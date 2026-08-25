<?php

namespace App\Providers;

use App\Contracts\CoverStorage;
use App\Services\CloudinaryCoverStorage;
use Illuminate\Cache\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\Request;
use Illuminate\Support\ServiceProvider;
use Symfony\Component\HttpKernel\Attribute\RateLimit;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(CoverStorage::class, CloudinaryCoverStorage::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request){
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('api-strict', function (Request $request) {
            return Limit::perMinute(10)->by(optional($request->user())->id ?: $request->ip());
        });  
    }
}