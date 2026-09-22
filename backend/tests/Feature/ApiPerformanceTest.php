<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Group;
use Tests\Support\AssertsApiLatency;
use Tests\TestCase;

/**
 * Contract and latency budgets for the mobile API.
 *
 * Behavioral edge cases stay in the dedicated feature classes (PublicEventTest,
 * MeTest, SavedEventTest, KhqrPaymentTest, AdminEventTest). This class samples
 * the hot paths those clients actually call and fails when either the JSON
 * contract or the in-process budget slips.
 *
 * Read samples are taken on the second request. The first call resolves
 * middleware and query plans; the budget applies to the steady-state call.
 * Writes are measured once, because a warm-up would mutate the database.
 *
 * Outbound Bakong and PayWay calls are replaced in Tests\TestCase, so a budget
 * failure here is application time, not a third-party round trip.
 */
#[Group('performance')]
class ApiPerformanceTest extends TestCase
{
    use AssertsApiLatency;
    use RefreshDatabase;

    /** Liveness probe. No database work. */
    private const HEALTH_MS = 150;

    /** Indexed reads against the in-memory schema. */
    private const READ_MS = 300;

    /** Auth failure and authorization failure. No domain write. */
    private const AUTH_MS = 200;

    /** Profile update, save, and free-ticket reservation. */
    private const WRITE_MS = 500;

    /** Local KHQR generation plus a payment row insert. */
    private const PAYMENT_MS = 800;

    public function test_health_returns_the_ok_envelope_within_budget(): void
    {
        $this->getJson('/api/v1/health');

        $this->assertApiWithin(self::HEALTH_MS, fn () => $this->getJson('/api/v1/health'))
            ->assertOk()
            ->assertJsonPath('data.status', 'ok')
            ->assertJsonStructure([
                'data' => ['status'],
                'meta' => ['request_id'],
            ]);
    }

