<?php

namespace App\Contracts;

interface PayWayGateway
{
    public function isEnabled(): bool;

    /**
     * @return array{tran_id: string, qr_code: string, qr_md5: string, aba_deeplink: string}
     */
    public function createKhqr(string $amount, string $currency, int $lifetimeMinutes): array;

    /**
     * @return array{amount: ?float, currency: ?string}|null
     */
    public function findApprovedTransaction(string $tranId): ?array;
}
