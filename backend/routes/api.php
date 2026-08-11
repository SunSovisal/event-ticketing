<?php
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function(){
    Route::get('/health', function() {
        return response()->json([
        'data' => [
            'status' => 'ok',
            ],
        'meta' => [
            'request_id' => (string) str()->uuid(),
        ],
        ]);
    });
});