    public function test_public_event_list_matches_the_catalog_contract_within_budget(): void
    {
        Event::factory()->published()->count(40)->create();
        Event::factory()->create();
        Event::factory()->cancelled()->create();

        $this->getJson('/api/v1/events');

        $response = $this->assertApiWithin(self::READ_MS, fn () => $this->getJson('/api/v1/events'))
            ->assertOk()
            ->assertJsonCount(40, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'title',
                        'description',
                        'starts_at',
                        'ends_at',
                        'location_label',
                        'category',
                        'capacity',
                        'spots_remaining',
                        'status',
                        'image_url',
                        'price_amount',
                        'price_currency',
                        'is_free',
                        'payment_methods',
                    ],
                ],
                'meta' => ['request_id'],
            ]);

        $this->assertArrayNotHasKey('is_saved', $response->json('data.0'));
        $this->assertArrayNotHasKey('image_public_id', $response->json('data.0'));
        $this->assertSame('published', $response->json('data.0.status'));
    }

    public function test_public_event_show_records_a_view_and_stays_within_budget(): void
    {
        $event = Event::factory()->published()->create(['capacity' => 25]);

        $this->getJson('/api/v1/events/'.$event->id);

        $this->assertApiWithin(
            self::READ_MS,
            fn () => $this->getJson('/api/v1/events/'.$event->id),
        )
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.spots_remaining', 25)
            ->assertJsonPath('data.is_free', true)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'title',
                    'spots_remaining',
                    'payment_methods' => [
                        '*' => ['id', 'live', 'sandbox'],
                    ],
                ],
                'meta' => ['request_id'],
            ]);

        $this->assertDatabaseHas('event_views', [
            'event_id' => $event->id,
        ]);
    }

    public function test_missing_event_returns_the_error_envelope_within_budget(): void
    {
        $this->getJson('/api/v1/events/00000000-0000-0000-0000-000000000000');

        $this->assertApiWithin(
            self::READ_MS,
            fn () => $this->getJson('/api/v1/events/00000000-0000-0000-0000-000000000000'),
        )
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND')
            ->assertJsonStructure($this->errorEnvelope());
    }

    public function test_profile_requires_a_bearer_token_within_budget(): void
    {
        $this->assertApiWithin(self::AUTH_MS, fn () => $this->getJson('/api/v1/me'))
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED')
            ->assertJsonPath('error.message', 'Missing bearer token.')
            ->assertJsonStructure($this->errorEnvelope());
    }

    public function test_profile_update_persists_the_campus_row_within_budget(): void
    {
        $user = User::factory()->create(['name' => 'Dara']);

        $response = $this->assertApiWithin(self::WRITE_MS, fn () => $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'student_id' => 'e20240001',
                'department' => 'GIC',
                'year' => 3,
            ]))
            ->assertOk()
            ->assertJsonPath('data.name', 'Dara')
            ->assertJsonPath('data.student_id', 'e20240001')
            ->assertJsonPath('data.department', 'GIC')
            ->assertJsonPath('data.year', 3)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'firebase_uid',
                    'email',
                    'phone_number',
                    'name',
                    'is_admin',
                    'is_active',
                    'student_id',
                    'department',
                    'year',
                ],
                'meta' => ['request_id'],
            ]);

        $this->assertMatchesRegularExpression(
            '/^[0-9a-f-]{36}$/i',
            (string) $response->json('meta.request_id'),
        );

        $this->assertDatabaseHas('user_profiles', [
            'user_id' => $user->id,
            'student_id' => 'e20240001',
            'department' => 'GIC',
            'year' => 3,
        ]);
    }

    public function test_save_event_inserts_one_row_and_does_not_reserve_a_ticket(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create(['capacity' => 40]);

        $this->assertApiWithin(
            self::WRITE_MS,
            fn () => $this->actingAsFirebaseUser($user)->postJson('/api/v1/events/'.$event->id.'/save'),
        )
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.is_saved', true)
            ->assertJsonPath('data.spots_remaining', 40);

        $this->assertDatabaseCount('saved_events', 1);
        $this->assertDatabaseCount('tickets', 0);
        $this->assertDatabaseHas('saved_events', [
            'user_id' => $user->id,
            'event_id' => $event->id,
        ]);
    }

    public function test_free_ticket_reservation_returns_201_and_inserts_a_valid_ticket(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create(['capacity' => 10]);

        $this->assertApiWithin(
            self::WRITE_MS,
            fn () => $this->actingAsFirebaseUser($user)->postJson('/api/v1/events/'.$event->id.'/tickets'),
        )
            ->assertCreated()
            ->assertJsonPath('data.status', 'valid')
            ->assertJsonPath('data.event_id', $event->id)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'event_id',
                    'ticket_code',
                    'status',
                    'checked_in_at',
                    'created_at',
                    'event' => ['id', 'title', 'starts_at', 'location_label', 'status'],
                ],
                'meta' => ['request_id'],
            ]);

        $this->assertDatabaseHas('tickets', [
            'user_id' => $user->id,
            'event_id' => $event->id,
            'status' => 'valid',
        ]);
        $this->assertDatabaseCount('payments', 0);
    }

    public function test_paid_event_rejects_the_free_ticket_route_without_a_ticket_row(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid()->create();

        $this->assertApiWithin(
            self::AUTH_MS,
            fn () => $this->actingAsFirebaseUser($user)->postJson('/api/v1/events/'.$event->id.'/tickets'),
        )
            ->assertStatus(402)
            ->assertJsonPath('error.code', 'PAYMENT_REQUIRED')
            ->assertJsonStructure($this->errorEnvelope());

        $this->assertDatabaseCount('tickets', 0);
    }

    public function test_khqr_payment_create_returns_a_pending_payload_within_budget(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $this->assertApiWithin(
            self::PAYMENT_MS,
            fn () => $this->actingAsFirebaseUser($user)->postJson('/api/v1/events/'.$event->id.'/payments'),
        )
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.amount', 0.01)
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.method', 'khqr')
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'event_id',
                    'status',
                    'amount',
                    'currency',
                    'method',
                    'merchant_name',
                    'qr_code',
                    'qr_md5',
                    'qr_expires_at',
                    'paid_at',
                ],
                'meta' => ['request_id'],
            ]);

        $this->assertDatabaseHas('payments', [
            'user_id' => $user->id,
            'event_id' => $event->id,
            'status' => 'pending',
            'method' => 'khqr',
        ]);
        $this->assertDatabaseCount('tickets', 0);
    }

    public function test_non_admin_is_forbidden_from_the_admin_catalog_within_budget(): void
    {
        $attendee = User::factory()->create();

        $this->assertApiWithin(
            self::AUTH_MS,
            fn () => $this->actingAsFirebaseUser($attendee)->getJson('/api/v1/admin/events'),
        )
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN')
            ->assertJsonPath('error.message', 'Admin access required.')
            ->assertJsonStructure($this->errorEnvelope());
    }

    public function test_guest_inbox_is_an_empty_collection_within_budget(): void
    {
        $this->getJson('/api/v1/notifications');

        $this->assertApiWithin(self::READ_MS, fn () => $this->getJson('/api/v1/notifications'))
            ->assertOk()
            ->assertJsonPath('data', [])
            ->assertJsonPath('meta.unread_count', 0)
            ->assertJsonStructure([
                'data',
                'meta' => ['request_id', 'unread_count'],
            ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function errorEnvelope(): array
    {
        return [
            'error' => ['code', 'message', 'fields'],
            'meta' => ['request_id'],
        ];
    }
}
