<?php

namespace App\Jobs;

use App\Contracts\PushNotifier;
use App\Models\Event;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class NotifyEventPublished implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    /** @var list<int> */
    public array $backoff = [30, 60, 120];

    public int $timeout = 30;

    public function __construct(public readonly string $eventId)
    {
        $this->afterCommit();
    }

    public function handle(PushNotifier $notifier): void
    {
        $event = Event::query()->find($this->eventId);

        if ($event === null || $event->status !== 'published') {
            return;
        }

        $notifier->notifyEventPublished($event);
    }
}
