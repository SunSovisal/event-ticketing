<?php

namespace App\Http\Resources\Admin;

use App\Models\CheckInAttempt;
use App\Support\AppDate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin CheckInAttempt
 */
class CheckInAttemptResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $this->ticket?->user;

        return [
            'id' => $this->id,
            'scanned_code' => $this->scanned_code,
            'attendee_name' => $user?->name
                ?: $user?->email
                ?: $user?->phone_number,
            'method' => $this->method,
            'result' => $this->result,
            'ticket_id' => $this->ticket_id,
            'created_at' => AppDate::iso($this->created_at),
        ];
    }
}
