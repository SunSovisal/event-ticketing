<?php

namespace App\Contracts;

interface CoverStorage
{
    /**
     * @return array{url: string, public_id: string}
     */
    public function upload(string $absolutePath): array;

    public function destroy(string $publicId): void;
}
