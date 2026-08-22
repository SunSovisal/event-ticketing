<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserProfile;
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
            ->assertJsonPath('data.is_admin', true)
            ->assertJsonPath('data.student_id', null)
            ->assertJsonPath('data.department', null)
            ->assertJsonPath('data.year', null);
    }

    public function test_patch_me_creates_campus_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Dara',
            'email' => 'dara@student.itc.edu.kh',
        ]);

        $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'student_id' => 'e20240001',
                'department' => 'GIC',
                'year' => 3,
            ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Dara')
            ->assertJsonPath('data.student_id', 'e20240001')
            ->assertJsonPath('data.department', 'GIC')
            ->assertJsonPath('data.year', 3);

        $this->assertDatabaseHas('user_profiles', [
            'user_id' => $user->id,
            'student_id' => 'e20240001',
            'department' => 'GIC',
            'year' => 3,
        ]);
    }

    public function test_patch_me_omitted_campus_fields_are_unchanged(): void
    {
        $user = User::factory()->create();
        UserProfile::factory()->create([
            'user_id' => $user->id,
            'student_id' => 'e20240001',
            'department' => 'GIC',
            'year' => 2,
        ]);

        $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'name' => 'Updated Name',
            ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Name')
            ->assertJsonPath('data.student_id', 'e20240001')
            ->assertJsonPath('data.department', 'GIC')
            ->assertJsonPath('data.year', 2);
    }

    public function test_patch_me_rejects_duplicate_student_id(): void
    {
        $owner = User::factory()->create();
        UserProfile::factory()->create([
            'user_id' => $owner->id,
            'student_id' => 'e20240001',
        ]);

        $other = User::factory()->create();

        $this->actingAsFirebaseUser($other)
            ->patchJson('/api/v1/me', [
                'student_id' => 'e20240001',
            ])
            ->assertConflict()
            ->assertJsonPath('error.code', 'STUDENT_ID_TAKEN')
            ->assertJsonPath('error.message', 'Student ID already used.');

        $this->assertDatabaseMissing('user_profiles', [
            'user_id' => $other->id,
        ]);
    }

    public function test_patch_me_allows_keeping_own_student_id(): void
    {
        $user = User::factory()->create();
        UserProfile::factory()->create([
            'user_id' => $user->id,
            'student_id' => 'e20240001',
            'department' => 'GEE',
            'year' => 1,
        ]);

        $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'student_id' => 'e20240001',
                'department' => 'GIC',
            ])
            ->assertOk()
            ->assertJsonPath('data.student_id', 'e20240001')
            ->assertJsonPath('data.department', 'GIC')
            ->assertJsonPath('data.year', 1);
    }

    public function test_patch_me_does_not_create_empty_profile(): void
    {
        $user = User::factory()->create();

        $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'student_id' => '',
                'department' => null,
                'year' => null,
            ])
            ->assertOk()
            ->assertJsonPath('data.student_id', null);

        $this->assertDatabaseMissing('user_profiles', [
            'user_id' => $user->id,
        ]);
    }

    public function test_patch_me_rejects_invalid_year(): void
    {
        $user = User::factory()->create();

        $this->actingAsFirebaseUser($user)
            ->patchJson('/api/v1/me', [
                'year' => 9,
            ])
            ->assertUnprocessable();
    }
}
