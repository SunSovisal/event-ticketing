<?php

namespace App\Http\Controllers;

use App\Http\Resources\EventResource;
use App\Models\Event;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $events = Event::query()
            ->publishedUpcoming()
            ->withTicketCounts()
            ->withSavedFlag($this->viewer($request))
            ->orderBy('starts_at')
            ->get();

        return $this->jsonResource(EventResource::collection($events));
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $event = Event::query()
            ->publishedUpcoming()
            ->withTicketCounts()
            ->withSavedFlag($this->viewer($request))
            ->find($id);

        if ($event === null) {
            return $this->jsonError('NOT_FOUND', 'Event not found.', 404);
        }

        return $this->jsonResource(new EventResource($event));
    }

    private function viewer(Request $request): ?User
    {
        $user = $request->attributes->get('auth_user');

        return $user instanceof User ? $user : null;
    }
}
