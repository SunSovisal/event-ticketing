<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Jobs\NotifyEventPublished;
use App\Models\Event;
use App\Models\Ticket;
use Illuminate\Support\Facades\DB;

class EventLifecycleService
{
    public function publish(string $eventId): Event
    {
        $event = DB::transaction(function () use ($eventId) {
            $event = Event::query()->whereKey($eventId)->lockForUpdate()->first();

            if ($event === null) {
                throw new ApiException('NOT_FOUND', 'Event not found.', 404);
            }

            if ($event->status === 'cancelled') {
                throw new ApiException('EVENT_CANCELLED', 'Cancelled events cannot be published.', 422);
            }

            if ($event->status !== 'draft') {
                throw new ApiException('EVENT_NOT_DRAFT', 'Only a draft event can be published.', 422);
            }

            $this->assertReadyToPublish($event);

            $event->update(['status' => 'published']);

            return $event->refresh();
        });

        NotifyEventPublished::dispatch($event->id);

        return $event;
    }

    public function cancel(string $eventId): Event
    {
        return DB::transaction(function () use ($eventId) {
            $event = Event::query()->whereKey($eventId)->lockForUpdate()->first();

            if ($event === null) {
                throw new ApiException('NOT_FOUND', 'Event not found.', 404);
            }

            if ($event->status === 'cancelled') {
                throw new ApiException('EVENT_ALREADY_CANCELLED', 'Event is already cancelled.', 422);
            }

            $event->update(['status' => 'cancelled']);

            Ticket::query()
                ->where('event_id', $event->id)
                ->whereIn('status', ['valid', 'checked_in'])
                ->update(['status' => 'cancelled']);

            return $event->refresh();
        });
    }

    public function deleteDraft(string $eventId): string
    {
        return DB::transaction(function () use ($eventId) {
            $event = Event::query()->whereKey($eventId)->lockForUpdate()->first();

            if ($event === null) {
                throw new ApiException('NOT_FOUND', 'Event not found.', 404);
            }

            if ($event->status === 'cancelled') {
                throw new ApiException('EVENT_CANCELLED', 'Cancelled events cannot be deleted.', 422);
            }

            if ($event->status !== 'draft') {
                throw new ApiException('EVENT_NOT_DRAFT', 'Only a draft event can be deleted.', 422);
            }

            if ($event->tickets()->exists()) {
                throw new ApiException('EVENT_HAS_TICKETS', 'This draft cannot be deleted because it has tickets.', 409);
            }

            $id = $event->id;
            $event->delete();

            return $id;
        });
    }

    private function assertReadyToPublish(Event $event): void
    {
        if ($event->title === '' || $event->description === '' || $event->location_label === '') {
            throw new ApiException('INVALID_EVENT', 'Publishing requires a title, description, and location.', 422);
        }

        if ($event->capacity < 1 || $event->capacity > 500) {
            throw new ApiException('INVALID_EVENT', 'Publishing requires a capacity between 1 and 500.', 422);
        }

        if ($event->starts_at->lte(now())) {
            throw new ApiException('EVENT_START_NOT_FUTURE', 'Publishing requires a future start time.', 422);
        }

        if ($event->ends_at !== null && $event->ends_at->lte($event->starts_at)) {
            throw new ApiException('INVALID_EVENT', 'Event end time must be after the start time.', 422);
        }
    }
}
