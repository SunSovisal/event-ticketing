<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;

abstract class Controller
{
    protected function jsonResource(JsonResource $resource, int $status = 200): JsonResponse
    {
        return $resource
            ->additional([
                'meta' => [
                    'request_id' => (string) str()->uuid(),
                ],
            ])
            ->response()
            ->setStatusCode($status);
    }

    protected function jsonError(string $code, string $message, int $status): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => $code,
                'message' => $message,
                'fields' => new \stdClass,
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ], $status);
    }
}
