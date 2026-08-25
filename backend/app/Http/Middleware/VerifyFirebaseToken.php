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
    public function handle(Request $request, Closure $next, ?string $mode = null): Response
    {
        $optional = $mode === 'optional';
        $header = $request->header('Authorization', '');
        if (! str_starts_with($header, 'Bearer ')) {
            if ($optional) {
                return $next($request);
            }

            return $this->errorResponse(
                'UNAUTHORIZED',
                'Missing bearer token.',
                401,
            );
        }

        $token = trim(substr($header, 7));
        if ($token === '') {
            if ($optional) {
                return $next($request);
            }

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
        } catch (FailedToVerifyToken $exception) {
            report($exception);

            $message = 'Invalid or expired token.';
            if (config('app.debug')) {
                $message .= ' Debug: '.$exception->getMessage();
                $message .= '. '.$this->debugTokenContext($token);
            }

            return $this->errorResponse(
                'UNAUTHORIZED',
                $message,
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

    private function debugTokenContext(string $token): string
    {
        $parts = explode('.', $token);
        if (count($parts) < 2) {
            return 'Token format invalid.';
        }

        $payloadJson = base64_decode(strtr($parts[1], '-_', '+/'), true);
        $payload = is_string($payloadJson) ? json_decode($payloadJson, true) : null;

        $aud = is_array($payload) ? ($payload['aud'] ?? 'missing') : 'unreadable';
        $iss = is_array($payload) ? ($payload['iss'] ?? 'missing') : 'unreadable';

        $backendProject = 'unknown';
        $credentialsPath = config('firebase.projects.app.credentials');
        if (is_string($credentialsPath) && is_readable($credentialsPath)) {
            $credentials = json_decode((string) file_get_contents($credentialsPath), true);
            if (is_array($credentials)) {
                $backendProject = $credentials['project_id'] ?? 'missing';
            }
        }

        return "Token aud={$aud}, iss={$iss}; backend project_id={$backendProject}";
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
