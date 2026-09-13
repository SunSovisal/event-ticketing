<?php

namespace App\Http\Resources;

use App\Models\Ticket;
use App\Support\AppDate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Ticket
 */
class TicketResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'event_id' => $this->event_id,
            'ticket_code' => $this->ticket_code,
            'status' => $this->status,
            'checked_in_at' => AppDate::iso($this->checked_in_at),
            'created_at' => AppDate::iso($this->created_at),
            'attendee_name' => $this->when(
                $this->relationLoaded('user'),
                fn () => $this->user?->name
                    ?: $this->user?->email
                    ?: $this->user?->phone_number,
            ),
            'event' => $this->whenLoaded('event', fn () => [
                'id' => $this->event->id,
                'title' => $this->event->title,
                'starts_at' => AppDate::iso($this->event->starts_at),
                'ends_at' => AppDate::iso($this->event->ends_at),
                'location_label' => $this->event->location_label,
                'category' => $this->event->category,
                'status' => $this->event->status,
                'image_url' => $this->event->image_url,
                'price_amount' => (float) $this->event->price_amount,
                'price_currency' => $this->event->price_currency,
            ]),
        ];
    }
}
