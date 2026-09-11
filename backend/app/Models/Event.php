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
        'price_amount',
        'price_currency',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'capacity' => 'integer',
            'price_amount' => 'decimal:2',
        ];
    }

    public function tickets(): HasMany
    {
        return $this->hasMany(Ticket::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
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

    public function isPaid(): bool
    {
        return (float) $this->price_amount > 0;
    }

    public function isFree(): bool
    {
        return ! $this->isPaid();
    }

    public function khqrAmount(): string
    {
        if (strtoupper((string) $this->price_currency) === 'KHR') {
            return (string) (int) round((float) $this->price_amount);
        }

        return number_format((float) $this->price_amount, 2, '.', '');
    }

    public function spotsRemaining(): int
    {
        $reserved = (int) ($this->reserved_count ?? 0);
        $pending = (int) ($this->pending_payment_count ?? 0);

        return max(0, $this->capacity - $reserved - $pending);
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
            'payments as pending_payment_count' => fn (Builder $payments) => $payments->activeHolds(),
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
