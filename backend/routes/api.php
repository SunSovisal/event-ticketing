<?php

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
    // checks authentication before calling MeController
    Route::middleware('firebase')->group(function () {
        Route::get('/me', [MeController::class, 'show']);
        Route::patch('/me', [MeController::class, 'update']);
    });
});
