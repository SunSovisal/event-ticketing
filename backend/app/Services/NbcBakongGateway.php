<?php

namespace App\Services;

use App\Contracts\BakongGateway;
use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Http;

class NbcBakongGateway implements BakongGateway
{
    public function findPaidTransaction(string $md5): ?array
    {
        $token = (string) config('services.bakong.access_token');
        $baseUrl = rtrim((string) config('services.bakong.base_url'), '/');

        if ($token === '' || $baseUrl === '') {
            throw new ApiException(
                'BAKONG_NOT_CONFIGURED',
                'Bakong is not configured.',
                503,
            );
        }

        $response = Http::timeout(15)
            ->acceptJson()
            ->withToken($token)
            ->post($baseUrl.'/check_transaction_by_md5', [
                'md5' => $md5,
            ]);

        if ($response->status() === 401) {
            throw new ApiException('BAKONG_UNAUTHORIZED', 'Bakong rejected the API token.', 502);
        }

        if (! $response->successful()) {
            throw new ApiException('BAKONG_UNAVAILABLE', 'Could not check Bakong payment status.', 502);
        }

        $payload = $response->json();
        if (! is_array($payload)) {
            return null;
        }

        if ((int) ($payload['responseCode'] ?? 1) !== 0) {
            return null;
        }

        $data = $payload['data'] ?? null;
        if (! is_array($data) || empty($data['hash'])) {
            return null;
        }

        return [
            'hash' => (string) $data['hash'],
            'fromAccountId' => (string) ($data['fromAccountId'] ?? ''),
            'toAccountId' => (string) ($data['toAccountId'] ?? ''),
            'currency' => strtoupper((string) ($data['currency'] ?? '')),
            'amount' => (float) ($data['amount'] ?? 0),
        ];
    }
}
