<?php

namespace App\Providers;

use App\Contracts\CoverStorage;
use App\Services\CloudinaryCoverStorage;
use Illuminate\Support\ServiceProvider;

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
        //
    }
}
