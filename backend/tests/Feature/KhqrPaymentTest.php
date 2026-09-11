<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class KhqrPaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_free_event_still_reserves_a_ticket_immediately(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/tickets')
            ->assertCreated()
            ->assertJsonPath('data.status', 'valid');

        $this->assertDatabaseCount('tickets', 1);
        $this->assertDatabaseCount('payments', 0);
    }

    public function test_paid_event_rejects_the_free_ticket_endpoint(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid()->create();

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/tickets')
            ->assertStatus(402)
            ->assertJsonPath('error.code', 'PAYMENT_REQUIRED');
    }

    public function test_paid_event_creates_a_dynamic_khqr_and_reuses_it(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $first = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.amount', 0.01)
            ->assertJsonPath('data.currency', 'USD');

        $this->assertNotEmpty($first->json('data.qr_code'));
        $this->assertSame(32, strlen((string) $first->json('data.qr_md5')));
        $this->assertSame('khqr', $first->json('data.method'));

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertOk()
            ->assertJsonPath('data.id', $first->json('data.id'))
            ->assertJsonPath('data.qr_md5', $first->json('data.qr_md5'));
    }

    public function test_sync_stays_pending_until_bakong_confirms_then_issues_a_ticket(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $md5 = $created->json('data.qr_md5');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertOk()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonMissingPath('data.ticket.id');

        $this->bakong->pay($md5, 0.01, 'USD', 'itc.events@abaa');

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

    public function test_another_user_cannot_read_or_sync_a_payment(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($owner)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $paymentId = $created->json('data.id');

        $this->actingAsFirebaseUser($stranger)
            ->getJson('/api/v1/payments/'.$paymentId)
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->actingAsFirebaseUser($stranger)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_sync_does_not_overbook_when_another_hold_took_the_last_seat(): void
    {
        $event = Event::factory()->published()->paid('0.01', 'USD')->create(['capacity' => 1]);
        $first = User::factory()->create();
        $second = User::factory()->create();

        $created = $this->actingAsFirebaseUser($first)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $md5 = $created->json('data.qr_md5');

        Payment::query()->whereKey($paymentId)->update([
            'qr_expires_at' => now()->subSeconds(Payment::graceSeconds() + 60),
        ]);

        $this->actingAsFirebaseUser($second)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $this->bakong->pay($md5, 0.01, 'USD', 'itc.events@abaa');

        $this->actingAsFirebaseUser($first)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'EVENT_FULL');

        $this->assertDatabaseMissing('tickets', [
            'event_id' => $event->id,
            'user_id' => $first->id,
        ]);
    }

    public function test_expired_qr_cannot_be_synced(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid()->create();
        $payment = Payment::factory()->expired()->create([
            'event_id' => $event->id,
            'user_id' => $user->id,
            'status' => 'pending',
        ]);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$payment->id.'/sync')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'QR_EXPIRED');
    }

    public function test_wrong_amount_is_rejected(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('1.00', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $this->bakong->pay($created->json('data.qr_md5'), 0.01, 'USD', 'itc.events@abaa');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$created->json('data.id').'/sync')
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'PAYMENT_MISMATCH');
    }

    public function test_pending_khqr_holds_capacity(): void
    {
        $event = Event::factory()->published()->paid()->create(['capacity' => 1]);
        $holder = User::factory()->create();
        $other = User::factory()->create();

        $this->actingAsFirebaseUser($holder)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $this->actingAsFirebaseUser($other)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'EVENT_FULL');
    }

    public function test_public_event_json_includes_price(): void
    {
        $event = Event::factory()->published()->paid('2.50', 'USD')->create();

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.is_free', false)
            ->assertJsonPath('data.price_amount', 2.5)
            ->assertJsonPath('data.price_currency', 'USD')
            ->assertJsonPath('data.payment_methods.0.id', 'khqr')
            ->assertJsonPath('data.payment_methods.0.live', true)
            ->assertJsonMissingPath('data.payment_methods.1.id');
    }

    public function test_admin_can_create_a_paid_draft(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->postJson('/api/v1/admin/events', [
                'title' => 'Paid workshop',
                'description' => 'KHQR entry.',
                'starts_at' => now()->addDays(3)->utc()->toIso8601String(),
                'location_label' => 'Building A - Hall',
                'category' => 'Workshop',
                'capacity' => 40,
                'price_amount' => 0.01,
                'price_currency' => 'USD',
            ])
            ->assertCreated()
            ->assertJsonPath('data.is_free', false)
            ->assertJsonPath('data.price_amount', 0.01);
    }

    public function test_grace_hold_blocks_the_last_seat_after_the_qr_timer(): void
    {
        $event = Event::factory()->published()->paid('0.01', 'USD')->create(['capacity' => 1]);
        $holder = User::factory()->create();
        $other = User::factory()->create();

        $created = $this->actingAsFirebaseUser($holder)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        Payment::query()->whereKey($created->json('data.id'))->update([
            'qr_expires_at' => now()->subMinute(),
        ]);

        $this->actingAsFirebaseUser($other)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'EVENT_FULL');
    }

    public function test_late_bakong_payment_during_grace_still_issues_a_ticket(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $paymentId = $created->json('data.id');
        $md5 = $created->json('data.qr_md5');

        Payment::query()->whereKey($paymentId)->update([
            'qr_expires_at' => now()->subMinute(),
        ]);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertOk()
            ->assertJsonPath('data.status', 'pending');

        $this->bakong->pay($md5, 0.01, 'USD', 'itc.events@abaa');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$paymentId.'/sync')
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.ticket.status', 'valid');
    }

    public function test_unpaid_sync_after_grace_expires_the_qr(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid()->create();
        $payment = Payment::factory()->scanExpired()->create([
            'event_id' => $event->id,
            'user_id' => $user->id,
            'qr_expires_at' => now()->subSeconds(Payment::graceSeconds() + 60),
        ]);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/payments/'.$payment->id.'/sync')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'QR_EXPIRED');

        $this->assertDatabaseHas('payments', [
            'id' => $payment->id,
            'status' => 'expired',
        ]);
    }

    public function test_start_after_bakong_payment_issues_the_ticket_instead_of_a_new_qr(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $md5 = $created->json('data.qr_md5');
        Payment::query()->whereKey($created->json('data.id'))->update([
            'qr_expires_at' => now()->subMinute(),
        ]);
        $this->bakong->pay($md5, 0.01, 'USD', 'itc.events@abaa');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.qr_md5', $md5)
            ->assertJsonPath('data.ticket.status', 'valid');
    }

    public function test_switching_method_after_bakong_payment_keeps_the_paid_qr(): void
    {
        $this->payway->enabled = true;

        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $md5 = $created->json('data.qr_md5');
        $this->bakong->pay($md5, 0.01, 'USD', 'itc.events@abaa');

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments', [
                'method' => 'aba_pay',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.method', 'khqr')
            ->assertJsonPath('data.qr_md5', $md5)
            ->assertJsonPath('data.ticket.status', 'valid');

        $this->assertNull(Payment::query()->find($created->json('data.id'))?->payway_tran_id);
    }

    public function test_start_after_grace_without_payment_mints_a_new_qr(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->published()->paid('0.01', 'USD')->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        $oldMd5 = $created->json('data.qr_md5');

        Payment::query()->whereKey($created->json('data.id'))->update([
            'qr_expires_at' => now()->subSeconds(Payment::graceSeconds() + 60),
        ]);

        $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertOk()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonMissingPath('data.ticket.id');

        $this->assertNotSame(
            $oldMd5,
            Payment::query()->find($created->json('data.id'))?->qr_md5,
        );
    }

    public function test_spots_remaining_counts_a_grace_hold(): void
    {
        $event = Event::factory()->published()->paid('0.01', 'USD')->create(['capacity' => 2]);
        $user = User::factory()->create();

        $created = $this->actingAsFirebaseUser($user)
            ->postJson('/api/v1/events/'.$event->id.'/payments')
            ->assertCreated();

        Payment::query()->whereKey($created->json('data.id'))->update([
            'qr_expires_at' => now()->subMinute(),
        ]);

        $this->getJson('/api/v1/events/'.$event->id)
            ->assertOk()
            ->assertJsonPath('data.spots_remaining', 1);
    }
}
