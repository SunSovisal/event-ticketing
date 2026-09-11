<?php

namespace App\Models;

use Database\Factories\PaymentFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

class Payment extends Model
{
    /** @use HasFactory<PaymentFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'event_id',
        'user_id',
        'ticket_id',
        'amount',
        'currency',
        'status',
        'method',
        'qr_code',
        'qr_md5',
        'payway_tran_id',
        'aba_deeplink',
        'qr_expires_at',
        'bakong_hash',
        'from_account_id',
        'to_account_id',
        'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'qr_expires_at' => 'datetime',
            'paid_at' => 'datetime',
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

    public function ticket(): BelongsTo
    {
        return $this->belongsTo(Ticket::class);
    }

    public function isPaid(): bool
    {
        return $this->status === 'paid';
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isAbaPay(): bool
    {
        return $this->method === 'aba_pay' || filled($this->payway_tran_id);
    }

    public function isKhqr(): bool
    {
        return ! $this->isAbaPay();
    }

    public function qrHasExpired(?Carbon $at = null): bool
    {
        return ($at ?? now())->gte($this->qr_expires_at);
    }

    public static function graceSeconds(): int
    {
        return max(0, (int) config('services.bakong.grace_seconds', 300));
    }

    public static function holdCutoff(?Carbon $at = null): Carbon
    {
        return ($at ?? now())->copy()->subSeconds(self::graceSeconds());
    }

    public function holdExpiresAt(): Carbon
    {
        return $this->qr_expires_at->copy()->addSeconds(self::graceSeconds());
    }

    public function holdHasExpired(?Carbon $at = null): bool
    {
        return ($at ?? now())->gte($this->holdExpiresAt());
    }

    /**
     * Pending QRs still count as a seat until the scan window plus grace elapse.
     *
     * @param  Builder<Payment>  $query
     * @return Builder<Payment>
     */
    public function scopeActiveHolds(Builder $query, ?Carbon $at = null): Builder
    {
        return $query
            ->where('status', 'pending')
            ->whereNull('ticket_id')
            ->where('qr_expires_at', '>', self::holdCutoff($at));
    }
}
