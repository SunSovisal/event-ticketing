<?php

namespace App\Http\Controllers;

use App\Http\Resources\EventResource;
use App\Models\User;
use App\Services\SavedEventService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SavedEventController extends Controller
{
    public function __construct(
        private SavedEventService $savedEvents,
    ) {}

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        return $this->jsonResource(
            EventResource::collection($this->savedEvents->listFor($user)),
        );
    }

    public function store(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        return $this->jsonResource(
            new EventResource($this->savedEvents->save($id, $user)),
        );
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        return $this->jsonResource(
            new EventResource($this->savedEvents->unsave($id, $user)),
        );
    }
}
