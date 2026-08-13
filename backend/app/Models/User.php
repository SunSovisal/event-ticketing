<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'firebase_uid',
        'email',
        'phone_number',
        'name',
        'is_admin',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_admin' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return array{id: string, firebase_uid: string, email: ?string, phone_number: ?string, name: ?string, is_admin: bool, is_active: bool}
     */
    public function toProfile(): array
    {
        return [
            'id' => $this->id,
            'firebase_uid' => $this->firebase_uid,
            'email' => $this->email,
            'phone_number' => $this->phone_number,
            'name' => $this->name,
            'is_admin' => $this->is_admin,
            'is_active' => $this->is_active,
        ];
    }

    public static function syncFromFirebase(
        string $firebaseUid,
        ?string $email,
        ?string $name,
        ?string $phone,
    ): self {
        $user = static::query()->where('firebase_uid', $firebaseUid)->first();

        if (! $user && $email) {
            $user = static::query()->where('email', $email)->first();
        }

        if ($user) {
            $user->update([
                'firebase_uid' => $firebaseUid,
                'email' => $email ?? $user->email,
                'name' => $user->name ?? $name,
                'phone_number' => $phone ?? $user->phone_number,
            ]);

            return $user;
        }

        return static::query()->create([
            'firebase_uid' => $firebaseUid,
            'email' => $email,
            'name' => $name,
            'phone_number' => $phone,
            'is_admin' => false,
            'is_active' => true,
        ]);
    }
}
