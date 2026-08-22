<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('auth_user');
        $user->loadMissing('profile');

        return response()->json([
            'data' => $user->toProfile(),
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'email' => ['sometimes', 'email', 'max:255'],
            'student_id' => ['sometimes', 'nullable', 'string', 'max:32'],
            'department' => ['sometimes', 'nullable', 'string', 'max:80'],
            'year' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:8'],
        ]);

        /** @var User $user */
        $user = $request->attributes->get('auth_user');

        $userUpdates = [];
        if (array_key_exists('name', $validated)) {
            $userUpdates['name'] = trim($validated['name']);
        }
        if (array_key_exists('email', $validated)) {
            $userUpdates['email'] = trim($validated['email']);
        }
        if ($userUpdates !== []) {
            $user->update($userUpdates);
        }

        $campus = $this->campusPayload($request, $validated);
        if ($campus !== [] && $this->studentIdTaken($user, $campus['student_id'] ?? null, array_key_exists('student_id', $campus))) {
            return $this->jsonError(
                'STUDENT_ID_TAKEN',
                'Student ID already used.',
                409,
            );
        }

        $user->syncCampusProfile($campus);

        return response()->json([
            'data' => $user->fresh()->load('profile')->toProfile(),
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    /**
     * @param  array<string, mixed>  $validated
     * @return array{student_id?: ?string, department?: ?string, year?: ?int}
     */
    private function campusPayload(Request $request, array $validated): array
    {
        $campus = [];

        if ($request->exists('student_id')) {
            $campus['student_id'] = $this->nullableString($validated['student_id'] ?? null);
        }
        if ($request->exists('department')) {
            $campus['department'] = $this->nullableString($validated['department'] ?? null);
        }
        if ($request->exists('year')) {
            $year = $validated['year'] ?? null;
            $campus['year'] = $year === null ? null : (int) $year;
        }

        return $campus;
    }

    private function studentIdTaken(User $user, ?string $studentId, bool $studentIdProvided): bool
    {
        if (! $studentIdProvided || $studentId === null) {
            return false;
        }

        return UserProfile::query()
            ->where('student_id', $studentId)
            ->where('user_id', '!=', $user->id)
            ->exists();
    }

    private function nullableString(mixed $value): ?string
    {
        if (! is_string($value)) {
            return null;
        }

        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }
}
