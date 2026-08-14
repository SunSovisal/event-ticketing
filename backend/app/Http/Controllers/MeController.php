<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        return response()->json([
            'data' => $user->toProfile(),
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:255'],
        ]);

        /** @var User $user */
        $user = $request->attributes->get('auth_user');
        $user->update([
            'name' => trim($validated['name']),
            'email' => trim($validated['email']),
        ]);

        return response()->json([
            'data' => $user->fresh()->toProfile(),
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ]
        ]);
    }
}
