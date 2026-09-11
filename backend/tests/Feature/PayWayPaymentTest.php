<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PayWayPaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_payway_creates_a_merchant_khqr_with_aba_deeplink(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.method', 'aba_pay')
            ->assertJsonPath('data.amount', 0.01);

        $deeplink = (string) $created->json('data.aba_deeplink');
        $this->assertStringStartsWith('abamobilebank://ababank.com?type=payway', $deeplink);
        $this->assertNotEmpty($created->json('data.qr_code'));
        $this->assertNotNull(Payment::query()->find($created->json('data.id'))?->payway_tran_id);
    }

    public function test_payway_sync_stays_pending_until_approved(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $tranId = Payment::query()->findOrFail($paymentId)->payway_tran_id;

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertOk()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonMissingPath('data.ticket.id');

        $this->payway->approve((string) $tranId);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.ticket.status', 'valid');

        $this->assertDatabaseHas('tickets', [
            'event_id' => $event->id,
            'user_id' => $user->id,
            'status' => 'valid',
        ]);
    }

    public function test_payway_sync_rejects_a_mismatched_amount(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('1.00', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $tranId = Payment::query()->findOrFail($paymentId)->payway_tran_id;
        $this->payway->approve((string) $tranId, 0.01, 'USD');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'PAYMENT_MISMATCH');

        $this->assertDatabaseMissing('tickets', [
            'event_id' => $event->id,
            'user_id' => $user->id,
        ]);
    }

    public function test_default_payment_is_live_khqr_even_when_payway_is_enabled(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated()
            ->assertJsonPath('data.method', 'khqr')
            ->assertJsonMissingPath('data.aba_deeplink');
    }

    public function test_switching_from_payway_to_khqr_issues_a_live_bakong_qr(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $payway = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated();

        $khqr = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'khqr',
            ])
            ->assertOk()
            ->assertJsonPath('data.id', $payway->json('data.id'))
            ->assertJsonPath('data.method', 'khqr')
            ->assertJsonMissingPath('data.aba_deeplink');

        $this->assertNotSame($payway->json('data.qr_md5'), $khqr->json('data.qr_md5'));
        $this->assertNull(Payment::query()->find($khqr->json('data.id'))?->payway_tran_id);
    }

    public function test_paid_event_lists_sandbox_aba_pay_when_payway_is_enabled(): void
    {
        $this->payway->enabled = true;
        config(['services.payway.sandbox' => true]);

        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.payment_methods.0.id', 'khqr')
            ->assertJsonPath('data.payment_methods.1.id', 'aba_pay')
            ->assertJsonPath('data.payment_methods.1.sandbox', true)
            ->assertJsonPath('data.payment_methods.1.live', false);
    }

    public function test_bakong_payments_do_not_expose_an_aba_deeplink(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated()
            ->assertJsonPath('data.method', 'khqr')
            ->assertJsonMissingPath('data.aba_deeplink');
    }

    public function test_switching_to_khqr_after_payway_approval_issues_the_ticket(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $tranId = Payment::query()->findOrFail($paymentId)->payway_tran_id;
        $md5 = $created->json('data.qr_md5');
        $this->payway->approve((string) $tranId);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'khqr',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.method', 'aba_pay')
            ->assertJsonPath('data.qr_md5', $md5)
            ->assertJsonPath('data.ticket.status', 'valid');
    }

    public function test_start_after_payway_approval_on_an_expired_qr_issues_the_ticket(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $tranId = Payment::query()->findOrFail($paymentId)->payway_tran_id;
        $md5 = $created->json('data.qr_md5');

        Payment::query()->whereKey($paymentId)->update([
            'qr_expires_at' => now()->subMinute(),
        ]);
        $this->payway->approve((string) $tranId);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.qr_md5', $md5)
            ->assertJsonPath('data.ticket.status', 'valid');
    }
}
