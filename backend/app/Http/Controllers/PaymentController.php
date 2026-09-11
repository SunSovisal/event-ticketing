<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\User;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(
        private PaymentService $payments,
    ) {}

    public function store(StorePaymentRequest $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        ['payment' => $payment, 'created' => $created] = $this->payments->start(
            $id,
            $user,
            $request->paymentMethod(),
        );

        return $this->jsonResource(
            new PaymentResource($payment),
            $created ? 201 : 200,
        );
    }

    public function show(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $payment = $this->payments->show($id, $user);

        return $this->jsonResource(new PaymentResource($payment));
    }

    public function sync(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $payment = $this->payments->sync($id, $user);

        return $this->jsonResource(new PaymentResource($payment));
    }
}
