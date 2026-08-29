<?php

namespace Tests\Feature;

use App\Jobs\NotifyEventPublished;
use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class EventPublishNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_publish_dispatches_a_notification_job(): void
    {
        Queue::fake();

        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'starts_at' => now()->addDays(2),
        ]);

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$event->id.'/publish')
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        Queue::assertPushed(
            NotifyEventPublished::class,
            fn (NotifyEventPublished $job) => $job->eventId === $event->id,
        );
    }

    public function test_failed_publish_does_not_dispatch_a_notification_job(): void
    {
        Queue::fake();

        $admin = User::factory()->admin()->create();
        $past = Event::factory()->create([
            'starts_at' => now()->subHour(),
        ]);
        $published = Event::factory()->published()->create();
        $cancelled = Event::factory()->cancelled()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$past->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_START_NOT_FUTURE');

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$published->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_NOT_DRAFT');

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events/'.$cancelled->id.'/publish')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'EVENT_CANCELLED');

        Queue::assertNothingPushed();
    }
}
