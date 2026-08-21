<?php

namespace Tests\Feature;

use App\Models\Event;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PublicEventTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_list_returns_only_published_upcoming_events(): void
    {
        $upcoming = Event::factory()->published()->create([
            'title' => 'Upcoming workshop',
            'starts_at' => now()->addDays(2),
            'image_public_id' => 'secret-cover-id',
        ]);
        Event::factory()->create(['title' => 'Hidden draft']);
        Event::factory()->cancelled()->create(['title' => 'Cancelled talk']);
        Event::factory()->ended()->create(['title' => 'Already ended']);
        Event::factory()->published()->create([
            'title' => 'Still happening',
            'starts_at' => now()->subHour(),
            'ends_at' => null,
        ]);

        $response = $this->getJson('/api/v1/events')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Still happening')
            ->assertJsonPath('data.1.title', 'Upcoming workshop')
            ->assertJsonPath('data.1.spots_remaining', 50)
            ->assertJsonPath('data.1.image_url', null)
            ->assertJsonPath('data.1.status', 'published');

        $ids = collect($response->json('data'))->pluck('id');
        $this->assertCount(2, $ids);
        $this->assertTrue($ids->contains($upcoming->id));
        $this->assertArrayNotHasKey('image_public_id', $response->json('data.1'));
        $this->assertArrayNotHasKey('reserved_count', $response->json('data.1'));
    }

    public function test_public_show_returns_a_published_upcoming_event(): void
    {
        $event = Event::factory()->published()->create([
            'title' => 'Career fair',
            'capacity' => 80,
        ]);

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.title', 'Career fair')
            ->assertJsonPath('data.spots_remaining', 80)
            ->assertJsonPath('data.image_url', null);
    }

    public function test_public_show_hides_drafts_and_unknown_ids(): void
    {
        $draft = Event::factory()->create();

        $this->getJson('/api/v1/events/'.$draft->id)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');

        $this->getJson('/api/v1/events/00000000-0000-0000-0000-000000000000')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_cancelled_factory_state_does_not_publish(): void
    {
        $event = Event::factory()->cancelled()->create();

        $this->assertSame('cancelled', $event->status);
        $this->getJson('/api/v1/events/'.$event->id)->assertNotFound();
    }
}
