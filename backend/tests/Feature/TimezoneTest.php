<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class TimezoneTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_application_timezone_is_phnom_penh(): void
    {
        $this->assertSame('Asia/Phnom_Penh', config('app.timezone'));
        $this->assertSame('Asia/Phnom_Penh', now()->timezoneName);
        $this->assertSame(7 * 60, now()->utcOffset());
    }

    public function test_api_returns_event_times_with_cambodia_offset(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-09-13 16:34:00', 'Asia/Phnom_Penh'));

        $event = Event::factory()->published()->create([
            'title' => 'Timezone check',
            'starts_at' => now(),
        ]);

        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'starts_at' => '2026-09-13 16:34:00',
        ]);

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.starts_at', '2026-09-13T16:34:00+07:00');
    }

    public function test_utc_payloads_are_stored_as_cambodia_wall_clock(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events', [
                'title' => 'UTC input event',
                'description' => 'Sent as Zulu, stored as ICT.',
                'starts_at' => '2026-09-13T09:34:00.000Z',
                'location_label' => 'Building A - Hall',
                'category' => 'General',
                'capacity' => 40,
            ])
            ->assertCreated();

        $stored = Event::query()->where('title', 'UTC input event')->first();
        $this->assertNotNull($stored);
        $this->assertDatabaseHas('events', [
            'title' => 'UTC input event',
            'starts_at' => '2026-09-13 16:34:00',
        ]);
        $this->assertSame('2026-09-13T16:34:00+07:00', $stored->starts_at?->toIso8601String());
    }
}
