<?php

namespace App\Models;

use App\Casts\AppDateTime;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EventView extends Model
{
    use HasUuids;

    public const UPDATED_AT = null;

    protected $fillable = [
        'event_id',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => AppDateTime::class,
        ];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
