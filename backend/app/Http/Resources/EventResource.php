<?php

namespace App\Http\Resources;

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
}
