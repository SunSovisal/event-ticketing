<?php

namespace App\Http\Resources;

use App\Models\Ticket;
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
            'checked_in_at' => $this->checked_in_at?->utc()->toIso8601String(),
            'created_at' => $this->created_at?->utc()->toIso8601String(),
            'event' => $this->whenLoaded('event', fn () => [
                'id' => $this->event->id,
                'title' => $this->event->title,
                'starts_at' => $this->event->starts_at?->utc()->toIso8601String(),
                'ends_at' => $this->event->ends_at?->utc()->toIso8601String(),
                'location_label' => $this->event->location_label,
                'status' => $this->event->status,
                'image_url' => $this->event->image_url,
            ]),
        ];
    }
}
