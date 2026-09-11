<?php

namespace Tests\Support;

use App\Contracts\BakongGateway;

class FakeBakongGateway implements BakongGateway
{
    /**
     * @var array<string, array{hash: string, fromAccountId: string, toAccountId: string, currency: string, amount: float}>
     */
    public array $paidByMd5 = [];

    public function pay(string $md5, float $amount = 0.01, string $currency = 'USD', string $toAccountId = 'itc.events@abaa'): void
    {
        $this->paidByMd5[$md5] = [
            'hash' => str_repeat('ab', 32),
            'fromAccountId' => 'payer@abaa',
            'toAccountId' => $toAccountId,
            'currency' => $currency,
            'amount' => $amount,
        ];
    }

    public function findPaidTransaction(string $md5): ?array
    {
        return $this->paidByMd5[$md5] ?? null;
    }
}
