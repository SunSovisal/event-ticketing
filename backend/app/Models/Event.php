<?php

namespace App\Models;

use Database\Factories\EventFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

class Event extends Model
{
    /** @use HasFactory<EventFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'title',
        'description',
        'starts_at',
        'ends_at',
        'location_label',
        'category',
        'capacity',
        'status',
        'image_url',
        'image_public_id',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'capacity' => 'integer',
        ];
    }

    public function tickets(): HasMany
    {
        return $this->hasMany(Ticket::class);
    }

    public function savedEvents(): HasMany
    {
        return $this->hasMany(SavedEvent::class);
    }

    public function effectiveEndsAt(): Carbon
    {
        return $this->ends_at ?? $this->starts_at->copy()->addHours(2);
    }

    public function hasEnded(?Carbon $at = null): bool
    {
        return ($at ?? now())->gte($this->effectiveEndsAt());
    }

    public function checkInOpensAt(): Carbon
    {
        return $this->starts_at->copy()->subHours(2);
    }

    public function checkInClosesAt(): Carbon
    {
        return $this->effectiveEndsAt()->copy()->addHours(2);
    }

    /**
     * @return 'too_early'|'too_late'|null
     */
    public function checkInWindowResult(?Carbon $at = null): ?string
    {
        $at ??= now();

        if ($at->lt($this->checkInOpensAt())) {
            return 'too_early';
        }

        if ($at->gt($this->checkInClosesAt())) {
            return 'too_late';
        }

        return null;
    }

    public function spotsRemaining(): int
    {
        $reserved = (int) ($this->reserved_count ?? 0);

        return max(0, $this->capacity - $reserved);
    }

    /**
     * @param  Builder<Event>  $query
     * @return Builder<Event>
     */
    public function scopePublishedUpcoming(Builder $query): Builder
    {
        $now = now();

        return $query
            ->where('status', 'published')
            ->where(function (Builder $inner) use ($now) {
                $inner->where('ends_at', '>', $now)
                    ->orWhere(function (Builder $withoutEnd) use ($now) {
                        $withoutEnd->whereNull('ends_at')
                            ->where('starts_at', '>', $now->copy()->subHours(2));
                    });
            });
    }

    /**
     * @param  Builder<Event>  $query
     * @return Builder<Event>
     */
    public function scopeWithTicketCounts(Builder $query): Builder
    {
        return $query->withCount([
            'tickets as reserved_count' => fn (Builder $tickets) => $tickets->whereIn('status', ['valid', 'checked_in']),
            'tickets as checked_in_count' => fn (Builder $tickets) => $tickets->where('status', 'checked_in'),
        ]);
    }

    /**
     * @param  Builder<Event>  $query
     * @return Builder<Event>
     */
    public function scopeWithSavedFlag(Builder $query, ?User $user): Builder
    {
        if ($user === null) {
            return $query;
        }

        return $query->withExists([
            'savedEvents as is_saved' => fn (Builder $saved) => $saved->where('user_id', $user->id),
        ]);
    }
}
