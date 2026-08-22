<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CheckInService
{
    public function checkIn(string $ticketCode, User $admin, string $method = 'qr'): Ticket
    {
        $ticketCode = trim($ticketCode);

        $outcome = DB::transaction(function () use ($ticketCode, $admin, $method) {
            $ticket = Ticket::query()
                ->where('ticket_code', $ticketCode)
                ->lockForUpdate()
                ->first();

            if ($ticket === null) {
                $this->recordAttempt($admin, null, null, $ticketCode, $method, 'not_found');

                return ['result' => 'not_found', 'ticket' => null];
            }

            $event = Event::query()
                ->whereKey($ticket->event_id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($event->status !== 'published') {
                $result = 'event_cancelled';
            } elseif (($window = $event->checkInWindowResult()) !== null) {
                $result = $window;
            } elseif ($ticket->status === 'checked_in') {
                $result = 'already_checked_in';
            } elseif ($ticket->status !== 'valid') {
                $result = 'cancelled';
            } else {
                $ticket->update([
                    'status' => 'checked_in',
                    'checked_in_at' => now(),
                    'checked_in_by' => $admin->id,
                ]);
                $result = 'success';
            }

            $this->recordAttempt(
                $admin,
                $ticket->id,
                $event->id,
                $ticketCode,
                $method,
                $result,
            );

            return [
                'result' => $result,
                'ticket' => $ticket->fresh()->load('event'),
            ];
        });

        $ticket = $outcome['ticket'];

        return match ($outcome['result']) {
            'success' => $ticket,
            'not_found' => throw new ApiException('INVALID_TICKET', 'Ticket not found.', 404),
            'already_checked_in' => throw new ApiException(
                'ALREADY_CHECKED_IN',
                'Ticket already checked in.',
                409,
                ['checked_in_at' => $ticket->checked_in_at?->utc()->toIso8601String()],
            ),
            'cancelled' => throw new ApiException('TICKET_CANCELLED', 'This ticket is cancelled.', 422),
            'event_cancelled' => throw new ApiException('EVENT_CANCELLED', 'Event cancelled.', 422),
            'too_early' => throw new ApiException('TOO_EARLY', 'Check-in has not opened yet.', 422),
            'too_late' => throw new ApiException('TOO_LATE', 'Check-in has closed.', 422),
        };
    }

    private function recordAttempt(
        User $admin,
        ?string $ticketId,
        ?string $eventId,
        string $scannedCode,
        string $method,
        string $result,
    ): void {
        CheckInAttempt::query()->create([
            'scanned_by' => $admin->id,
            'ticket_id' => $ticketId,
            'event_id' => $eventId,
            'scanned_code' => $scannedCode,
            'method' => $method,
            'result' => $result,
        ]);
    }
}
