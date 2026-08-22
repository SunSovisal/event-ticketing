<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

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

    public function tickets(): HasMany
    {
        return $this->hasMany(Ticket::class);
    }

    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    /**
     * Create or update campus fields. A missing profile is created only when
     * at least one campus value is non-null.
     *
     * @param  array{student_id?: ?string, department?: ?string, year?: ?int}  $campus
     */
    public function syncCampusProfile(array $campus): void
    {
        if ($campus === []) {
            return;
        }

        $allNull = collect($campus)->every(fn (mixed $value) => $value === null);
        $profile = $this->profile;

        if ($profile === null && $allNull) {
            return;
        }

        $this->profile()->updateOrCreate(
            ['user_id' => $this->id],
            $campus,
        );
    }

    protected function casts(): array
    {
        return [
            'is_admin' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return array{id: string, firebase_uid: string, email: ?string, phone_number: ?string, name: ?string, is_admin: bool, is_active: bool, student_id: ?string, department: ?string, year: ?int}
     */
    public function toProfile(): array
    {
        $profile = $this->profile;

        return [
            'id' => $this->id,
            'firebase_uid' => $this->firebase_uid,
            'email' => $this->email,
            'phone_number' => $this->phone_number,
            'name' => $this->name,
            'is_admin' => $this->is_admin,
            'is_active' => $this->is_active,
            'student_id' => $profile?->student_id,
            'department' => $profile?->department,
            'year' => $profile?->year,
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
