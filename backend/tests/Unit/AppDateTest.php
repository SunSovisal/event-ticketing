<?php

namespace Tests\Unit;

use App\Support\AppDate;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class AppDateTest extends TestCase
{
    public function test_iso_formats_in_phnom_penh(): void
    {
        $value = Carbon::parse('2026-09-13 09:34:00', 'UTC');

        $this->assertSame('2026-09-13T16:34:00+07:00', AppDate::iso($value));
        $this->assertNull(AppDate::iso(null));
    }
}
