<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Resources\TicketResource;
use App\Models\Ticket;
use App\Models\User;
use App\Services\TicketService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function __construct(
        private TicketService $tickets,
    ) {}

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $tickets = Ticket::query()
            ->where('user_id', $user->id)
            ->with('event')
            ->orderByDesc('created_at')
            ->get();

        return $this->jsonResource(TicketResource::collection($tickets));
    }

    public function show(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $ticket = Ticket::query()->with('event')->find($id);

        if ($ticket === null) {
            throw new ApiException('NOT_FOUND', 'Ticket not found.', 404);
        }

        if ($ticket->user_id !== $user->id) {
            throw new ApiException('FORBIDDEN', 'You cannot access this ticket.', 403);
        }

        return $this->jsonResource(new TicketResource($ticket));
    }

    public function store(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        ['ticket' => $ticket, 'created' => $created] = $this->tickets->reserve($id, $user);

        return $this->jsonResource(
            new TicketResource($ticket),
            $created ? 201 : 200,
        );
    }
}
