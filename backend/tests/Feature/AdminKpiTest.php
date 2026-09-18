<?php

namespace Tests\Feature;

use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\EventView;
use App\Models\Payment;
use App\Models\SavedEvent;
use App\Models\Ticket;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class AdminKpiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::parse('2026-09-17 12:00:00', 'Asia/Phnom_Penh'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_kpis_require_a_bearer_token(): void
    {
        $this->getJson('/api/v1/admin/kpis')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_non_admin_cannot_read_kpis(): void
    {
        $attendee = User::factory()->create();

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/admin/kpis')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_invalid_range_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/kpis?range=yesterday')
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');
    }

    public function test_empty_database_returns_zero_kpis(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/kpis?range=30d')
            ->assertOk()
            ->assertJsonPath('data.range', '30d')
            ->assertJsonPath('data.overview.tickets.value', 0)
            ->assertJsonPath('data.overview.fill_rate.value', 0)
            ->assertJsonPath('data.overview.check_in_rate.value', 0)
            ->assertJsonPath('data.overview.revenue.usd', 0)
            ->assertJsonPath('data.top_events', []);
    }

    public function test_overview_aggregates_tickets_fill_check_in_and_paid_revenue(): void
    {
        $admin = User::factory()->admin()->create();
        $currentEvent = Event::factory()->published()->create([
            'title' => 'Current workshop',
            'category' => 'Workshop',
            'capacity' => 40,
            'starts_at' => now()->subDays(5),
            'ends_at' => now()->subDays(5)->addHours(2),
        ]);
        $previousEvent = Event::factory()->published()->create([
            'title' => 'Previous meetup',
            'category' => 'Meetup',
            'capacity' => 40,
            'starts_at' => now()->subDays(40),
            'ends_at' => now()->subDays(40)->addHours(2),
        ]);

        Ticket::factory()->count(20)->create([
            'event_id' => $currentEvent->id,
        ]);
        Ticket::factory()->count(10)->checkedIn()->create([
            'event_id' => $currentEvent->id,
            'checked_in_at' => now()->subDays(5)->addHour(),
        ]);
        $previousTickets = Ticket::factory()->count(10)->create([
            'event_id' => $previousEvent->id,
        ]);
        Ticket::query()
            ->where('event_id', $currentEvent->id)
            ->update(['created_at' => now()->subDays(4)]);
        Ticket::query()
            ->whereIn('id', $previousTickets->pluck('id'))
            ->update(['created_at' => now()->subDays(40)]);

        $paidUser = User::factory()->create();
        $expiredUser = User::factory()->create();
        Payment::factory()->paid()->create([
            'event_id' => $currentEvent->id,
            'user_id' => $paidUser->id,
            'amount' => '12.50',
            'currency' => 'USD',
            'paid_at' => now()->subDays(3),
        ]);
        Payment::factory()->expired()->create([
            'event_id' => $currentEvent->id,
            'user_id' => $expiredUser->id,
            'amount' => '99.00',
            'currency' => 'USD',
        ]);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/kpis?range=30d')
            ->assertOk();

        $this->assertSame(30, $response->json('data.overview.tickets.value'));
        $this->assertSame(10, $response->json('data.overview.tickets.previous'));
        $this->assertEquals(200, $response->json('data.overview.tickets.delta_pct'));
        $this->assertEqualsWithDelta(0.75, $response->json('data.overview.fill_rate.value'), 0.0001);
        $this->assertEqualsWithDelta(0.25, $response->json('data.overview.fill_rate.previous'), 0.0001);
        $this->assertEqualsWithDelta(0.3333, $response->json('data.overview.check_in_rate.value'), 0.0001);
        $this->assertEquals(12.5, $response->json('data.overview.revenue.usd'));
        $this->assertEquals(0, $response->json('data.overview.revenue.previous_usd'));

        $categories = collect($response->json('data.breakdowns.tickets_by_category'))
            ->pluck('count', 'key');
        $this->assertSame(30, $categories['Workshop']);

        $this->assertSame($currentEvent->id, $response->json('data.top_events.0.id'));
        $this->assertEqualsWithDelta(0.75, $response->json('data.top_events.0.fill_rate'), 0.0001);
    }

    public function test_event_kpis_include_funnel_hours_departments_and_scans(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create([
            'title' => 'ITC Coding Day',
            'category' => 'Workshop',
            'location_label' => 'Building A - Hall',
            'capacity' => 40,
            'starts_at' => now()->subDays(2)->setTime(16, 0),
            'ends_at' => now()->subDays(2)->setTime(18, 0),
        ]);

        $gic = User::factory()->create();
        UserProfile::factory()->create([
            'user_id' => $gic->id,
            'department' => 'GIC',
        ]);
        $gee = User::factory()->create();
        UserProfile::factory()->create([
            'user_id' => $gee->id,
            'department' => 'GEE',
        ]);

        Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'user_id' => $gic->id,
            'checked_in_at' => $event->starts_at->copy()->subHour(),
            'checked_in_by' => $admin->id,
        ]);
        Ticket::factory()->create([
            'event_id' => $event->id,
            'user_id' => $gee->id,
        ]);

        SavedEvent::query()->create([
            'user_id' => $gic->id,
            'event_id' => $event->id,
        ]);
        EventView::query()->create([
            'event_id' => $event->id,
            'user_id' => $gic->id,
        ]);
        EventView::query()->create([
            'event_id' => $event->id,
            'user_id' => null,
        ]);

        CheckInAttempt::query()->create([
            'scanned_by' => $admin->id,
            'ticket_id' => Ticket::query()->where('user_id', $gic->id)->value('id'),
            'event_id' => $event->id,
            'scanned_code' => 'TKT_OK',
            'method' => 'qr',
            'result' => 'success',
            'created_at' => now()->subDay(),
        ]);
        CheckInAttempt::query()->create([
            'scanned_by' => $admin->id,
            'ticket_id' => null,
            'event_id' => $event->id,
            'scanned_code' => 'TKT_BAD',
            'method' => 'qr',
            'result' => 'too_early',
            'created_at' => now()->subDay(),
        ]);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/'.$event->id.'/kpis?range=30d')
            ->assertOk()
            ->assertJsonPath('data.event.title', 'ITC Coding Day')
            ->assertJsonPath('data.overview.reserved_count', 2)
            ->assertJsonPath('data.overview.checked_in_count', 1)
            ->assertJsonPath('data.funnel.views', 2)
            ->assertJsonPath('data.funnel.saves', 1)
            ->assertJsonPath('data.funnel.tickets', 2)
            ->assertJsonPath('data.funnel.check_ins', 1);

        $hours = collect($response->json('data.check_ins_by_hour'))->pluck('count', 'label');
        $this->assertSame(1, $hours['-1h']);
        $this->assertCount(9, $response->json('data.check_ins_by_hour'));

        $departments = collect($response->json('data.attendees_by_department'))->pluck('count', 'key');
        $this->assertSame(1, $departments['GIC']);
        $this->assertSame(1, $departments['GEE']);

        $scans = collect($response->json('data.scan_results'))->pluck('count', 'key');
        $this->assertSame(1, $scans['success']);
        $this->assertSame(1, $scans['too_early']);
    }

    public function test_event_kpis_bucket_arrivals_every_thirty_minutes(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->published()->create([
            'starts_at' => now()->subDays(2)->setTime(16, 0),
            'ends_at' => now()->subDays(2)->setTime(18, 0),
        ]);

        Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'checked_in_at' => $event->starts_at->copy()->subMinutes(75),
            'checked_in_by' => $admin->id,
        ]);
        Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'checked_in_at' => $event->starts_at->copy()->addMinutes(10),
            'checked_in_by' => $admin->id,
        ]);
        Ticket::factory()->checkedIn()->create([
            'event_id' => $event->id,
            'checked_in_at' => $event->starts_at->copy()->addMinutes(70),
            'checked_in_by' => $admin->id,
        ]);

        $hours = collect(
            $this->actingAsFirebaseUser($admin)
                ->getJson('/api/v1/admin/events/'.$event->id.'/kpis?range=30d')
                ->assertOk()
                ->json('data.check_ins_by_hour'),
        )->keyBy('label');

        $this->assertCount(9, $hours);
        $this->assertSame(1, $hours['-90m']['count']);
        $this->assertSame(-90, $hours['-90m']['offset_minutes']);
        $this->assertSame(1, $hours['Start']['count']);
        $this->assertSame(0, $hours['Start']['offset_minutes']);
        $this->assertSame(1, $hours['+1h']['count']);
        $this->assertSame(60, $hours['+1h']['offset_minutes']);
        $this->assertSame(0, $hours['-1h']['count']);
    }

    public function test_event_kpis_return_not_found(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events/00000000-0000-0000-0000-000000000000/kpis')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_public_show_records_guest_views_and_unique_authenticated_views(): void
    {
        $event = Event::factory()->published()->create();
        $attendee = User::factory()->create();

        $this->getJson('/api/v1/events/'.$event->id)->assertOk();
        $this->getJson('/api/v1/events/'.$event->id)->assertOk();

        $this->assertSame(2, EventView::query()->whereNull('user_id')->count());

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/events/'.$event->id)
            ->assertOk();
        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/events/'.$event->id)
            ->assertOk();

        $this->assertSame(1, EventView::query()->where('user_id', $attendee->id)->count());
    }
}
