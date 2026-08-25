<?php

namespace App\Services;

use App\Contracts\CoverStorage;
use App\Exceptions\ApiException;
use App\Models\Event;
use Illuminate\Http\UploadedFile;
use Throwable;

class EventCoverService
{
    public function __construct(
        private CoverStorage $storage,
    ) {}

    public function upload(string $eventId, UploadedFile $image): Event
    {
        $event = Event::query()->whereKey($eventId)->first();

        if ($event === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        $previousPublicId = $event->image_public_id;

        try {
            $uploaded = $this->storage->upload($image->getRealPath());
        } catch (ApiException $e) {
            throw $e;
        } catch (Throwable) {
            throw new ApiException(
                'COVER_UPLOAD_FAILED',
                'Could not upload the cover image.',
                502,
            );
        }

        $event->update([
            'image_url' => $uploaded['url'],
            'image_public_id' => $uploaded['public_id'],
        ]);

        if (is_string($previousPublicId) && $previousPublicId !== '') {
            try {
                $this->storage->destroy($previousPublicId);
            } catch (Throwable) {
                // New cover is already saved; orphaned previous asset is acceptable.
            }
        }

        return $event->refresh();
    }

    public function delete(string $eventId): Event
    {
        $event = Event::query()->whereKey($eventId)->first();

        if ($event === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        $publicId = $event->image_public_id;

        if (is_string($publicId) && $publicId !== '') {
            try {
                $this->storage->destroy($publicId);
            } catch (ApiException $e) {
                throw $e;
            } catch (Throwable) {
                throw new ApiException(
                    'COVER_UPLOAD_FAILED',
                    'Could not remove the cover image.',
                    502,
                );
            }
        }

        $event->update([
            'image_url' => null,
            'image_public_id' => null,
        ]);

        return $event->refresh();
    }
}
