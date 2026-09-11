<?php

namespace Tests\Unit;

use App\Services\HttpPayWayGateway;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class HttpPayWayGatewayTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'services.payway.merchant_id' => 'ec000002',
            'services.payway.api_key' => 'test-api-key',
            'services.payway.base_url' => 'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase',
            'services.payway.qr_template' => 'template3_color',
        ]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_hash_is_hmac_sha512_base64_of_concatenated_fields(): void
    {
        $gateway = $this->app->make(HttpPayWayGateway::class);
        $concat = $gateway->concat([
            'req_time' => '20250212104216',
            'merchant_id' => 'ec000002',
            'tran_id' => 'abc123',
        ]);

        $this->assertSame('20250212104216ec000002abc123', $concat);
        $this->assertSame(
            base64_encode(hash_hmac('sha512', $concat, 'test-api-key', true)),
            $gateway->sign($concat),
        );
    }

    public function test_create_khqr_posts_generate_qr_to_the_origin_host(): void
    {
        Carbon::setTestNow(Carbon::parse('2025-02-12 10:42:16', 'UTC'));

        Http::fake([
            'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/generate-qr' => Http::response([
                'qrString' => '000201PAYWAYTEST',
                'abapay_deeplink' => 'abamobilebank://ababank.com?type=payway&qrcode=000201PAYWAYTEST',
                'status' => ['code' => '0', 'message' => 'Success.'],
            ], 200),
        ]);

        $result = $this->app->make(HttpPayWayGateway::class)->createKhqr('0.01', 'USD', 5);

        $this->assertSame('000201PAYWAYTEST', $result['qr_code']);
        $this->assertSame(md5('000201PAYWAYTEST'), $result['qr_md5']);
        $this->assertStringStartsWith('abamobilebank://ababank.com?type=payway', $result['aba_deeplink']);
        $this->assertSame(20, strlen($result['tran_id']));

        Http::assertSent(function (Request $request) {
            $body = $request->data();

            return $request->url() === 'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/generate-qr'
                && $body['merchant_id'] === 'ec000002'
                && $body['amount'] === '0.01'
                && $body['payment_option'] === 'abapay_khqr'
                && $body['lifetime'] === 5
                && $body['req_time'] === '20250212104216'
                && is_string($body['hash'])
                && $body['hash'] !== '';
        });
    }

    public function test_is_approved_when_payway_marks_the_transaction_approved(): void
    {
        Http::fake([
            'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction-2' => Http::response([
                'data' => [
                    'payment_status' => 'APPROVED',
                    'payment_status_code' => 0,
                    'amount' => '0.01',
                    'currency' => 'usd',
                    'status' => ['code' => '00', 'message' => 'Success!'],
                ],
            ], 200),
        ]);

        $this->assertTrue($this->app->make(HttpPayWayGateway::class)->isApproved('tran-1'));
        $settlement = $this->app->make(HttpPayWayGateway::class)->findApprovedTransaction('tran-1');
        $this->assertSame(0.01, $settlement['amount']);
        $this->assertSame('USD', $settlement['currency']);
    }

    public function test_is_not_approved_when_payway_has_not_seen_the_payment(): void
    {
        Http::fake([
            'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction-2' => Http::response([
                'data' => [
                    'status' => ['code' => '6', 'message' => 'Transaction not found'],
                ],
            ], 200),
        ]);

        $this->assertFalse($this->app->make(HttpPayWayGateway::class)->isApproved('tran-missing'));
    }
}
