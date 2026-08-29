<?php

namespace App\Providers;

use App\Contracts\CoverStorage;
use App\Contracts\PushNotifier;
use App\Services\CloudinaryCoverStorage;
use App\Services\FcmPushNotifier;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(CoverStorage::class, CloudinaryCoverStorage::class);
        $this->app->singleton(PushNotifier::class, FcmPushNotifier::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('api-strict', function (Request $request) {
            return Limit::perMinute(10)->by(
                optional($request->user())->id ?: $request->ip()
            );
        });
    }
}
