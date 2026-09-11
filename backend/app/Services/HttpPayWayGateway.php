<?php

namespace App\Services;

use App\Contracts\PayWayGateway;
use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class HttpPayWayGateway implements PayWayGateway
{
    public function isEnabled(): bool
    {
        return $this->merchantId() !== '' && $this->apiKey() !== '';
    }

    public function createKhqr(string $amount, string $currency, int $lifetimeMinutes): array
    {
        $this->assertConfigured();

        $tranId = $this->newTranId();
        $reqTime = now('UTC')->format('YmdHis');
        $lifetime = max(3, $lifetimeMinutes);
        $template = (string) config('services.payway.qr_template', 'template3_color');
        $option = 'abapay_khqr';
        $purchaseType = 'purchase';
        $currency = strtoupper($currency);

        $fields = [
            'req_time' => $reqTime,
            'merchant_id' => $this->merchantId(),
            'tran_id' => $tranId,
            'amount' => $amount,
            'items' => '',
            'first_name' => '',
            'last_name' => '',
            'email' => '',
            'phone' => '',
            'purchase_type' => $purchaseType,
            'payment_option' => $option,
            'callback_url' => '',
            'return_deeplink' => '',
            'currency' => $currency,
            'custom_fields' => '',
            'return_params' => '',
            'payout' => '',
            'lifetime' => (string) $lifetime,
            'qr_image_template' => $template,
        ];

        $payload = [
            ...$fields,
            'lifetime' => $lifetime,
            'hash' => $this->sign($this->concat($fields)),
        ];

        $response = Http::timeout(20)
            ->acceptJson()
            ->asJson()
            ->post($this->origin().'/api/payment-gateway/v1/payments/generate-qr', $payload);

        $body = $response->json();
        if (! is_array($body)) {
            throw new ApiException('PAYWAY_UNAVAILABLE', 'Could not create PayWay KHQR.', 502);
        }

        $this->assertPayWayOk($body, $response->status());

        $qr = $body['qrString'] ?? $body['data']['qrString'] ?? null;
        $deeplink = $body['abapay_deeplink'] ?? $body['data']['abapay_deeplink'] ?? null;

        if (! is_string($qr) || $qr === '') {
            throw new ApiException('PAYWAY_UNAVAILABLE', 'PayWay did not return a KHQR.', 502);
        }

        return [
            'tran_id' => $tranId,
            'qr_code' => $qr,
            'qr_md5' => md5($qr),
            'aba_deeplink' => is_string($deeplink) ? $deeplink : '',
        ];
    }

    public function isApproved(string $tranId): bool
    {
        return $this->findApprovedTransaction($tranId) !== null;
    }

    public function findApprovedTransaction(string $tranId): ?array
    {
        $this->assertConfigured();

        $reqTime = now('UTC')->format('YmdHis');
        $payload = [
            'req_time' => $reqTime,
            'merchant_id' => $this->merchantId(),
            'tran_id' => $tranId,
            'hash' => $this->sign($reqTime.$this->merchantId().$tranId),
        ];

        $response = Http::timeout(20)
            ->acceptJson()
            ->asJson()
            ->post($this->origin().'/api/payment-gateway/v1/payments/check-transaction-2', $payload);

        $body = $response->json();
        if (! is_array($body)) {
            throw new ApiException('PAYWAY_UNAVAILABLE', 'Could not check PayWay payment status.', 502);
        }

        $data = is_array($body['data'] ?? null) ? $body['data'] : $body;
        $apiStatus = is_array($data['status'] ?? null) ? $data['status'] : ($body['status'] ?? []);
        $apiCode = (string) ($apiStatus['code'] ?? '');

        if (in_array($apiCode, ['5', '8', '11', '429'], true)) {
            throw new ApiException('PAYWAY_UNAVAILABLE', 'PayWay rejected the payment check.', 502);
        }

        if ($apiCode === '6') {
            return null;
        }

        $paymentStatus = strtoupper((string) ($data['payment_status'] ?? ''));
        $paymentCode = (int) ($data['payment_status_code'] ?? -1);
        $approved = in_array($paymentStatus, ['APPROVED', 'PRE-AUTH'], true) || $paymentCode === 0;

        if (! $approved) {
            return null;
        }

        $amount = $data['amount'] ?? $data['total_amount'] ?? null;
        $currency = $data['currency'] ?? null;

        return [
            'amount' => is_numeric($amount) ? round((float) $amount, 2) : null,
            'currency' => is_string($currency) && $currency !== '' ? strtoupper($currency) : null,
        ];
    }

    public function sign(string $concatenated): string
    {
        return base64_encode(hash_hmac('sha512', $concatenated, $this->apiKey(), true));
    }

    /**
     * @param  array<string, string>  $fields
     */
    public function concat(array $fields): string
    {
        return implode('', array_values($fields));
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function assertPayWayOk(array $body, int $httpStatus): void
    {
        $code = (string) ($body['status']['code'] ?? $body['data']['status']['code'] ?? '');
        $message = (string) ($body['status']['message'] ?? $body['data']['status']['message'] ?? 'PayWay request failed.');

        if ($code === '0' || $code === '00') {
            return;
        }

        if ($httpStatus >= 200 && $httpStatus < 300 && $code === '') {
            return;
        }

        if ($code === '1') {
            throw new ApiException('PAYWAY_HASH', 'PayWay rejected the request signature.', 502);
        }

        if (in_array($code, ['6', '102'], true)) {
            throw new ApiException(
                'PAYWAY_DOMAIN',
                'PayWay blocked this server IP or domain. Ask ABA to whitelist it for sandbox.',
                502,
            );
        }

        throw new ApiException('PAYWAY_UNAVAILABLE', $message !== '' ? $message : 'PayWay could not create the KHQR.', 502);
    }

    private function newTranId(): string
    {
        return substr(str_replace('-', '', (string) Str::ulid()), 0, 20);
    }

    private function origin(): string
    {
        $raw = rtrim((string) config('services.payway.base_url'), '/');
        if (str_contains($raw, '/api/')) {
            return explode('/api/', $raw)[0];
        }

        return $raw;
    }

    private function merchantId(): string
    {
        return trim((string) config('services.payway.merchant_id'));
    }

    private function apiKey(): string
    {
        return trim((string) config('services.payway.api_key'));
    }

    private function assertConfigured(): void
    {
        if (! $this->isEnabled()) {
            throw new ApiException('PAYWAY_NOT_CONFIGURED', 'PayWay is not configured.', 503);
        }
    }
}
