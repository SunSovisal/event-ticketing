<?php

namespace Tests\Feature;

use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminCheckInTest extends TestCase
{
    use RefreshDatabase;

    public function test_check_in_requires_a_bearer_token(): void
    {
        $this->postJson('/api/v1/admin/check-in', [
            'ticket_code' => 'TKT_MISSING',
        ])
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_non_admin_cannot_check_in(): void
    {
        $attendee = User::factory()->create();
        $ticket = Ticket::factory()->create();

        $this->actingAsFirebaseUser($attendee)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => $ticket->ticket_code,
            ])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->assertDatabaseCount('check_in_attempts', 0);
        $this->assertSame('valid', $ticket->fresh()->status);
    }

    public function test_admin_can_check_in_a_valid_ticket_in_window(): void
    {
        $admin = User::factory()->admin()->create();
        $attendee = User::factory()->create(['name' => 'Dara Sok']);
        $event = $this->openEvent();
        $ticket = Ticket::factory()->create([
            'event_id' => $event->id,
            'user_id' => $attendee->id,
        ]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => $ticket->ticket_code,
                'method' => 'qr',
            ])
            ->assertOk()
            ->assertJsonPath('data.id', $ticket->id)
            ->assertJsonPath('data.status', 'checked_in')
            ->assertJsonPath('data.ticket_code', $ticket->ticket_code)
            ->assertJsonPath('data.attendee_name', 'Dara Sok')
            ->assertJsonPath('data.event.id', $event->id);

        $this->assertSame('checked_in', $ticket->fresh()->status);
        $this->assertNotNull($ticket->fresh()->checked_in_at);
        $this->assertSame($admin->id, $ticket->fresh()->checked_in_by);

        $this->assertDatabaseHas('check_in_attempts', [
            'ticket_id' => $ticket->id,
            'event_id' => $event->id,
            'scanned_code' => $ticket->ticket_code,
            'method' => 'qr',
            'result' => 'success',
            'scanned_by' => $admin->id,
        ]);
    }

    public function test_duplicate_check_in_returns_conflict_and_records_attempt(): void
    {
        $admin = User::factory()->admin()->create();
        $event = $this->openEvent();
        $ticket = Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'checked_in_at' => now()->subMinute(),
            'checked_in_by' => $admin->id,
        ]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => $ticket->ticket_code,
                'method' => 'manual',
            ])
            ->assertConflict()
            ->assertJsonPath('error.code', 'ALREADY_CHECKED_IN');

        $this->assertSame(1, CheckInAttempt::query()->where('result', 'already_checked_in')->count());
        $this->assertDatabaseHas('check_in_attempts', [
            'ticket_id' => $ticket->id,
            'method' => 'manual',
            'result' => 'already_checked_in',
        ]);
    }

    public function test_unknown_code_returns_not_found_and_records_attempt(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => 'TKT_DOESNOTEXIST',
            ])
            ->assertNotFound()
            ->assertJsonPath('error.code', 'INVALID_TICKET');

        $this->assertDatabaseHas('check_in_attempts', [
            'ticket_id' => null,
            'event_id' => null,
            'scanned_code' => 'TKT_DOESNOTEXIST',
            'method' => 'qr',
            'result' => 'not_found',
        ]);
    }

    public function test_too_early_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create([
            'starts_at' => now()->addDays(2),
            'ends_at' => now()->addDays(2)->addHours(2),
        ]);
        $ticket = Ticket::factory()->create(['event_id' => $event->id]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => $ticket->ticket_code,
            ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'TOO_EARLY');

        $this->assertSame('valid', $ticket->fresh()->status);
        $this->assertDatabaseHas('check_in_attempts', [
            'ticket_id' => $ticket->id,
            'result' => 'too_early',
        ]);
    }

    public function test_cancelled_ticket_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();
        $event = $this->openEvent();
        $ticket = Ticket::factory()->cancelled()->create(['event_id' => $event->id]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/check-in', [
                'ticket_code' => $ticket->ticket_code,
            ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'TICKET_CANCELLED');

        $this->assertDatabaseHas('check_in_attempts', [
            'ticket_id' => $ticket->id,
            'result' => 'cancelled',
        ]);
    }

    private function openEvent(): Event
    {
        return Event::factory()->published()->create([
            'starts_at' => now()->addHour(),
            'ends_at' => now()->addHours(3),
        ]);
    }
}
