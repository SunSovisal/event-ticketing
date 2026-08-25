<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SavedEventTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_list_saved_events(): void
    {
        $this->getJson('/api/v1/saved-events')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_guest_cannot_save_an_event(): void
    {
        $event = Event::factory()->published()->create();

        $this->postJson('/api/v1/events/'.$event->id.'/save')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_guest_event_payload_omits_is_saved(): void
    {
        $event = Event::factory()->published()->create();

        $list = $this->getJson('/api/v1/events')->assertOk();
        $this->assertArrayNotHasKey('is_saved', $list->json('data.0'));

        $show = $this->getJson('/api/v1/events/'.$event->id)->assertOk();
        $this->assertArrayNotHasKey('is_saved', $show->json('data'));
    }

    public function test_authenticated_show_and_list_include_is_saved(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($user)
            ->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.is_saved', false);

        $this->getJson('/api/v1/events')
            ->assertOk()
            ->assertJsonPath('data.0.is_saved', false);
    }

    public function test_save_is_idempotent_and_does_not_reserve_a_ticket(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create(['capacity' => 40]);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.id', $event->id)
            ->assertJsonPath('data.is_saved', true)
            ->assertJsonPath('data.spots_remaining', 40);

        $this->postJson('/api/v1/events/'.$event->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.is_saved', true);

        $this->assertDatabaseCount('saved_events', 1);
        $this->assertDatabaseCount('tickets', 0);
        $this->assertDatabaseHas('saved_events', [
            'user_id' => $user->id,
            'event_id' => $event->id,
        ]);
    }

    public function test_unsave_is_idempotent(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/save')
            ->assertOk();

        $this->deleteJson('/api/v1/events/'.$event->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.is_saved', false);

        $this->deleteJson('/api/v1/events/'.$event->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.is_saved', false);

        $this->assertDatabaseCount('saved_events', 0);
    }

    public function test_save_allows_cancelled_and_past_events(): void
    {
        $user = User::factory()->create();
        $cancelled = Event::factory()->cancelled()->create();
        $past = Event::factory()->ended()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$cancelled->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.is_saved', true);

        $this->postJson('/api/v1/events/'.$past->id.'/save')
            ->assertOk()
            ->assertJsonPath('data.is_saved', true);

        $this->assertDatabaseCount('saved_events', 2);
        $this->assertDatabaseCount('tickets', 0);
    }

    public function test_save_hides_drafts_and_unknown_ids(): void
    {
        $user = User::factory()->create();
        $draft = Event::factory()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$draft->id.'/save')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');

        $this->postJson('/api/v1/events/00000000-0000-0000-0000-000000000000/save')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');

        $this->assertDatabaseCount('saved_events', 0);
    }

    public function test_saved_list_is_newest_first_and_private_to_the_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $older = Event::factory()->published()->create(['title' => 'Older save']);
        $newer = Event::factory()->published()->create(['title' => 'Newer save']);
        $otherEvent = Event::factory()->published()->create(['title' => 'Someone else']);

        $this->actingAsFirebaseUser($other)
            ->postJson('/api/v1/events/'.$otherEvent->id.'/save')
            ->assertOk();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$older->id.'/save')
            ->assertOk();

        $this->travel(2)->seconds();

        $this->postJson('/api/v1/events/'.$newer->id.'/save')
            ->assertOk();

        $this->getJson('/api/v1/saved-events')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Newer save')
            ->assertJsonPath('data.0.is_saved', true)
            ->assertJsonPath('data.1.title', 'Older save')
            ->assertJsonCount(2, 'data');

        $this->assertDatabaseCount('tickets', 0);
        $this->assertDatabaseMissing('tickets', [
            'user_id' => $user->id,
        ]);
        $this->assertSame(0, Ticket::query()->count());
    }
}
