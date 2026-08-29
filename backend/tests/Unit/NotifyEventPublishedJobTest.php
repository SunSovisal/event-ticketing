<?php

namespace Tests\Unit;

use App\Contracts\PushNotifier;
use App\Jobs\NotifyEventPublished;
use App\Models\Event;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class NotifyEventPublishedJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_notifies_a_published_event(): void
    {
        $event = Event::factory()->published()->create();
        $notifier = Mockery::mock(PushNotifier::class);
        $notifier->shouldReceive('notifyEventPublished')
            ->once()
            ->with(Mockery::on(fn (Event $sent) => $sent->is($event)));

        (new NotifyEventPublished($event->id))->handle($notifier);
    }

    public function test_job_skips_a_missing_event(): void
    {
        $notifier = Mockery::mock(PushNotifier::class);
        $notifier->shouldReceive('notifyEventPublished')->never();

        (new NotifyEventPublished('00000000-0000-0000-0000-000000000000'))
            ->handle($notifier);
    }

    public function test_job_skips_a_cancelled_event(): void
    {
        $event = Event::factory()->cancelled()->create();
        $notifier = Mockery::mock(PushNotifier::class);
        $notifier->shouldReceive('notifyEventPublished')->never();

        (new NotifyEventPublished($event->id))->handle($notifier);
    }
}
