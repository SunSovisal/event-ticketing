<?php

namespace Tests\Support;

use Illuminate\Testing\TestResponse;

/**
 * Budgets one in-process HTTP kernel call.
 *
 * `$this->getJson()` / `postJson()` drive routing, middleware, the controller,
 * and JSON encoding inside the test process. They do not open a socket, so the
 * sample is a regression ceiling for application work, not a production SLO.
 * Time is taken with hrtime(), which is monotonic and is not moved by NTP.
 */
trait AssertsApiLatency
{
    /**
     * @param  callable(): TestResponse  $request
     */
    protected function assertApiWithin(int $budgetMs, callable $request): TestResponse
    {
        $started = hrtime(true);
        $response = $request();
        $elapsedMs = (hrtime(true) - $started) / 1_000_000;

        $this->assertLessThanOrEqual(
            $budgetMs,
            $elapsedMs,
            sprintf('Response exceeded the %d ms budget (%.2f ms).', $budgetMs, $elapsedMs),
        );

        return $response;
    }
}
