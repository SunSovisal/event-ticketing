<?php

namespace App\Http\Resources;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Payment
 */
class PaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $ticket = $this->relationLoaded('ticket') ? $this->ticket : null;

        return [
            'id' => $this->id,
            'event_id' => $this->event_id,
            'status' => $this->status,
            'amount' => (float) $this->amount,
            'currency' => $this->currency,
            'method' => $this->method,
            'merchant_name' => config('services.bakong.account_name'),
            'qr_code' => $this->when($this->isPending() && ! $this->qrHasExpired(), $this->qr_code),
            'aba_deeplink' => $this->when(
                $this->isPending() && ! $this->qrHasExpired() && filled($this->aba_deeplink),
                $this->aba_deeplink,
            ),
            'qr_md5' => $this->qr_md5,
            'qr_expires_at' => $this->qr_expires_at?->utc()->toIso8601String(),
            'paid_at' => $this->paid_at?->utc()->toIso8601String(),
            'ticket' => $this->when(
                $ticket !== null,
                fn () => new TicketResource($ticket),
            ),
        ];
    }
}
