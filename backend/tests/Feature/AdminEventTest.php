<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminEventTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_events_require_a_bearer_token(): void
    {
        $this->getJson('/api/v1/admin/events')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHORIZED');
    }

    public function test_non_admin_cannot_list_admin_events(): void
    {
        $attendee = User::factory()->create([
            'firebase_uid' => 'uid_attendee',
        ]);

        $this->actingAsFirebaseUser($attendee)
            ->getJson('/api/v1/admin/events')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_admin_can_list_events_of_any_status(): void
    {
        $admin = User::factory()->admin()->create([
            'firebase_uid' => 'uid_admin',
        ]);
        Event::factory()->published()->create(['title' => 'Published talk']);
        Event::factory()->create(['title' => 'Draft workshop']);
        Event::factory()->cancelled()->create(['title' => 'Cancelled meetup']);

        $response = $this->actingAsFirebaseUser($admin)
            ->getJson('/api/v1/admin/events')
            ->assertOk();

        $titles = collect($response->json('data'))->pluck('title');
        $this->assertEqualsCanonicalizing(
            ['Published talk', 'Draft workshop', 'Cancelled meetup'],
            $titles->all(),
        );
        $this->assertSame(0, $response->json('data.0.reserved_count'));
        $this->assertSame(0, $response->json('data.0.checked_in_count'));
        $this->assertArrayNotHasKey('image_public_id', $response->json('data.0'));
    }
}
