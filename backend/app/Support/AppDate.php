<?php

namespace App\Support;

use Carbon\Carbon;
use DateTimeInterface;

final class AppDate
{
    public static function iso(?DateTimeInterface $value): ?string
    {
        if ($value === null) {
            return null;
        }

        return Carbon::parse($value)
            ->timezone((string) config('app.timezone'))
            ->toIso8601String();
    }
}
