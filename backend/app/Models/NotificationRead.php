<?php

namespace App\Models;

use App\Casts\AppDateTime;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationRead extends Model
{
    use HasUuids;

    public const CREATED_AT = null;

    public const UPDATED_AT = null;

    protected $fillable = [
        'user_id',
        'notification_id',
        'read_at',
    ];

    protected function casts(): array
    {
        return [
            'read_at' => AppDateTime::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function notification(): BelongsTo
    {
        return $this->belongsTo(InboxNotification::class, 'notification_id');
    }
}
