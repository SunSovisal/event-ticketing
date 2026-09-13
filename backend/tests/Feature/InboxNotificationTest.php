<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\InboxNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InboxNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_can_list_published_event_notifications(): void
    {
        $event = Event::factory()->published()->create([
            'title' => 'Campus open day',
        ]);
        InboxNotification::query()->create([
            'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
            'title' => InboxNotification::TITLE_EVENT_PUBLISHED,
            'body' => $event->title,
            'event_id' => $event->id,
            'data' => [
                'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
                'event_id' => $event->id,
            ],
        ]);

        $this->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.type', 'event_published')
            ->assertJsonPath('data.0.title', 'New event at ITC')
            ->assertJsonPath('data.0.body', 'Campus open day')
            ->assertJsonPath('data.0.event_id', $event->id)
            ->assertJsonPath('data.0.is_read', false)
            ->assertJsonPath('meta.unread_count', 0);
    }

    public function test_guest_cannot_mark_a_notification_read(): void
    {
        $notification = $this->storePublishedNotification();

        $this->postJson('/api/v1/notifications/'.$notification->id.'/read')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');

        $this->postJson('/api/v1/notifications/read-all')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_authenticated_list_includes_unread_count_and_read_state(): void
    {
        $user = User::factory()->create();
        $older = $this->storePublishedNotification('Older workshop');
        $this->travel(2)->seconds();
        $newer = $this->storePublishedNotification('Newer meetup');

        $this->actingAsFirebaseUser($user)
            ->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.id', $newer->id)
            ->assertJsonPath('data.0.is_read', false)
            ->assertJsonPath('data.1.id', $older->id)
            ->assertJsonPath('meta.unread_count', 2);
    }

    public function test_mark_read_is_idempotent_and_private_to_the_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $notification = $this->storePublishedNotification();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/notifications/'.$notification->id.'/read')
            ->assertOk()
            ->assertJsonPath('data.id', $notification->id)
            ->assertJsonPath('data.is_read', true)
            ->assertJsonPath('meta.unread_count', 0);

        $this->postJson('/api/v1/notifications/'.$notification->id.'/read')
            ->assertOk()
            ->assertJsonPath('data.is_read', true)
            ->assertJsonPath('meta.unread_count', 0);

        $this->actingAsFirebaseUser($other)
            ->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.is_read', false)
            ->assertJsonPath('meta.unread_count', 1);

        $this->assertDatabaseCount('notification_reads', 1);
    }

    public function test_mark_all_read_clears_the_unread_badge(): void
    {
        $user = User::factory()->create();
        $this->storePublishedNotification('First');
        $this->storePublishedNotification('Second');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('data.0.is_read', true)
            ->assertJsonPath('data.1.is_read', true)
            ->assertJsonPath('meta.unread_count', 0);

        $this->postJson('/api/v1/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('meta.unread_count', 0);

        $this->assertDatabaseCount('notification_reads', 2);
    }

    public function test_unknown_notification_cannot_be_marked_read(): void
    {
        $user = User::factory()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/notifications/00000000-0000-0000-0000-000000000000/read')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_publish_stores_one_inbox_row_matching_the_push_copy(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'title' => 'Intro to Flutter',
            'starts_at' => now()->addDays(2),
        ]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/publish')
            ->assertOk();

        $this->assertDatabaseCount('notifications', 1);
        $this->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'New event at ITC')
            ->assertJsonPath('data.0.body', 'Intro to Flutter')
            ->assertJsonPath('data.0.event_id', $event->id)
            ->assertJsonPath('data.0.payload.type', 'event_published');
    }

    private function storePublishedNotification(string $title = 'Campus open day'): InboxNotification
    {
        $event = Event::factory()->published()->create([
            'title' => $title,
        ]);

        return InboxNotification::query()->create([
            'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
            'title' => InboxNotification::TITLE_EVENT_PUBLISHED,
            'body' => $event->title,
            'event_id' => $event->id,
            'data' => [
                'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
                'event_id' => $event->id,
            ],
        ]);
    }
}
