<?php

namespace Tests\Feature;

use App\Contracts\CoverStorage;
use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class EventCoverTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->app->instance(CoverStorage::class, new class implements CoverStorage
        {
            /** @var list<string> */
            public array $destroyed = [];

            public int $uploads = 0;

            public function upload(string $absolutePath): array
            {
                $this->uploads++;

                return [
                    'url' => 'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/cover-'.$this->uploads.'.jpg',
                    'public_id' => 'itc-events/covers/cover-'.$this->uploads,
                ];
            }

            public function destroy(string $publicId): void
            {
                $this->destroyed[] = $publicId;
            }
        });
    }

    public function test_admin_can_upload_a_cover(): void
    {
        Storage::fake('local');
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create();

        $response = $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [
                'image' => UploadedFile::fake()->image('cover.jpg', 800, 450),
            ])
            ->assertOk()
            ->assertJsonPath(
                'data.image_url',
                'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/cover-1.jpg',
            );

        $this->assertArrayNotHasKey('image_public_id', $response->json('data'));
        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'image_url' => 'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/cover-1.jpg',
            'image_public_id' => 'itc-events/covers/cover-1',
        ]);
    }

    public function test_replacing_a_cover_deletes_the_previous_asset(): void
    {
        Storage::fake('local');
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'image_url' => 'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/old.jpg',
            'image_public_id' => 'itc-events/covers/old',
        ]);

        $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [
                'image' => UploadedFile::fake()->image('cover.png'),
            ])
            ->assertOk()
            ->assertJsonPath(
                'data.image_url',
                'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/cover-1.jpg',
            );

        /** @var object{destroyed: list<string>} $storage */
        $storage = $this->app->make(CoverStorage::class);
        $this->assertSame(['itc-events/covers/old'], $storage->destroyed);
        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'image_public_id' => 'itc-events/covers/cover-1',
        ]);
    }

    public function test_admin_can_delete_a_cover(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'image_url' => 'https://res.cloudinary.com/demo/image/upload/v1/itc-events/covers/cover-1.jpg',
            'image_public_id' => 'itc-events/covers/cover-1',
        ]);

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$event->id.'/cover')
            ->assertOk()
            ->assertJsonPath('data.image_url', null);

        /** @var object{destroyed: list<string>} $storage */
        $storage = $this->app->make(CoverStorage::class);
        $this->assertSame(['itc-events/covers/cover-1'], $storage->destroyed);
        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'image_url' => null,
            'image_public_id' => null,
        ]);
    }

    public function test_delete_cover_is_idempotent_when_none_exists(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'image_url' => null,
            'image_public_id' => null,
        ]);

        $this->actingAsFirebaseUser($admin)
            ->deleteJson('/api/v1/admin/events/'.$event->id.'/cover')
            ->assertOk()
            ->assertJsonPath('data.image_url', null);
    }

    public function test_non_admin_cannot_upload_a_cover(): void
    {
        Storage::fake('local');
        $attendee = User::factory()->create();
        $event = Event::factory()->create();

        $this->actingAsFirebaseUser($attendee)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [
                'image' => UploadedFile::fake()->image('cover.jpg'),
            ])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_upload_rejects_missing_image(): void
    {
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create();

        $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [])
            ->assertUnprocessable();
    }

    public function test_upload_rejects_unsupported_type(): void
    {
        Storage::fake('local');
        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create();

        $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [
                'image' => UploadedFile::fake()->create('notes.pdf', 100, 'application/pdf'),
            ])
            ->assertUnprocessable();
    }

    public function test_upload_returns_502_when_cloudinary_fails(): void
    {
        Storage::fake('local');
        $this->app->instance(CoverStorage::class, new class implements CoverStorage
        {
            public function upload(string $absolutePath): array
            {
                throw new ApiException(
                    'COVER_UPLOAD_FAILED',
                    'Could not upload the cover image.',
                    502,
                );
            }

            public function destroy(string $publicId): void {}
        });

        $admin = User::factory()->admin()->create();
        $event = Event::factory()->create([
            'image_url' => null,
            'image_public_id' => null,
        ]);

        $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/'.$event->id.'/cover', [
                'image' => UploadedFile::fake()->image('cover.jpg'),
            ])
            ->assertStatus(502)
            ->assertJsonPath('error.code', 'COVER_UPLOAD_FAILED');

        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'image_url' => null,
            'image_public_id' => null,
        ]);
    }

    public function test_upload_unknown_event_returns_404(): void
    {
        Storage::fake('local');
        $admin = User::factory()->admin()->create();

        $this->actingAsFirebaseUser($admin)
            ->post('/api/v1/admin/events/00000000-0000-0000-0000-000000000000/cover', [
                'image' => UploadedFile::fake()->image('cover.jpg'),
            ])
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }
}
