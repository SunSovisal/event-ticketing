<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Lcobucci\JWT\Token\DataSet;
use Lcobucci\JWT\UnencryptedToken;
use Mockery;
use Tests\TestCase;

class MeTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_me_requires_a_bearer_token(): void
    {
        $this->getJson('/api/v1/me')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED')
            ->assertJsonPath('error.message', 'Missing bearer token.');
    }

    public function test_verified_admin_token_returns_database_profile(): void
    {
        User::factory()->create([
            'firebase_uid' => 'uid_admin',
            'email' => 'admin@itc.edu.kh',
            'name' => 'ITC Admin',
            'is_admin' => true,
        ]);

        $claims = new DataSet([
            'sub' => 'uid_admin',
            'email' => 'admin@itc.edu.kh',
            'name' => 'Google Name',
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
            ->assertOk()
            ->assertJsonPath('data.name', 'ITC Admin')
            ->assertJsonPath('data.is_admin', true);
    }
}
