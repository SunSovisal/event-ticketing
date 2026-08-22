<?php

namespace App\Http\Controllers;

use App\Http\Resources\TicketResource;
use App\Models\User;
use App\Services\CheckInService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminCheckInController extends Controller
{
    public function store(Request $request, CheckInService $checkIn): JsonResponse
    {
        $validated = $request->validate([
            'ticket_code' => ['required', 'string', 'max:64'],
            'method' => ['sometimes', 'in:qr,manual'],
        ]);

        /** @var User $admin */
        $admin = $request->attributes->get('auth_user');

        $ticket = $checkIn->checkIn(
            $validated['ticket_code'],
            $admin,
            $validated['method'] ?? 'qr',
        );

        return $this->jsonResource(new TicketResource($ticket));
    }
}
