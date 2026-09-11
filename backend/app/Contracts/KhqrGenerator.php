<?php

namespace App\Contracts;

interface KhqrGenerator
{
    /**
     * @return array{qr: string, md5: string}
     */
    public function generate(
        string $bakongAccountId,
        string $merchantName,
        string $merchantCity,
        string $currency,
        string $amount,
        int $expiresAtMs,
        ?string $billNumber = null,
    ): array;
}
