<?php

namespace App\Services;

use App\Contracts\BakongGateway;
use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Bakong Open API allows 100 status checks per calendar day.
 * This decorator caches hits, coalesces repeats, and stops at the daily cap.
 */
class RateLimitedBakongGateway implements BakongGateway
{
    public function __construct(
        private BakongGateway $inner,
    ) {}

    public function findPaidTransaction(string $md5): ?array
    {
        $paid = Cache::get($this->paidKey($md5));
        if (is_array($paid)) {
            return $paid;
        }

        $minSeconds = max(5, (int) config('services.bakong.min_check_seconds', 20));
        if (Cache::has($this->cooldownKey($md5))) {
            return null;
        }

        $limit = max(1, (int) config('services.bakong.daily_limit', 100));
        $dailyKey = $this->dailyKey();
        Cache::add($dailyKey, 0, $this->dailyTtl());
        $used = (int) Cache::increment($dailyKey);

        if ($used > $limit) {
            Cache::decrement($dailyKey);

            throw new ApiException(
                'BAKONG_DAILY_LIMIT',
                'Bakong payment checks are limited to '.$limit.' per day. Try again tomorrow.',
                429,
            );
        }

        Cache::put($this->cooldownKey($md5), 1, $minSeconds);

        Log::info('Bakong MD5 status check', [
            'md5_prefix' => substr($md5, 0, 8),
            'used' => $used,
            'limit' => $limit,
        ]);

        $result = $this->inner->findPaidTransaction($md5);
        if ($result !== null) {
            Cache::put($this->paidKey($md5), $result, $this->dailyTtl());
        }

        return $result;
    }

    private function paidKey(string $md5): string
    {
        return 'bakong:paid:'.$md5;
    }

    private function cooldownKey(string $md5): string
    {
        return 'bakong:cooldown:'.$md5;
    }

    private function dailyKey(): string
    {
        return 'bakong:daily:'.now('Asia/Phnom_Penh')->toDateString();
    }

    private function dailyTtl(): \DateTimeInterface
    {
        return now('Asia/Phnom_Penh')->endOfDay();
    }
}
