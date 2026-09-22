<?php

namespace Tests\Unit;

use App\Exceptions\ApiException;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\UserNotFound;
use Mockery;
use Tests\TestCase;

class UserSyncFromFirebaseTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_preserves_inactive_status_for_existing_user(): void
    {
        $user = User::factory()->inactive()->create([
            'firebase_uid' => 'uid_inactive',
            'email' => 'inactive@example.com',
            'name' => 'Old Name',
        ]);

        $synced = User::syncFromFirebase(
            'uid_inactive',
            'inactive@example.com',
            'New Name',
            null,
        );

        $this->assertTrue($synced->is($user));
        $this->assertFalse($synced->is_active);
        $this->assertSame('Old Name', $synced->name);
        $this->assertSame('uid_inactive', $synced->firebase_uid);
    }

    public function test_unverified_email_does_not_claim_an_existing_account(): void
    {
        $admin = User::factory()->admin()->create([
            'firebase_uid' => 'pending-'.Str::uuid(),
            'email' => 'dean@itc.edu.kh',
        ]);

        try {
            User::syncFromFirebase('new-uid', 'dean@itc.edu.kh', 'Stranger', null, false);
            $this->fail('Unverified email should not sign in to an existing account.');
        } catch (ApiException $exception) {
            $this->assertSame('EMAIL_UNVERIFIED', $exception->errorCode);
            $this->assertSame(403, $exception->httpStatus);
        }

        $admin->refresh();
        $this->assertTrue($admin->is_admin);
        $this->assertTrue($admin->hasPlaceholderFirebaseUid());
        $this->assertNull(User::query()->where('firebase_uid', 'new-uid')->first());
    }

    public function test_admin_address_can_sign_in_without_email_verification(): void
    {
        $admin = User::factory()->admin()->create([
            'firebase_uid' => 'pending-'.Str::uuid(),
            'email' => 'admin@itc.edu.kh',
            'name' => 'ITC Admin',
        ]);

        $claimed = User::syncFromFirebase(
            'admin-uid',
            'admin@itc.edu.kh',
            'Firebase Name',
            null,
            false,
        );

        $this->assertTrue($claimed->is($admin));
        $this->assertTrue($claimed->is_admin);
        $this->assertSame('admin-uid', $claimed->firebase_uid);
        $this->assertSame('admin@itc.edu.kh', $claimed->email);
        $this->assertSame('ITC Admin', $claimed->name);
    }

    public function test_verified_email_claims_placeholder_admin_without_replacing_a_real_login(): void
    {
        $admin = User::factory()->admin()->create([
            'firebase_uid' => 'pending-'.Str::uuid(),
            'email' => 'admin@itc.edu.kh',
            'name' => 'ITC Admin',
        ]);

        $claimed = User::syncFromFirebase(
            'real-admin-uid',
            'Admin@itc.edu.kh',
            'Firebase Name',
            null,
            true,
        );

        $this->assertTrue($claimed->is($admin));
        $this->assertTrue($claimed->is_admin);
        $this->assertSame('real-admin-uid', $claimed->firebase_uid);
        $this->assertSame('ITC Admin', $claimed->name);

        $student = User::factory()->create([
            'firebase_uid' => 'student-uid',
            'email' => 'student@itc.edu.kh',
        ]);

        $auth = Mockery::mock(FirebaseAuth::class);
        $auth->shouldReceive('getUser')->once()->with('student-uid')->andReturn(new \stdClass);
        $this->app->instance(FirebaseAuth::class, $auth);

        try {
            User::syncFromFirebase('other-uid', 'student@itc.edu.kh', 'Other', null, true);
            $this->fail('A verified email must not take over an account that already has a login.');
        } catch (ApiException $exception) {
            $this->assertSame('EMAIL_TAKEN', $exception->errorCode);
        }

        $this->assertSame('student-uid', $student->fresh()->firebase_uid);
    }

    public function test_verified_email_claims_a_row_whose_firebase_login_was_deleted(): void
    {
        $user = User::factory()->create([
            'firebase_uid' => 'deleted-uid',
            'email' => 'fresh@itc.edu.kh',
            'name' => 'Fresh',
        ]);

        $auth = Mockery::mock(FirebaseAuth::class);
        $auth->shouldReceive('getUser')->once()->with('deleted-uid')->andThrow(new UserNotFound);
        $this->app->instance(FirebaseAuth::class, $auth);

        $claimed = User::syncFromFirebase('new-uid', 'fresh@itc.edu.kh', 'Ignored', null, true);

        $this->assertTrue($claimed->is($user));
        $this->assertSame('new-uid', $claimed->firebase_uid);
        $this->assertSame('Fresh', $claimed->name);
        $this->assertSame('fresh@itc.edu.kh', $claimed->email);
    }

    public function test_new_unverified_login_stores_no_email(): void
    {
        $user = User::syncFromFirebase('fresh-uid', 'fresh@itc.edu.kh', 'Fresh', null, false);

        $this->assertSame('fresh-uid', $user->firebase_uid);
        $this->assertNull($user->email);
        $this->assertFalse($user->is_admin);
    }
}
