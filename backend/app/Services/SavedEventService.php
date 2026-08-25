<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\SavedEvent;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Collection;

class SavedEventService
{
    public function save(string $eventId, User $user): Event
    {
        $event = $this->visibleEvent($eventId);

        try {
            SavedEvent::query()->create([
                'user_id' => $user->id,
                'event_id' => $event->id,
            ]);
        } catch (UniqueConstraintViolationException) {
            // Already saved — treat as success.
        }

        return $this->present($event->id, $user);
    }

    public function unsave(string $eventId, User $user): Event
    {
        $event = $this->visibleEvent($eventId);

        SavedEvent::query()
            ->where('user_id', $user->id)
            ->where('event_id', $event->id)
            ->delete();

        return $this->present($event->id, $user);
    }

    /**
     * @return Collection<int, Event>
     */
    public function listFor(User $user): Collection
    {
        $saves = SavedEvent::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        $events = Event::query()
            ->withTicketCounts()
            ->whereIn('id', $saves->pluck('event_id'))
            ->get()
            ->keyBy('id');

        return $saves
            ->map(function (SavedEvent $save) use ($events) {
                $event = $events->get($save->event_id);
                if ($event === null) {
                    return null;
                }

                $event->setAttribute('is_saved', true);

                return $event;
            })
            ->filter()
            ->values();
    }

    private function visibleEvent(string $eventId): Event
    {
        $event = Event::query()->find($eventId);

        if ($event === null || $event->status === 'draft') {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        return $event;
    }

    private function present(string $eventId, User $user): Event
    {
        return Event::query()
            ->withTicketCounts()
            ->withSavedFlag($user)
            ->findOrFail($eventId);
    }
}
