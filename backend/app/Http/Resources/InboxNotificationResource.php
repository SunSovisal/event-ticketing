<?php

namespace App\Http\Resources;

use App\Models\InboxNotification;
use App\Support\AppDate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin InboxNotification
 */
class InboxNotificationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'event_id' => $this->event_id,
            'payload' => $this->resource->getAttribute('data') ?? [],
            'is_read' => (bool) (int) ($this->is_read ?? false),
            'created_at' => AppDate::iso($this->created_at),
        ];
    }
}
