<?php

namespace App\Services;

use App\Contracts\BakongGateway;
use App\Contracts\KhqrGenerator;
use App\Contracts\PayWayGateway;
use App\Enums\PaymentMethod;
use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\Payment;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentService
{
    public function __construct(
        private KhqrGenerator $khqr,
        private BakongGateway $bakong,
        private PayWayGateway $payway,
        private TicketService $tickets,
    ) {}

    /**
     * @return array{payment: Payment, created: bool}
     */
    public function start(string $eventId, User $user, PaymentMethod $method = PaymentMethod::Khqr): array
    {
        $existing = Payment::query()
            ->where('event_id', $eventId)
            ->where('user_id', $user->id)
            ->first();

        if ($existing !== null && $this->wouldReplaceQr($existing, $method)) {
            try {
                $checked = $this->sync($existing->id, $user);
                if ($checked->isPaid()) {
                    return [
                        'payment' => $checked,
                        'created' => false,
                    ];
                }
            } catch (ApiException $e) {
                if ($e->errorCode !== 'QR_EXPIRED') {
                    throw $e;
                }
            }
        }

        return DB::transaction(function () use ($eventId, $user, $method) {
            $event = Event::query()->whereKey($eventId)->lockForUpdate()->first();

            if ($event === null) {
                throw new ApiException('NOT_FOUND', 'Event not found.', 404);
            }

            $this->assertEventAcceptsPayment($event);

            $existingTicket = Ticket::query()
                ->where('event_id', $event->id)
                ->where('user_id', $user->id)
                ->first();

            if ($existingTicket !== null) {
                $payment = Payment::query()
                    ->where('event_id', $event->id)
                    ->where('user_id', $user->id)
                    ->first();

                if ($payment !== null) {
                    return [
                        'payment' => $payment->load(['event', 'ticket.event']),
                        'created' => false,
                    ];
                }

                throw new ApiException('TICKET_EXISTS', 'You already have a ticket for this event.', 409);
            }

            $payment = Payment::query()
                ->where('event_id', $event->id)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if ($payment !== null && $payment->isPaid()) {
                return [
                    'payment' => $payment->load(['event', 'ticket.event']),
                    'created' => false,
                ];
            }

            if ($payment !== null && $payment->isPending() && ! $payment->qrHasExpired() && $payment->method === $method->value) {
                return [
                    'payment' => $payment->load(['event', 'ticket.event']),
                    'created' => false,
                ];
            }

            $this->assertCapacityAvailable($event, $user->id);

            $payload = $this->newQr($event, $payment?->id, $method);

            if ($payment === null) {
                $payment = Payment::query()->create([
                    'event_id' => $event->id,
                    'user_id' => $user->id,
                    'amount' => $event->price_amount,
                    'currency' => $event->price_currency,
                    'status' => 'pending',
                    ...$payload,
                ]);

                return [
                    'payment' => $payment->load(['event', 'ticket.event']),
                    'created' => true,
                ];
            }

            $payment->update([
                'amount' => $event->price_amount,
                'currency' => $event->price_currency,
                'status' => 'pending',
                'ticket_id' => null,
                'bakong_hash' => null,
                'from_account_id' => null,
                'to_account_id' => null,
                'paid_at' => null,
                'payway_tran_id' => null,
                'aba_deeplink' => null,
                ...$payload,
            ]);

            return [
                'payment' => $payment->refresh()->load(['event', 'ticket.event']),
                'created' => false,
            ];
        });
    }

    public function sync(string $paymentId, User $user): Payment
    {
        $payment = Payment::query()->with(['event', 'ticket.event'])->find($paymentId);

        if ($payment === null) {
            throw new ApiException('NOT_FOUND', 'Payment not found.', 404);
        }

        if ($payment->user_id !== $user->id) {
            throw new ApiException('FORBIDDEN', 'You cannot access this payment.', 403);
        }

        if ($payment->isPaid()) {
            return $payment;
        }

        if ($payment->isAbaPay()) {
            return $this->syncPayWay($payment, $user);
        }

        $transaction = $this->bakong->findPaidTransaction($payment->qr_md5);

        if ($transaction === null) {
            if ($payment->holdHasExpired()) {
                $payment->update(['status' => 'expired']);

                throw new ApiException('QR_EXPIRED', 'QR code has expired.', 422);
            }

            return $payment;
        }

        $this->assertTransactionMatches($payment, $transaction);

        return DB::transaction(function () use ($payment, $user, $transaction) {
            $locked = Payment::query()->whereKey($payment->id)->lockForUpdate()->firstOrFail();

            if ($locked->isPaid()) {
                return $locked->load(['event', 'ticket.event']);
            }

            $event = Event::query()->whereKey($locked->event_id)->lockForUpdate()->firstOrFail();
            $this->assertEventAcceptsPayment($event);
            $this->assertCapacityAvailable($event, $user->id);

            ['ticket' => $ticket] = $this->tickets->issuePaidTicket($event, $user);

            $locked->update([
                'status' => 'paid',
                'ticket_id' => $ticket->id,
                'bakong_hash' => $transaction['hash'],
                'from_account_id' => $transaction['fromAccountId'],
                'to_account_id' => $transaction['toAccountId'],
                'paid_at' => now(),
            ]);

            return $locked->refresh()->load(['event', 'ticket.event']);
        });
    }

    public function show(string $paymentId, User $user): Payment
    {
        $payment = Payment::query()->with(['event', 'ticket.event'])->find($paymentId);

        if ($payment === null) {
            throw new ApiException('NOT_FOUND', 'Payment not found.', 404);
        }

        if ($payment->user_id !== $user->id) {
            throw new ApiException('FORBIDDEN', 'You cannot access this payment.', 403);
        }

        return $payment;
    }

    private function syncPayWay(Payment $payment, User $user): Payment
    {
        $settlement = $this->payway->findApprovedTransaction((string) $payment->payway_tran_id);

        if ($settlement === null) {
            if ($payment->holdHasExpired()) {
                $payment->update(['status' => 'expired']);

                throw new ApiException('QR_EXPIRED', 'QR code has expired.', 422);
            }

            return $payment;
        }

        $this->assertPayWaySettlementMatches($payment, $settlement);

        return DB::transaction(function () use ($payment, $user) {
            $locked = Payment::query()->whereKey($payment->id)->lockForUpdate()->firstOrFail();

            if ($locked->isPaid()) {
                return $locked->load(['event', 'ticket.event']);
            }

            $event = Event::query()->whereKey($locked->event_id)->lockForUpdate()->firstOrFail();
            $this->assertEventAcceptsPayment($event);
            $this->assertCapacityAvailable($event, $user->id);

            ['ticket' => $ticket] = $this->tickets->issuePaidTicket($event, $user);

            $locked->update([
                'status' => 'paid',
                'ticket_id' => $ticket->id,
                'paid_at' => now(),
            ]);

            return $locked->refresh()->load(['event', 'ticket.event']);
        });
    }

    /**
     * @param  array{hash: string, fromAccountId: string, toAccountId: string, currency: string, amount: float}  $transaction
     */
    private function assertTransactionMatches(Payment $payment, array $transaction): void
    {
        $expectedAccount = strtolower((string) config('services.bakong.account_id'));
        $toAccount = strtolower($transaction['toAccountId']);

        if ($expectedAccount !== '' && $toAccount !== $expectedAccount) {
            throw new ApiException('PAYMENT_MISMATCH', 'This payment was sent to a different account.', 409);
        }

        if (strtoupper($transaction['currency']) !== strtoupper($payment->currency)) {
            throw new ApiException('PAYMENT_MISMATCH', 'This payment currency does not match the ticket price.', 409);
        }

        if (round($transaction['amount'], 2) !== round((float) $payment->amount, 2)) {
            throw new ApiException('PAYMENT_MISMATCH', 'This payment amount does not match the ticket price.', 409);
        }
    }

    /**
     * @param  array{amount: ?float, currency: ?string}  $settlement
     */
    private function assertPayWaySettlementMatches(Payment $payment, array $settlement): void
    {
        $currency = $settlement['currency'] ?? null;
        if (is_string($currency) && $currency !== '' && strtoupper($currency) !== strtoupper($payment->currency)) {
            throw new ApiException('PAYMENT_MISMATCH', 'This payment currency does not match the ticket price.', 409);
        }

        $amount = $settlement['amount'] ?? null;
        if (is_float($amount) || is_int($amount)) {
            if (round((float) $amount, 2) !== round((float) $payment->amount, 2)) {
                throw new ApiException('PAYMENT_MISMATCH', 'This payment amount does not match the ticket price.', 409);
            }
        }
    }

    private function assertEventAcceptsPayment(Event $event): void
    {
        if ($event->status === 'cancelled') {
            throw new ApiException('EVENT_CANCELLED', 'Event cancelled.', 422);
        }

        if ($event->status !== 'published') {
            throw new ApiException('EVENT_NOT_PUBLISHED', 'Event is not open for reservation.', 422);
        }

        if ($event->hasEnded()) {
            throw new ApiException('EVENT_ENDED', 'Event has ended.', 422);
        }

        if (! $event->isPaid()) {
            throw new ApiException('EVENT_IS_FREE', 'This event does not require payment.', 422);
        }
    }

    private function assertCapacityAvailable(Event $event, string $userId): void
    {
        $tickets = Ticket::query()
            ->where('event_id', $event->id)
            ->whereIn('status', ['valid', 'checked_in'])
            ->count();

        $holds = Payment::query()
            ->where('event_id', $event->id)
            ->activeHolds()
            ->where('user_id', '!=', $userId)
            ->count();

        if (($tickets + $holds) >= $event->capacity) {
            throw new ApiException('EVENT_FULL', 'This event has no remaining places.', 409);
        }
    }

    private function wouldReplaceQr(Payment $payment, PaymentMethod $method): bool
    {
        if ($payment->isPaid()) {
            return false;
        }

        if ($payment->method !== $method->value) {
            return true;
        }

        if (! $payment->isPending()) {
            return true;
        }

        return $payment->qrHasExpired();
    }

    /**
     * @return array{method: string, qr_code: string, qr_md5: string, qr_expires_at: Carbon, payway_tran_id: ?string, aba_deeplink: ?string}
     */
    private function newQr(Event $event, ?string $billNumber, PaymentMethod $method): array
    {
        if ($method === PaymentMethod::AbaPay) {
            if (! $this->payway->isEnabled()) {
                throw new ApiException('PAYWAY_NOT_CONFIGURED', 'ABA PAY sandbox is not configured.', 503);
            }

            $ttlSeconds = max(180, (int) config('services.bakong.qr_ttl_seconds', 300));
            $lifetimeMinutes = max(3, (int) ceil($ttlSeconds / 60));
            $expiresAt = now()->addMinutes($lifetimeMinutes);
            $created = $this->payway->createKhqr(
                $event->khqrAmount(),
                strtoupper((string) $event->price_currency),
                $lifetimeMinutes,
            );

            return [
                'method' => $method->value,
                'qr_code' => $created['qr_code'],
                'qr_md5' => $created['qr_md5'],
                'payway_tran_id' => $created['tran_id'],
                'aba_deeplink' => $created['aba_deeplink'] !== '' ? $created['aba_deeplink'] : null,
                'qr_expires_at' => $expiresAt,
            ];
        }

        return [
            'method' => $method->value,
            ...$this->newKhqr($event, $billNumber),
            'payway_tran_id' => null,
            'aba_deeplink' => null,
        ];
    }

    /**
     * @return array{qr_code: string, qr_md5: string, qr_expires_at: Carbon}
     */
    private function newKhqr(Event $event, ?string $billNumber): array
    {
        $accountId = (string) config('services.bakong.account_id');
        $merchantName = (string) config('services.bakong.account_name');
        $city = (string) config('services.bakong.merchant_city');

        if ($accountId === '' || $merchantName === '') {
            throw new ApiException('BAKONG_NOT_CONFIGURED', 'Bakong is not configured.', 503);
        }

        $ttl = max(60, (int) config('services.bakong.qr_ttl_seconds', 300));
        $expiresAt = now()->addSeconds($ttl);
        $expiresAtMs = (int) $expiresAt->getTimestampMs();

        $khqr = $this->khqr->generate(
            $accountId,
            $merchantName,
            $city !== '' ? $city : 'PHNOM PENH',
            strtoupper((string) $event->price_currency),
            $event->khqrAmount(),
            $expiresAtMs,
            $billNumber ?? Str::ulid(),
        );

        return [
            'qr_code' => $khqr['qr'],
            'qr_md5' => $khqr['md5'],
            'qr_expires_at' => $expiresAt,
        ];
    }
}
