<?php

namespace App\Services;

use App\Models\Event;
use App\Models\EventView;
use App\Models\User;

class EventViewService
{
    public function record(Event $event, ?User $user): void
    {
        if ($user !== null) {
            $alreadyToday = EventView::query()
                ->where('event_id', $event->id)
                ->where('user_id', $user->id)
                ->where('created_at', '>=', now()->startOfDay())
                ->where('created_at', '<=', now()->endOfDay())
                ->exists();

            if ($alreadyToday) {
                return;
            }
        }

        EventView::query()->create([
            'event_id' => $event->id,
            'user_id' => $user?->id,
        ]);
    }
}
