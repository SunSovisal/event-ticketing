<?php

namespace App\Http\Resources;

use App\Contracts\PayWayGateway;
use App\Models\Event;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Event
 */
class EventResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $payload = [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'starts_at' => $this->starts_at?->utc()->toIso8601String(),
            'ends_at' => $this->ends_at?->utc()->toIso8601String(),
            'location_label' => $this->location_label,
            'category' => $this->category,
            'capacity' => $this->capacity,
            'spots_remaining' => $this->spotsRemaining(),
            'status' => $this->status,
            'image_url' => $this->image_url,
            'price_amount' => (float) $this->price_amount,
            'price_currency' => $this->price_currency,
            'is_free' => $this->isFree(),
            'payment_methods' => $this->paymentMethods(),
        ];

        if ($request->is('api/v1/admin/*')) {
            $payload['reserved_count'] = (int) ($this->reserved_count ?? 0);
            $payload['checked_in_count'] = (int) ($this->checked_in_count ?? 0);
        }

        $user = $request->attributes->get('auth_user');
        if ($user instanceof User && ! $request->is('api/v1/admin/*')) {
            $payload['is_saved'] = (bool) (int) $this->is_saved;
        }

        return $payload;
    }

    /**
     * @return list<array{id: string, live: bool, sandbox: bool}>
     */
    private function paymentMethods(): array
    {
        $methods = [
            [
                'id' => 'khqr',
                'live' => true,
                'sandbox' => false,
            ],
        ];

        if (app(PayWayGateway::class)->isEnabled()) {
            $sandbox = (bool) config('services.payway.sandbox', true);
            $methods[] = [
                'id' => 'aba_pay',
                'live' => ! $sandbox,
                'sandbox' => $sandbox,
            ];
        }

        return $methods;
    }
}
