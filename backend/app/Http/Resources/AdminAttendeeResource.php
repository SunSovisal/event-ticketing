<?php

namespace App\Http\Resources;

use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Ticket
 */
class AdminAttendeeResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $this->user;
        $profile = $user?->profile;

        $name = $user?->name
            ?: $user?->email
            ?: $user?->phone_number;

        return [
            'name' => $name,
            'student_id' => $profile?->student_id,
            'department' => $profile?->department,
            'year' => $profile?->year,
            'ticket_status' => $this->status,
            'issued_at' => $this->created_at?->utc()->toIso8601String(),
            'checked_in_at' => $this->checked_in_at?->utc()->toIso8601String(),
        ];
    }
}
