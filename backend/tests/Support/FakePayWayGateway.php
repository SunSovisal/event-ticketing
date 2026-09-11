<?php

namespace Tests\Support;

use App\Contracts\PayWayGateway;

class FakePayWayGateway implements PayWayGateway
{
    public bool $enabled = false;

    /** @var array<string, bool> */
    public array $approvedByTranId = [];

    /** @var array<string, array{amount: float, currency: string}> */
    public array $createdByTranId = [];

    /** @var array<string, array{amount: ?float, currency: ?string}> */
    public array $settlementByTranId = [];

    public function isEnabled(): bool
    {
        return $this->enabled;
    }

    public function createKhqr(string $amount, string $currency, int $lifetimeMinutes): array
    {
        $tranId = 'pw'.substr(md5($amount.$currency.microtime()), 0, 18);
        $qr = '000201PAYWAY'.$tranId;
        $this->createdByTranId[$tranId] = [
            'amount' => (float) $amount,
            'currency' => strtoupper($currency),
        ];

        return [
            'tran_id' => $tranId,
            'qr_code' => $qr,
            'qr_md5' => md5($qr),
            'aba_deeplink' => 'abamobilebank://ababank.com?type=payway&qrcode='.rawurlencode($qr),
        ];
    }

    public function findApprovedTransaction(string $tranId): ?array
    {
        if (! ($this->approvedByTranId[$tranId] ?? false)) {
            return null;
        }

        return $this->settlementByTranId[$tranId]
            ?? $this->createdByTranId[$tranId]
            ?? ['amount' => 0.01, 'currency' => 'USD'];
    }

    public function approve(string $tranId, ?float $amount = null, ?string $currency = null): void
    {
        $this->approvedByTranId[$tranId] = true;
        if ($amount !== null || $currency !== null) {
            $this->settlementByTranId[$tranId] = [
                'amount' => $amount,
                'currency' => $currency !== null ? strtoupper($currency) : null,
            ];
        }
    }
}
