<?php

namespace App\Http\Controllers;

use App\Http\Resources\EventResource;
use App\Models\Event;
use Illuminate\Http\JsonResponse;

class EventController extends Controller
{
    public function index(): JsonResponse
    {
        $events = Event::query()
            ->publishedUpcoming()
            ->withTicketCounts()
            ->orderBy('starts_at')
            ->get();

        return $this->jsonResource(EventResource::collection($events));
    }

    public function show(string $id): JsonResponse
    {
        $event = Event::query()
            ->publishedUpcoming()
            ->withTicketCounts()
            ->find($id);

        if ($event === null) {
            return $this->jsonError('NOT_FOUND', 'Event not found.', 404);
        }

        return $this->jsonResource(new EventResource($event));
    }
}
