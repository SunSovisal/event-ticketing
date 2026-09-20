<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\CheckInRequest;
use App\Http\Resources\TicketResource;
use App\Models\User;
use App\Services\CheckInService;
use Illuminate\Http\JsonResponse;

class CheckInController extends Controller
{
    public function store(CheckInRequest $request, CheckInService $checkIn): JsonResponse
    {
        /** @var User $admin */
        $admin = $request->attributes->get('auth_user');

        $ticket = $checkIn->checkIn(
            $request->ticketCode(),
            $admin,
            $request->checkInMethod(),
        );

        return $this->jsonResource(new TicketResource($ticket));
    }
}
