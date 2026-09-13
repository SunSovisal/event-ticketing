<?php

namespace App\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Stores and reads naive datetimes as Cambodia wall clock (APP_TIMEZONE).
 *
 * @implements CastsAttributes<Carbon|null, string|null>
 */
class AppDateTime implements CastsAttributes
{
    public bool $withoutObjectCaching = true;
    public function get(Model $model, string $key, mixed $value, array $attributes): ?Carbon
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse($value)
            ->timezone((string) config('app.timezone'))
            ->startOfSecond();
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse($value)
            ->timezone((string) config('app.timezone'))
            ->format('Y-m-d H:i:s');
    }
}
