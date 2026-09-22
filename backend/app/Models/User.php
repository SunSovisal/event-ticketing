<?php

namespace App\Models;

use App\Exceptions\ApiException;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\UserNotFound;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class User extends Model
{
    use HasFactory, HasUuids;

    /**
     * Campus admin login. This inbox is not real, so Firebase cannot verify it.
     */
    public const TRUSTED_UNVERIFIED_EMAIL = 'admin@itc.edu.kh';

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

    public function savedEvents(): HasMany
    {
        return $this->hasMany(SavedEvent::class);
    }

    public function notificationReads(): HasMany
    {
        return $this->hasMany(NotificationRead::class);
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

    /**
     * Seeded accounts use this prefix until a verified Firebase login claims them.
     */
    public function hasPlaceholderFirebaseUid(): bool
    {
        return str_starts_with($this->firebase_uid, 'pending-');
    }

    public static function sameEmail(?string $left, ?string $right): bool
    {
        $left = self::canonicalEmail($left);
        $right = self::canonicalEmail($right);

        return $left !== null && $left === $right;
    }

    public static function syncFromFirebase(
        string $firebaseUid,
        ?string $email,
        ?string $name,
        ?string $phone,
        bool $emailVerified = false,
    ): self {
        $email = self::canonicalEmail($email);
        if ($email === self::TRUSTED_UNVERIFIED_EMAIL) {
            $emailVerified = true;
        }

        return DB::transaction(function () use ($firebaseUid, $email, $name, $phone, $emailVerified) {
            $user = static::query()->where('firebase_uid', $firebaseUid)->lockForUpdate()->first();

            if ($user) {
                $user->update(self::profileUpdates($user, $firebaseUid, $email, $emailVerified, $name, $phone));

                return $user;
            }

            if ($email !== null && ! $emailVerified) {
                $existing = static::query()->whereRaw('lower(email) = ?', [$email])->lockForUpdate()->first();
                if ($existing !== null) {
                    throw new ApiException(
                        'EMAIL_UNVERIFIED',
                        'Verify this email before signing in.',
                        403,
                    );
                }
            }

            if ($email !== null && $emailVerified) {
                $existing = static::query()->whereRaw('lower(email) = ?', [$email])->lockForUpdate()->first();
                if ($existing !== null) {
                    $canClaim = $existing->hasPlaceholderFirebaseUid()
                        || ! self::firebaseUidExists($existing->firebase_uid);

                    if (! $canClaim) {
                        throw new ApiException(
                            'EMAIL_TAKEN',
                            'This email is already used by another account.',
                            409,
                        );
                    }

                    $existing->update(self::profileUpdates(
                        $existing,
                        $firebaseUid,
                        $email,
                        true,
                        $name,
                        $phone,
                        true,
                    ));

                    return $existing;
                }
            }

            return static::query()->create([
                'firebase_uid' => $firebaseUid,
                'email' => $emailVerified ? $email : null,
                'name' => $name,
                'phone_number' => $phone,
                'is_admin' => false,
                'is_active' => true,
            ]);
        });
    }

    /**
     * @return array{firebase_uid?: string, email?: ?string, name: ?string, phone_number: ?string}
     */
    private static function profileUpdates(
        self $user,
        string $firebaseUid,
        ?string $email,
        bool $emailVerified,
        ?string $name,
        ?string $phone,
        bool $claimUid = false,
    ): array {
        $updates = [
            'name' => $user->name ?? $name,
            'phone_number' => $phone ?? $user->phone_number,
        ];

        if ($claimUid || $user->hasPlaceholderFirebaseUid()) {
            $updates['firebase_uid'] = $firebaseUid;
        }

        if ($emailVerified && $email !== null && self::emailAvailable($email, $user)) {
            $updates['email'] = $email;
        }

        return $updates;
    }

    private static function canonicalEmail(?string $email): ?string
    {
        if (! is_string($email)) {
            return null;
        }

        $email = Str::lower(trim($email));

        return $email === '' ? null : $email;
    }

    private static function firebaseUidExists(string $uid): bool
    {
        try {
            app(FirebaseAuth::class)->getUser($uid);

            return true;
        } catch (UserNotFound) {
            return false;
        } catch (\Throwable) {
            return true;
        }
    }

    private static function emailAvailable(string $email, self $except): bool
    {
        return ! static::query()
            ->whereRaw('lower(email) = ?', [$email])
            ->whereKeyNot($except->id)
            ->exists();
    }
}
