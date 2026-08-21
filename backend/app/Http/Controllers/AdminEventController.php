<?php

namespace App\Http\Controllers;

use App\Http\Resources\EventResource;
use App\Models\Event;
use Illuminate\Http\JsonResponse;

class AdminEventController extends Controller
{
    public function index(): JsonResponse
    {
        $events = Event::query()
            ->withTicketCounts()
            ->orderBy('starts_at')
            ->get();

        return $this->jsonResource(EventResource::collection($events));
    }
}
