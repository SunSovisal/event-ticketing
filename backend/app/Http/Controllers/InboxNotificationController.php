<?php

namespace App\Http\Controllers;

use App\Http\Resources\InboxNotificationResource;
use App\Models\User;
use App\Services\InboxNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InboxNotificationController extends Controller
{
    public function __construct(
        private InboxNotificationService $inbox,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $this->viewer($request);

        return $this->jsonResource(
            InboxNotificationResource::collection($this->inbox->listFor($user)),
            meta: ['unread_count' => $this->inbox->unreadCountFor($user)],
        );
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        return $this->jsonResource(
            new InboxNotificationResource($this->inbox->markRead($id, $user)),
            meta: ['unread_count' => $this->inbox->unreadCountFor($user)],
        );
    }

    public function markAllRead(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $this->inbox->markAllRead($user);

        return $this->index($request);
    }

    private function viewer(Request $request): ?User
    {
        $user = $request->attributes->get('auth_user');

        return $user instanceof User ? $user : null;
    }
}
