<?php

namespace Tests\Feature;

use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminEventAttendeesTest extends TestCase
{
    use RefreshDatabase;

    public function test_attendees_require_a_bearer_token(): void
    {
        $event = Event::factory()->published()->create();

        $this->getJson('/api/v1/admin/events/'.$event->id.'/attendees')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_non_admin_cannot_list_attendees(): void
    {
        $attendee = User::factory()->create();
        $event = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/admin/events/'.$event->id.'/attendees')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_attendees_unknown_event_returns_not_found(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/00000000-0000-0000-0000-000000000000/attendees')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_admin_can_list_attendees_with_campus_fields(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create();
        $otherEvent = Event::factory()->published()->create();

        $withProfile = User::factory()->create([
            'name' => 'Dara Sok',
            'email' => 'dara@itc.edu.kh',
        ]);
        UserProfile::factory()->create([
            'user_id' => $withProfile->id,
            'student_id' => 'e20240001',
            'department' => 'GIC',
            'year' => 3,
        ]);

        $emailOnly = User::factory()->create([
            'name' => null,
            'email' => 'fallback@itc.edu.kh',
            'phone_number' => null,
        ]);

        Ticket::factory()->create([
            'event_id' => $event->id,
            'user_id' => $withProfile->id,
            'status' => 'valid',
            'created_at' => now()->subMinutes(10),
        ]);
        Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'user_id' => $emailOnly->id,
            'created_at' => now()->subMinutes(5),
        ]);
        Ticket::factory()->create([
            'event_id' => $otherEvent->id,
            'user_id' => User::factory(),
        ]);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/'.$event->id.'/attendees')
            ->assertOk();

        $data = $response->json('data');
        $this->assertCount(2, $data);

        $this->assertSame('Dara Sok', $data[0]['name']);
        $this->assertSame('e20240001', $data[0]['student_id']);
        $this->assertSame('GIC', $data[0]['department']);
        $this->assertSame(3, $data[0]['year']);
        $this->assertSame('valid', $data[0]['ticket_status']);
        $this->assertNotNull($data[0]['issued_at']);
        $this->assertNull($data[0]['checked_in_at']);
        $this->assertArrayNotHasKey('ticket_code', $data[0]);

        $this->assertSame('fallback@itc.edu.kh', $data[1]['name']);
        $this->assertNull($data[1]['student_id']);
        $this->assertSame('checked_in', $data[1]['ticket_status']);
        $this->assertNotNull($data[1]['checked_in_at']);
    }

    public function test_check_in_attempts_require_admin(): void
    {
        $attendee = User::factory()->create();
        $event = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/admin/events/'.$event->id.'/check-in-attempts')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_check_in_attempts_unknown_event_returns_not_found(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/00000000-0000-0000-0000-000000000000/check-in-attempts')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_admin_lists_event_attempts_newest_first_excluding_unknown_codes(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create([
            'starts_at' => now()->subHour(),
        ]);
        $otherEvent = Event::factory()->published()->create();
        $ticket = Ticket::factory()->create(['event_id' => $event->id]);

        $older = CheckInAttempt::query()->create([
            'id' => (string) Str::uuid(),
            'scanned_by' => $admin->id,
            'ticket_id' => $ticket->id,
            'event_id' => $event->id,
            'scanned_code' => $ticket->ticket_code,
            'method' => 'qr',
            'result' => 'success',
            'created_at' => now()->subMinutes(20),
        ]);
        $newer = CheckInAttempt::query()->create([
            'id' => (string) Str::uuid(),
            'scanned_by' => $admin->id,
            'ticket_id' => $ticket->id,
            'event_id' => $event->id,
            'scanned_code' => $ticket->ticket_code,
            'method' => 'manual',
            'result' => 'already_checked_in',
            'created_at' => now()->subMinutes(5),
        ]);

        CheckInAttempt::query()->create([
            'id' => (string) Str::uuid(),
            'scanned_by' => $admin->id,
            'ticket_id' => null,
            'event_id' => null,
            'scanned_code' => 'TKT_UNKNOWN',
            'method' => 'qr',
            'result' => 'not_found',
            'created_at' => now()->subMinutes(1),
        ]);

        CheckInAttempt::query()->create([
            'id' => (string) Str::uuid(),
            'scanned_by' => $admin->id,
            'ticket_id' => null,
            'event_id' => $otherEvent->id,
            'scanned_code' => 'TKT_OTHER',
            'method' => 'qr',
            'result' => 'not_found',
            'created_at' => now(),
        ]);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/'.$event->id.'/check-in-attempts')
            ->assertOk();

        $data = $response->json('data');
        $this->assertCount(2, $data);
        $this->assertSame($newer->id, $data[0]['id']);
        $this->assertSame('already_checked_in', $data[0]['result']);
        $this->assertSame('manual', $data[0]['method']);
        $this->assertSame($ticket->ticket_code, $data[0]['scanned_code']);
        $this->assertSame($ticket->id, $data[0]['ticket_id']);

        $this->assertSame($older->id, $data[1]['id']);
        $this->assertSame('success', $data[1]['result']);
    }
}
