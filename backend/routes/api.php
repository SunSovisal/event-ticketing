<?php

use App\Http\Controllers\AdminCheckInController;
use App\Http\Controllers\AdminEventController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\MeController;
use App\Http\Controllers\SavedEventController;
use App\Http\Controllers\TicketController;
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

    Route::middleware('throttle:api')->group( function(){
        Route::middleware('firebase:optional')->group(function () {
            Route::get('/events', [EventController::class, 'index']);
            Route::get('/events/{id}', [EventController::class, 'show']);
        });
        
        Route::middleware('firebase')->group(function () {
            Route::get('/me', [MeController::class, 'show']);
            Route::patch('/me', [MeController::class, 'update']);

            Route::post('/events/{id}/tickets', [TicketController::class, 'store'])->middleware('throttle:api');
            Route::post('/events/{id}/save', [SavedEventController::class, 'store']);
            Route::delete('/events/{id}/save', [SavedEventController::class, 'destroy']);
            Route::get('/saved-events', [SavedEventController::class, 'index']);
            Route::get('/tickets', [TicketController::class, 'index']);
            Route::get('/tickets/{id}', [TicketController::class, 'show']);

            Route::middleware('admin')->prefix('admin')->group(function () {
                Route::get('/events', [AdminEventController::class, 'index']);
                Route::post('/events', [AdminEventController::class, 'store']);
                Route::get('/events/{id}', [AdminEventController::class, 'show']);
                Route::patch('/events/{id}', [AdminEventController::class, 'update']);
                Route::post('/events/{id}/cover', [AdminEventController::class, 'uploadCover']);
                Route::delete('/events/{id}/cover', [AdminEventController::class, 'destroyCover']);
                Route::post('/events/{id}/publish', [AdminEventController::class, 'publish']);
                Route::post('/events/{id}/cancel', [AdminEventController::class, 'cancel']);
                Route::delete('/events/{id}', [AdminEventController::class, 'destroy']);
                Route::post('/check-in', [AdminCheckInController::class, 'store']);
            });
        });
    });
});
