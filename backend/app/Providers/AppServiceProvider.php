<?php

namespace App\Providers;

use App\Contracts\BakongGateway;
use App\Contracts\CoverStorage;
use App\Contracts\KhqrGenerator;
use App\Contracts\PayWayGateway;
use App\Contracts\PushNotifier;
use App\Services\CloudinaryCoverStorage;
use App\Services\FcmPushNotifier;
use App\Services\HttpPayWayGateway;
use App\Services\IndividualKhqrGenerator;
use App\Services\NbcBakongGateway;
use App\Services\RateLimitedBakongGateway;
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
        $this->app->singleton(KhqrGenerator::class, IndividualKhqrGenerator::class);
        $this->app->singleton(NbcBakongGateway::class);
        $this->app->singleton(BakongGateway::class, function ($app) {
            return new RateLimitedBakongGateway($app->make(NbcBakongGateway::class));
        });
        $this->app->singleton(PayWayGateway::class, HttpPayWayGateway::class);
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

        RateLimiter::for('chat', function (Request $request) {
            $user = $request->attributes->get('auth_user');
            $key = is_object($user) && isset($user->id)
                ? 'user:'.$user->id
                : 'ip:'.$request->ip();

            return Limit::perMinute(10)->by($key);
        });

        RateLimiter::for('payment-sync', function (Request $request) {
            $user = $request->attributes->get('auth_user');
            $key = is_object($user) && isset($user->id)
                ? 'pay-sync:'.$user->id
                : 'pay-sync-ip:'.$request->ip();

            return Limit::perMinute(6)->by($key);
        });
    }
}
