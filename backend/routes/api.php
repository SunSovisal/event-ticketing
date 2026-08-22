<?php

use App\Http\Controllers\AdminEventController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\MeController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', function () {
        return response()->json([
            'data' => [
                'status' => 'ok',
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    });

    Route::get('/events', [EventController::class, 'index']);
    Route::get('/events/{id}', [EventController::class, 'show']);

    Route::middleware('firebase')->group(function () {
        Route::get('/me', [MeController::class, 'show']);
        Route::patch('/me', [MeController::class, 'update']);

        Route::middleware('admin')->prefix('admin')->group(function () {
            Route::get('/events', [AdminEventController::class, 'index']);
        });
    });
});
