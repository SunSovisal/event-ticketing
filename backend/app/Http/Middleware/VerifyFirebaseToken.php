<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Symfony\Component\HttpFoundation\Response;

class VerifyFirebaseToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization', '');
        if (! str_starts_with($header, 'Bearer ')) {
            return $this->errorResponse(
                'UNAUTHORIZED',
                'Missing bearer token.',
                401,
            );
        }

        $token = trim(substr($header, 7));
        if ($token === '') {
            return $this->errorResponse(
                'UNAUTHORIZED',
                'Missing bearer token.',
                401,
            );
        }

        try {
            $claims = app(FirebaseAuth::class)->verifyIdToken($token)->claims();
            $firebaseUid = (string) $claims->get('sub');

            if ($firebaseUid === '') {
                return $this->errorResponse(
                    'UNAUTHORIZED',
                    'Invalid or expired token.',
                    401,
                );
            }

            $user = User::syncFromFirebase(
                $firebaseUid,
                $this->optionalClaim($claims->get('email')),
                $this->optionalClaim($claims->get('name')),
                $this->optionalClaim($claims->get('phone_number')),
            );

            if (! $user->is_active) {
                return $this->errorResponse(
                    'FORBIDDEN',
                    'This account has been deactivated.',
                    403,
                );
            }

            $request->attributes->set('auth_user', $user);
        } catch (FailedToVerifyToken) {
            return $this->errorResponse(
                'UNAUTHORIZED',
                'Invalid or expired token.',
                401,
            );
        } catch (\Throwable $exception) {
            report($exception);

            return $this->errorResponse(
                'SERVER_ERROR',
                'Could not verify Firebase token.',
                500,
            );
        }

        return $next($request);
    }

    private function optionalClaim(mixed $value): ?string
    {
        if (! is_string($value) || $value === '') {
            return null;
        }

        return $value;
    }

    private function errorResponse(string $code, string $message, int $status): Response
    {
        return response()->json([
            'error' => [
                'code' => $code,
                'message' => $message,
                'fields' => new \stdClass,
            ],
            'meta' => ['request_id' => (string) str()->uuid()],
        ], $status);
    }
}
