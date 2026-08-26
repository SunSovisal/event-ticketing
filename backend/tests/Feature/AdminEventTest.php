<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminEventTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function eventPayload(array $overrides = []): array
    {
        return array_merge([
            'title' => 'Campus career fair',
            'description' => 'Meet employers at Building A.',
            'starts_at' => now()->addDays(5)->startOfHour()->utc()->toIso8601String(),
            'ends_at' => null,
            'location_label' => 'Building A - Hall',
            'category' => 'Career',
            'capacity' => 80,
        ], $overrides);
    }

    public function test_admin_events_require_a_bearer_token(): void
    {
        $this->getJson('/api/v1/admin/events')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_non_admin_cannot_list_admin_events(): void
    {
        $attendee = User::factory()->create([
            'firebase_uid' => 'uid_attendee',
        ]);

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/admin/events')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_admin_can_list_events_of_any_status(): void
    {
        $admin = User::factory()->admin()->create([
            'firebase_uid' => 'uid_admin',
        ]);
        Event::factory()->published()->create(['title' => 'Published talk']);
        Event::factory()->create(['title' => 'Draft workshop']);
        Event::factory()->cancelled()->create(['title' => 'Cancelled meetup']);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events')
            ->assertOk();

        $titles = collect($response->json('data'))->pluck('title');
        $this->assertEqualsCanonicalizing(
            ['Published talk', 'Draft workshop', 'Cancelled meetup'],
            $titles->all(),
        );
        $this->assertSame(0, $response->json('data.0.reserved_count'));
        $this->assertSame(0, $response->json('data.0.checked_in_count'));
        $this->assertArrayNotHasKey('image_public_id', $response->json('data.0'));
    }

    public function test_admin_can_create_a_draft_event(): void
    {
        $admin = User::factory()->admin()->create();

        $response = $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events', $this->eventPayload([
                'status' => 'published',
            ]))
            ->assertCreated()
            ->assertJsonPath('data.title', 'Campus career fair')
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.capacity', 80)
            ->assertJsonPath('data.category', 'Career')
            ->assertJsonPath('data.reserved_count', 0)
            ->assertJsonPath('data.image_url', null);

        $this->assertArrayNotHasKey('image_public_id', $response->json('data'));
        $this->assertDatabaseHas('events', [
            'title' => 'Campus career fair',
            'status' => 'draft',
            'category' => 'Career',
        ]);
    }

    public function test_non_admin_cannot_create_an_event(): void
    {
        $attendee = User::factory()->create();

        $this->actingAsFirebaseUser($attendee)
            ->postJson('/api/v1/admin/events', $this->eventPayload())
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_create_rejects_invalid_capacity(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events', $this->eventPayload([
                'capacity' => 0,
            ]))
            ->assertUnprocessable();
    }

    public function test_create_rejects_invalid_category(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events', $this->eventPayload([
                'category' => 'NotACategory',
            ]))
            ->assertUnprocessable();
    }

    public function test_admin_can_show_an_event_with_counts(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create(['capacity' => 10]);
        Ticket::factory()->create(['event_id' => $event->id]);
        Ticket::factory()->checkedIn()->create(['event_id' => $event->id]);

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.reserved_count', 2)
            ->assertJsonPath('data.checked_in_count', 1)
            ->assertJsonPath('data.spots_remaining', 8);
    }

    public function test_show_unknown_event_returns_not_found(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/00000000-0000-0000-0000-000000000000')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_admin_can_update_a_draft_or_published_event(): void
    {
        $admin = User::factory()->admin()->create();
        $draft = Event::factory()->create();
        $published = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($admin)
            ->patchJson('/api/v1/admin/events/'.$draft->id, $this->eventPayload([
                'title' => 'Updated draft',
                'capacity' => 40,
            ]))
            ->assertOk()
            ->assertJsonPath('data.title', 'Updated draft')
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.capacity', 40);

        $this->actingAsFirebaseUser($admin)
            ->patchJson('/api/v1/admin/events/'.$published->id, $this->eventPayload([
                'title' => 'Updated published',
            ]))
            ->assertOk()
            ->assertJsonPath('data.title', 'Updated published')
            ->assertJsonPath('data.status', 'published');
    }

    public function test_cannot_update_a_cancelled_event(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->cancelled()->create();

        $this->actingAsFirebaseUser($admin)
            ->patchJson('/api/v1/admin/events/'.$event->id, $this->eventPayload())
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_CANCELLED');
    }

    public function test_cannot_reduce_capacity_below_reservations(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create(['capacity' => 2]);
        Ticket::factory()->create(['event_id' => $event->id]);
        Ticket::factory()->create(['event_id' => $event->id]);

        $this->actingAsFirebaseUser($admin)
            ->patchJson('/api/v1/admin/events/'.$event->id, $this->eventPayload([
                'capacity' => 1,
            ]))
            ->assertConflict()
            ->assertJsonPath('error.code', 'CAPACITY_BELOW_RESERVED');

        $this->assertSame(2, $event->fresh()->capacity);
    }

    public function test_publish_makes_a_draft_visible_on_the_public_list(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'title' => 'New workshop',
            'starts_at' => now()->addDays(2),
        ]);

        $this->getJson('/api/v1/events/'.$event->id)->assertNotFound();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/publish')
            ->assertOk()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.title', 'New workshop');

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.title', 'New workshop');
    }

    public function test_publish_rejects_a_past_start_time(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'starts_at' => now()->subHour(),
        ]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_START_NOT_FUTURE');

        $this->assertSame('draft', $event->fresh()->status);
    }

    public function test_publish_rejects_non_draft_events(): void
    {
        $admin = User::factory()->admin()->create();
        $published = Event::factory()->published()->create();
        $cancelled = Event::factory()->cancelled()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$published->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_NOT_DRAFT');

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$cancelled->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_CANCELLED');
    }

    public function test_cancel_is_atomic_and_preserves_check_in_audit(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create();
        $valid = Ticket::factory()->create(['event_id' => $event->id]);
        $checkedIn = Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'checked_in_by' => $admin->id,
        ]);
        $checkedInAt = $checkedIn->checked_in_at;

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertSame('cancelled', $valid->fresh()->status);
        $this->assertSame('cancelled', $checkedIn->fresh()->status);
        $this->assertEquals($checkedInAt, $checkedIn->fresh()->checked_in_at);
        $this->assertSame($admin->id, $checkedIn->fresh()->checked_in_by);
        $this->getJson('/api/v1/events/'.$event->id)->assertNotFound();
    }

    public function test_cannot_cancel_an_already_cancelled_event(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->cancelled()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/cancel')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_ALREADY_CANCELLED');
    }

    public function test_admin_can_delete_a_draft_event(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create();

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.deleted', true);

        $this->assertDatabaseMissing('events', ['id' => $event->id]);
    }

    public function test_non_admin_cannot_delete_an_event(): void
    {
        $attendee = User::factory()->create();
        $event = Event::factory()->create();

        $this->actingAsFirebaseUser($attendee)
            ->deleteJson('/api/v1/admin/events/'.$event->id)
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->assertDatabaseHas('events', ['id' => $event->id]);
    }

    public function test_cannot_delete_published_or_cancelled_events(): void
    {
        $admin = User::factory()->admin()->create();
        $published = Event::factory()->published()->create();
        $cancelled = Event::factory()->cancelled()->create();

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$published->id)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_NOT_DRAFT');

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$cancelled->id)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_CANCELLED');

        $this->assertDatabaseHas('events', ['id' => $published->id]);
        $this->assertDatabaseHas('events', ['id' => $cancelled->id]);
    }

    public function test_cannot_delete_a_draft_that_has_tickets(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create();
        Ticket::factory()->create(['event_id' => $event->id]);

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$event->id)
            ->assertConflict()
            ->assertJsonPath('error.code', 'EVENT_HAS_TICKETS');

        $this->assertDatabaseHas('events', ['id' => $event->id]);
    }
}
