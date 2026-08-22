<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TicketService
{
    /**
     * @return array{ticket: Ticket, created: bool}
     */
    public function reserve(string $eventId, User $user): array
    {
        return DB::transaction(function () use ($eventId, $user) {
            $event = Event::query()->whereKey($eventId)->lockForUpdate()->first();

            if ($event === null) {
                throw new ApiException('NOT_FOUND', 'Event not found.', 404);
            }

            if ($event->status === 'cancelled') {
                throw new ApiException('EVENT_CANCELLED', 'Event cancelled.', 422);
            }

            if ($event->status !== 'published') {
                throw new ApiException('EVENT_NOT_PUBLISHED', 'Event is not open for reservation.', 422);
            }

            if ($event->hasEnded()) {
                throw new ApiException('EVENT_ENDED', 'Event has ended.', 422);
            }

            $existing = Ticket::query()
                ->where('event_id', $event->id)
                ->where('user_id', $user->id)
                ->first();

            if ($existing !== null) {
                return [
                    'ticket' => $existing->load('event'),
                    'created' => false,
                ];
            }

            $activeCount = Ticket::query()
                ->where('event_id', $event->id)
                ->whereIn('status', ['valid', 'checked_in'])
                ->count();

            if ($activeCount >= $event->capacity) {
                throw new ApiException(
                    'EVENT_FULL',
                    'This event has no remaining places.',
                    409,
                );
            }

            try {
                $ticket = Ticket::query()->create([
                    'event_id' => $event->id,
                    'user_id' => $user->id,
                    'ticket_code' => 'TKT_'.Str::ulid(),
                    'status' => 'valid',
                ]);
            } catch (UniqueConstraintViolationException) {
                $ticket = Ticket::query()
                    ->where('event_id', $event->id)
                    ->where('user_id', $user->id)
                    ->firstOrFail();

                return [
                    'ticket' => $ticket->load('event'),
                    'created' => false,
                ];
            }

            return [
                'ticket' => $ticket->load('event'),
                'created' => true,
            ];
        });
    }
}
