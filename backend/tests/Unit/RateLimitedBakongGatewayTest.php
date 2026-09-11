<?php

namespace Tests\Unit;

use App\Contracts\BakongGateway;
use App\Exceptions\ApiException;
use App\Services\RateLimitedBakongGateway;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class RateLimitedBakongGatewayTest extends TestCase
{
    private CountingBakongGateway $inner;

    private RateLimitedBakongGateway $gateway;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();
        config([
            'services.bakong.daily_limit' => 2,
            'services.bakong.min_check_seconds' => 5,
        ]);

        $this->inner = new CountingBakongGateway;
        $this->gateway = new RateLimitedBakongGateway($this->inner);
    }

    protected function tearDown(): void
    {
        $this->travelBack();
        parent::tearDown();
    }

    public function test_repeat_checks_wait_for_the_cooldown(): void
    {
        $this->assertNull($this->gateway->findPaidTransaction('md5-a'));
        $this->assertNull($this->gateway->findPaidTransaction('md5-a'));
        $this->assertSame(1, $this->inner->calls);

        $this->travel(6)->seconds();

        $this->assertNull($this->gateway->findPaidTransaction('md5-a'));
        $this->assertSame(2, $this->inner->calls);
    }

    public function test_a_paid_result_is_cached_without_another_bakong_call(): void
    {
        $this->inner->paid = [
            'hash' => str_repeat('ab', 32),
            'fromAccountId' => 'payer@abaa',
            'toAccountId' => 'itc.events@abaa',
            'currency' => 'USD',
            'amount' => 0.01,
        ];

        $first = $this->gateway->findPaidTransaction('md5-paid');
        $this->travel(6)->seconds();
        $second = $this->gateway->findPaidTransaction('md5-paid');

        $this->assertSame($first, $second);
        $this->assertSame(1, $this->inner->calls);
    }

    public function test_daily_limit_stops_further_bakong_calls(): void
    {
        $this->gateway->findPaidTransaction('md5-1');
        $this->travel(6)->seconds();
        $this->gateway->findPaidTransaction('md5-2');
        $this->travel(6)->seconds();

        try {
            $this->gateway->findPaidTransaction('md5-3');
            $this->fail('Expected BAKONG_DAILY_LIMIT');
        } catch (ApiException $e) {
            $this->assertSame('BAKONG_DAILY_LIMIT', $e->errorCode);
            $this->assertSame(429, $e->httpStatus);
        }

        $this->assertSame(2, $this->inner->calls);
    }
}

class CountingBakongGateway implements BakongGateway
{
    public int $calls = 0;

    /** @var array<string, mixed>|null */
    public ?array $paid = null;

    public function findPaidTransaction(string $md5): ?array
    {
        $this->calls++;

        return $this->paid;
    }
}
