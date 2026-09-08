<?php

namespace App\Http\Controllers;

use App\Http\Requests\ChatRequest;
use App\Models\User;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;

class ChatController extends Controller
{
    public function __construct(
        private ChatService $chat,
    ) {}

    public function store(ChatRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $validated = $request->validated();
        $history = $validated['history'] ?? [];

        $result = $this->chat->reply(
            $user,
            $validated['message'],
            is_array($history) ? $history : [],
            (string) ($validated['locale'] ?? 'en'),
        );

        return response()->json([
            'data' => [
                'reply' => $result['reply'],
                'refused' => $result['refused'],
                'events' => $result['events'],
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
                'remaining_today' => $result['remaining_today'],
            ],
        ]);
    }
}
