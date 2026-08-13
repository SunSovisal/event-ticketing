<?php

namespace Tests\Feature;

use Tests\TestCase;

class MeTest extends TestCase
{
    public function test_me_requires_a_bearer_token(): void
    {
        $this->getJson('/api/v1/me')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED')
            ->assertJsonPath('error.message', 'Missing bearer token.');
    }
}
