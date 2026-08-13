<?php

namespace Tests\Unit;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
    }
}
