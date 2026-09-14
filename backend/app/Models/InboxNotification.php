<?php

namespace App\Models;

use App\Casts\AppDateTime;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InboxNotification extends Model
{
    use HasUuids;

    public const UPDATED_AT = null;

    public const TYPE_EVENT_PUBLISHED = 'event_published';

    public const TITLE_EVENT_PUBLISHED = 'New event at ITC';

    protected $table = 'notifications';

    protected $fillable = [
        'type',
        'title',
        'body',
        'event_id',
        'data',
    ];

    protected function casts(): array
    {
        return [
            'data' => 'array',
            'created_at' => AppDateTime::class,
        ];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function reads(): HasMany
    {
        return $this->hasMany(NotificationRead::class, 'notification_id');
    }

    /**
     * @param  Builder<InboxNotification>  $query
     * @return Builder<InboxNotification>
     */
    public function scopeWithReadFlag(Builder $query, ?User $user): Builder
    {
        if ($user === null) {
            return $query;
        }

        return $query->withExists([
            'reads as is_read' => fn (Builder $reads) => $reads->where('user_id', $user->id),
        ]);
    }
}
