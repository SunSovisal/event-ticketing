<?php

use App\Http\Controllers\Admin\CheckInController as AdminCheckInController;
use App\Http\Controllers\Admin\EventController as AdminEventController;
use App\Http\Controllers\Admin\KpiController as AdminKpiController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\InboxNotificationController;
use App\Http\Controllers\Api\MeController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\SavedEventController;
use App\Http\Controllers\Api\TicketController;
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

    Route::middleware('throttle:api')->group(function () {
        Route::middleware('firebase:optional')->group(function () {
            Route::get('/events', [EventController::class, 'index']);
            Route::get('/events/{id}', [EventController::class, 'show']);
            Route::get('/notifications', [InboxNotificationController::class, 'index']);
        });

        Route::middleware('firebase')->group(function () {
            Route::get('/me', [MeController::class, 'show']);
            Route::patch('/me', [MeController::class, 'update']);

            Route::post('/chat', [ChatController::class, 'store'])
                ->middleware('throttle:chat');

            Route::post('/events/{id}/tickets', [TicketController::class, 'store'])->middleware('throttle:api');
            Route::post('/events/{id}/payments', [PaymentController::class, 'store']);
            Route::get('/payments/{id}', [PaymentController::class, 'show']);
            Route::post('/payments/{id}/sync', [PaymentController::class, 'sync'])
                ->middleware('throttle:payment-sync');
            Route::post('/events/{id}/save', [SavedEventController::class, 'store']);
            Route::delete('/events/{id}/save', [SavedEventController::class, 'destroy']);
            Route::get('/saved-events', [SavedEventController::class, 'index']);
            Route::post('/notifications/read-all', [InboxNotificationController::class, 'markAllRead']);
            Route::post('/notifications/{id}/read', [InboxNotificationController::class, 'markRead']);
            Route::get('/tickets', [TicketController::class, 'index']);
            Route::get('/tickets/{id}', [TicketController::class, 'show']);

            Route::middleware('admin')->prefix('admin')->group(function () {
                Route::get('/kpis', [AdminKpiController::class, 'index']);
                Route::get('/events/{id}/kpis', [AdminKpiController::class, 'show']);
                Route::get('/events', [AdminEventController::class, 'index']);
                Route::post('/events', [AdminEventController::class, 'store']);
                Route::get('/events/{id}', [AdminEventController::class, 'show']);
                Route::patch('/events/{id}', [AdminEventController::class, 'update']);
                Route::get('/events/{id}/attendees', [AdminEventController::class, 'attendees']);
                Route::get('/events/{id}/check-in-attempts', [AdminEventController::class, 'checkInAttempts']);
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
