<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Services\AdminKpiService;
use App\Support\KpiRange;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminKpiController extends Controller
{
    public function __construct(private AdminKpiService $kpis) {}

    public function index(Request $request): JsonResponse
    {
        $range = KpiRange::parse($request->query('range'));

        return response()->json([
            'data' => $this->kpis->overview($range),
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $range = KpiRange::parse($request->query('range'));
        $data = $this->kpis->forEvent($id, $range);

        if ($data === null) {
            throw new ApiException('NOT_FOUND', 'Event not found.', 404);
        }

        return response()->json([
            'data' => $data,
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }
}
