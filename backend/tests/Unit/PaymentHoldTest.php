<?php

namespace Tests\Unit;

use App\Models\Payment;
use Tests\TestCase;

class PaymentHoldTest extends TestCase
{
    public function test_hold_outlives_the_qr_timer_by_the_grace_window(): void
    {
        config(['services.bakong.grace_seconds' => 120]);

        $payment = new Payment;
        $payment->qr_expires_at = now();

        $this->assertTrue($payment->qrHasExpired());
        $this->assertFalse($payment->holdHasExpired());
        $this->assertTrue($payment->holdHasExpired(now()->addSeconds(120)));
        $this->assertTrue(
            $payment->holdExpiresAt()->equalTo($payment->qr_expires_at->copy()->addSeconds(120)),
        );
    }
}
