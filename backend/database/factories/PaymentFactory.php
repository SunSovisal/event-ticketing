<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Payment>
 */
class PaymentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $qr = '000201'.Str::lower(Str::random(40));

        return [
            'event_id' => Event::factory()->published()->paid(),
            'user_id' => User::factory(),
            'ticket_id' => null,
            'amount' => '0.01',
            'currency' => 'USD',
            'status' => 'pending',
            'method' => 'khqr',
            'qr_code' => $qr,
            'qr_md5' => md5($qr),
            'qr_expires_at' => now()->addMinutes(5),
        ];
    }

    public function paid(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'paid',
            'paid_at' => now(),
            'bakong_hash' => str_repeat('a', 64),
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'expired',
            'qr_expires_at' => now()->subSeconds(Payment::graceSeconds() + 60),
        ]);
    }

    public function scanExpired(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
            'qr_expires_at' => now()->subMinute(),
        ]);
    }
}
