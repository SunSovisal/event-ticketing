<?php

namespace App\Support;

use App\Exceptions\ApiException;
use Illuminate\Support\Carbon;

final class KpiRange
{
    public const KEYS = ['7d', '30d', '90d', 'all'];

    public function __construct(
        public readonly string $key,
        public readonly ?Carbon $from,
        public readonly Carbon $to,
        public readonly ?Carbon $previousFrom,
        public readonly ?Carbon $previousTo,
    ) {}

    public static function parse(?string $value): self
    {
        $key = $value ?: '30d';

        if (! in_array($key, self::KEYS, true)) {
            throw new ApiException(
                'VALIDATION_ERROR',
                'Range must be 7d, 30d, 90d, or all.',
                422,
                ['range' => 'Range must be 7d, 30d, 90d, or all.'],
            );
        }

        $to = now();

        if ($key === 'all') {
            return new self('all', null, $to, null, null);
        }

        $days = (int) rtrim($key, 'd');
        $from = $to->copy()->subDays($days);
        $previousTo = $from->copy();
        $previousFrom = $from->copy()->subDays($days);

        return new self($key, $from, $to, $previousFrom, $previousTo);
    }

    public function seriesFrom(): Carbon
    {
        return $this->from?->copy()->startOfDay()
            ?? $this->to->copy()->subDays(90)->startOfDay();
    }

    /**
     * @return array{range: string, from: ?string, to: string}
     */
    public function toMeta(): array
    {
        return [
            'range' => $this->key,
            'from' => AppDate::iso($this->from),
            'to' => AppDate::iso($this->to),
        ];
    }
}
