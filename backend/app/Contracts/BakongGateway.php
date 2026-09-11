<?php

namespace App\Contracts;

interface BakongGateway
{
    /**
     * @return array{
     *     hash: string,
     *     fromAccountId: string,
     *     toAccountId: string,
     *     currency: string,
     *     amount: float
     * }|null
     */
    public function findPaidTransaction(string $md5): ?array;
}
