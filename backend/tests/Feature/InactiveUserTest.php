<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Lcobucci\JWT\Token\DataSet;
use Lcobucci\JWT\UnencryptedToken;
use Mockery;
use Tests\TestCase;

class InactiveUserTest extends TestCase
{
    use RefreshDatabase;

    public function test_inactive_user_cannot_access_me(): void
    {
        User::factory()->inactive()->create([
            'firebase_uid' => 'uid_inactive',
            'email' => 'inactive@example.com',
        ]);

        $claims = new DataSet([
            'sub' => 'uid_inactive',
            'email' => 'inactive@example.com',
            'name' => 'Inactive User',
        ], '{}');

        $verifiedToken = Mockery::mock(UnencryptedToken::class);
        $verifiedToken->shouldReceive('claims')->andReturn($claims);

        $this->mock(FirebaseAuth::class, function ($mock) use ($verifiedToken) {
            $mock->shouldReceive('verifyIdToken')
                ->with('valid-token')
                ->andReturn($verifiedToken);
        });

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->getJson('/api/v1/me')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN')
            ->assertJsonPath('error.message', 'This account has been deactivated.');
    }
}
