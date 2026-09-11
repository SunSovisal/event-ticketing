<?php

namespace Tests\Unit;

use App\Services\IndividualKhqrGenerator;
use PHPUnit\Framework\TestCase;

class IndividualKhqrGeneratorTest extends TestCase
{
    public function test_dynamic_qr_includes_account_amount_and_valid_crc(): void
    {
        $generator = new IndividualKhqrGenerator;
        $expiresAt = (int) floor(microtime(true) * 1000) + 300_000;

        $result = $generator->generate(
            'itc.events@abaa',
            'ITC Events',
            'PHNOM PENH',
            'USD',
            '0.01',
            $expiresAt,
            'PAYTEST',
        );

        $qr = $result['qr'];

        $this->assertSame(32, strlen($result['md5']));
        $this->assertSame(md5($qr), $result['md5']);
        $this->assertStringStartsWith('000201010212', $qr);
        $this->assertStringContainsString('itc.events@abaa', $qr);
        $this->assertStringContainsString('54040.01', $qr);
        $this->assertStringContainsString('PAYTEST', $qr);

        $body = substr($qr, 0, -4);
        $crc = substr($qr, -4);
        $this->assertSame($generator->crc16($body), $crc);
    }
}
