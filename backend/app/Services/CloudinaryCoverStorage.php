<?php

namespace App\Services;

use App\Contracts\CoverStorage;
use App\Exceptions\ApiException;
use Cloudinary\Cloudinary;
use Cloudinary\Configuration\Configuration;
use Throwable;

class CloudinaryCoverStorage implements CoverStorage
{
    private const FOLDER = 'itc-events/covers';

    private ?Cloudinary $cloudinary;

    public function __construct(?Cloudinary $cloudinary = null)
    {
        $this->cloudinary = $cloudinary;
    }

    public function upload(string $absolutePath): array
    {
        try {
            $result = $this->client()->uploadApi()->upload($absolutePath, [
                'folder' => self::FOLDER,
                'resource_type' => 'image',
            ]);
        } catch (ApiException $e) {
            throw $e;
        } catch (Throwable) {
            throw new ApiException(
                'COVER_UPLOAD_FAILED',
                'Could not upload the cover image.',
                502,
            );
        }

        $url = $result['secure_url'] ?? null;
        $publicId = $result['public_id'] ?? null;

        if (! is_string($url) || $url === '' || ! is_string($publicId) || $publicId === '') {
            throw new ApiException(
                'COVER_UPLOAD_FAILED',
                'Could not upload the cover image.',
                502,
            );
        }

        return [
            'url' => $url,
            'public_id' => $publicId,
        ];
    }

    public function destroy(string $publicId): void
    {
        try {
            $this->client()->uploadApi()->destroy($publicId, [
                'resource_type' => 'image',
            ]);
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

    private function client(): Cloudinary
    {
        if ($this->cloudinary !== null) {
            return $this->cloudinary;
        }

        $cloudName = config('services.cloudinary.cloud_name');
        $apiKey = config('services.cloudinary.api_key');
        $apiSecret = config('services.cloudinary.api_secret');

        if (! is_string($cloudName) || $cloudName === ''
            || ! is_string($apiKey) || $apiKey === ''
            || ! is_string($apiSecret) || $apiSecret === '') {
            throw new ApiException(
                'COVER_UPLOAD_FAILED',
                'Cloudinary is not configured.',
                502,
            );
        }

        $this->cloudinary = new Cloudinary(
            Configuration::instance([
                'cloud' => [
                    'cloud_name' => $cloudName,
                    'api_key' => $apiKey,
                    'api_secret' => $apiSecret,
                ],
                'url' => [
                    'secure' => true,
                ],
            ]),
        );

        return $this->cloudinary;
    }
}
