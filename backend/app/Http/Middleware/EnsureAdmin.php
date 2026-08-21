<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->attributes->get('auth_user');

        if (! $user instanceof User || ! $user->is_admin) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'Admin access required.',
                    'fields' => new \stdClass,
                ],
                'meta' => [
                    'request_id' => (string) str()->uuid(),
                ],
            ], 403);
        }

        return $next($request);
    }
}
