<?php

namespace App\Http\Resources;

use App\Models\CheckInAttempt;
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
        return [
            'id' => $this->id,
            'scanned_code' => $this->scanned_code,
            'method' => $this->method,
            'result' => $this->result,
            'ticket_id' => $this->ticket_id,
            'created_at' => $this->created_at?->utc()->toIso8601String(),
        ];
    }
}
