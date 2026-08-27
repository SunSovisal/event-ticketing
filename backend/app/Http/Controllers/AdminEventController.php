<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Requests\AdminEventRequest;
use App\Http\Resources\AdminAttendeeResource;
use App\Http\Resources\CheckInAttemptResource;
use App\Http\Resources\EventResource;
use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\Ticket;
use App\Services\EventCoverService;
use App\Services\EventLifecycleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminEventController extends Controller
{
    public function __construct(
        private EventLifecycleService $lifecycle,
        private EventCoverService $covers,
    ) {}

    public function index(): JsonResponse
    {
        $events = Event::query()
            ->withTicketCounts()
            ->orderBy('starts_at')
            ->get();

        return $this->jsonResource(EventResource::collection($events));
    }

    public function store(AdminEventRequest $request): JsonResponse
    {
        $event = Event::query()->create([
            ...$request->eventAttributes(),
            'status' => 'draft',
        ]);

        return $this->jsonResource(
            new EventResource($this->adminEvent($event->id)),
            201,
        );
    }

    public function show(string $id): JsonResponse
    {
        return $this->jsonResource(new EventResource($this->adminEvent($id)));
    }

    public function update(AdminEventRequest $request, string $id): JsonResponse
    {
        $event = Event::query()->whereKey($id)->first();

        if ($event === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        if ($event->status === 'cancelled') {
            throw new ApiException('EVENT_CANCELLED', 'Cancelled events cannot be updated.', 422);
        }

        $attributes = $request->eventAttributes();
        $reserved = $event->tickets()
            ->whereIn('status', ['valid', 'checked_in'])
            ->count();

        if ($attributes['capacity'] < $reserved) {
            throw new ApiException(
                'CAPACITY_BELOW_RESERVED',
                'Capacity cannot be below the number of reserved tickets.',
                409,
            );
        }

        $event->update($attributes);

        return $this->jsonResource(new EventResource($this->adminEvent($event->id)));
    }

    public function uploadCover(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'file', 'image', 'mimes:jpeg,jpg,png,webp', 'max:5120'],
        ]);

        $event = $this->covers->upload($id, $request->file('image'));

        return $this->jsonResource(new EventResource($this->adminEvent($event->id)));
    }

    public function destroyCover(string $id): JsonResponse
    {
        $event = $this->covers->delete($id);

        return $this->jsonResource(new EventResource($this->adminEvent($event->id)));
    }

    public function publish(string $id): JsonResponse
    {
        $event = $this->lifecycle->publish($id);

        return $this->jsonResource(new EventResource($this->adminEvent($event->id)));
    }

    public function cancel(string $id): JsonResponse
    {
        $event = $this->lifecycle->cancel($id);

        return $this->jsonResource(new EventResource($this->adminEvent($event->id)));
    }

    public function destroy(string $id): JsonResponse
    {
        $deletedId = $this->lifecycle->deleteDraft($id);

        return response()->json([
            'data' => [
                'id' => $deletedId,
                'deleted' => true,
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function attendees(string $id): JsonResponse
    {
        $this->requireEvent($id);

        $tickets = Ticket::query()
            ->where('event_id', $id)
            ->with('user.profile')
            ->orderBy('created_at')
            ->get();

        return $this->jsonResource(AdminAttendeeResource::collection($tickets));
    }

    public function checkInAttempts(string $id): JsonResponse
    {
        $this->requireEvent($id);

        $attempts = CheckInAttempt::query()
            ->where('event_id', $id)
            ->orderByDesc('created_at')
            ->get();

        return $this->jsonResource(CheckInAttemptResource::collection($attempts));
    }

    private function adminEvent(string $id): Event
    {
        $event = Event::query()->withTicketCounts()->find($id);

        if ($event === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        return $event;
    }

    private function requireEvent(string $id): Event
    {
        $event = Event::query()->find($id);

        if ($event === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        return $event;
    }
}
