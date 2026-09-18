<?php

namespace App\Services;

use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\EventView;
use App\Models\Payment;
use App\Models\SavedEvent;
use App\Models\Ticket;
use App\Support\AppDate;
use App\Support\KpiRange;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AdminKpiService
{
    /**
     * @return array<string, mixed>
     */
    public function overview(KpiRange $range): array
    {
        $tickets = $this->reservedTicketCount($range->from, $range->to);
        $previousTickets = $range->previousFrom === null
            ? $tickets
            : $this->reservedTicketCount($range->previousFrom, $range->previousTo);

        $fill = $this->fillRates($range->from, $range->to);
        $previousFill = $range->previousFrom === null
            ? $fill
            : $this->fillRates($range->previousFrom, $range->previousTo);

        $revenue = $this->paidRevenue($range->from, $range->to);
        $previousRevenue = $range->previousFrom === null
            ? $revenue
            : $this->paidRevenue($range->previousFrom, $range->previousTo);

        return [
            ...$range->toMeta(),
            'overview' => [
                'tickets' => $this->countMetric($tickets, $previousTickets),
                'fill_rate' => $this->rateMetric($fill['rate'], $previousFill['rate']),
                'check_in_rate' => $this->rateMetric($fill['check_in_rate'], $previousFill['check_in_rate']),
                'revenue' => [
                    'usd' => $revenue['USD'],
                    'khr' => $revenue['KHR'],
                    'previous_usd' => $previousRevenue['USD'],
                    'previous_khr' => $previousRevenue['KHR'],
                    'delta_pct' => $this->pctChange($revenue['USD'], $previousRevenue['USD']),
                ],
            ],
            'series' => [
                'tickets_by_day' => $this->countByDay(
                    Ticket::query()->whereIn('status', ['valid', 'checked_in']),
                    'created_at',
                    $range,
                ),
                'check_ins_by_day' => $this->countByDay(
                    Ticket::query()->where('status', 'checked_in')->whereNotNull('checked_in_at'),
                    'checked_in_at',
                    $range,
                ),
            ],
            'breakdowns' => [
                'tickets_by_category' => $this->ticketsByCategory($range->from, $range->to),
                'payments_by_method' => $this->paymentsByMethod($range->from, $range->to),
            ],
            'top_events' => $this->topEvents($range->from, $range->to),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    public function forEvent(string $eventId, KpiRange $range): ?array
    {
        $event = Event::query()->withTicketCounts()->whereKey($eventId)->first();

        if ($event === null) {
            return null;
        }

        $reserved = (int) ($event->reserved_count ?? 0);
        $checkedIn = (int) ($event->checked_in_count ?? 0);
        $capacity = max(1, (int) $event->capacity);
        $fillRate = $reserved / $capacity;
        $checkInRate = $reserved > 0 ? $checkedIn / $reserved : 0.0;
        $noShow = max(0, $reserved - $checkedIn);

        $revenue = $this->paidRevenue($range->from, $range->to, $event->id);

        return [
            ...$range->toMeta(),
            'event' => [
                'id' => $event->id,
                'title' => $event->title,
                'category' => $event->category,
                'location_label' => $event->location_label,
                'capacity' => (int) $event->capacity,
                'starts_at' => AppDate::iso($event->starts_at),
            ],
            'overview' => [
                'fill_rate' => round($fillRate, 4),
                'reserved_count' => $reserved,
                'check_in_rate' => round($checkInRate, 4),
                'checked_in_count' => $checkedIn,
                'no_show_rate' => round($reserved > 0 ? $noShow / $reserved : 0.0, 4),
                'no_show_count' => $noShow,
                'revenue_usd' => $revenue['USD'],
                'revenue_khr' => $revenue['KHR'],
            ],
            'funnel' => $this->eventFunnel($event, $range),
            'check_ins_by_hour' => $this->checkInsByHour($event),
            'attendees_by_department' => $this->attendeesByDepartment($event->id),
            'scan_results' => $this->scanResults($event->id, $range->from, $range->to),
        ];
    }

    private function reservedTicketCount(?Carbon $from, ?Carbon $to): int
    {
        if ($from === null && $to === null) {
            return 0;
        }

        $query = Ticket::query()->whereIn('status', ['valid', 'checked_in']);
        $this->constrain($query, 'created_at', $from, $to);

        return $query->count();
    }

    /**
     * @return array{rate: float, check_in_rate: float}
     */
    private function fillRates(?Carbon $from, ?Carbon $to): array
    {
        if ($from === null && $to === null) {
            return ['rate' => 0.0, 'check_in_rate' => 0.0];
        }

        $query = Event::query()->withTicketCounts();
        $this->constrain($query, 'starts_at', $from, $to);
        $events = $query->get();

        $capacity = (int) $events->sum('capacity');
        $reserved = (int) $events->sum(fn (Event $event) => (int) ($event->reserved_count ?? 0));
        $checkedIn = (int) $events->sum(fn (Event $event) => (int) ($event->checked_in_count ?? 0));

        return [
            'rate' => $capacity > 0 ? $reserved / $capacity : 0.0,
            'check_in_rate' => $reserved > 0 ? $checkedIn / $reserved : 0.0,
        ];
    }

    /**
     * @return array{USD: float, KHR: float}
     */
    private function paidRevenue(?Carbon $from, ?Carbon $to, ?string $eventId = null): array
    {
        $totals = ['USD' => 0.0, 'KHR' => 0.0];

        if ($from === null && $to === null) {
            return $totals;
        }

        $query = Payment::query()->where('status', 'paid');
        $this->constrain($query, 'paid_at', $from, $to);

        if ($eventId !== null) {
            $query->where('event_id', $eventId);
        }

        $query
            ->select('currency', DB::raw('sum(amount) as total'))
            ->groupBy('currency')
            ->get()
            ->each(function ($row) use (&$totals): void {
                $currency = strtoupper((string) $row->currency);
                if (array_key_exists($currency, $totals)) {
                    $totals[$currency] = round((float) $row->total, 2);
                }
            });

        return $totals;
    }

    /**
     * @param  Builder<Ticket>  $query
     * @return list<array{date: string, count: int}>
     */
    private function countByDay(Builder $query, string $column, KpiRange $range): array
    {
        $from = $range->seriesFrom();
        $to = $range->to;
        $this->constrain($query, $column, $from, $to);

        $rows = $query
            ->selectRaw('date('.$column.') as day, count(*) as count')
            ->groupBy('day')
            ->orderBy('day')
            ->pluck('count', 'day');

        $series = [];
        for ($day = $from->copy()->startOfDay(); $day->lte($to); $day->addDay()) {
            $key = $day->toDateString();
            $series[] = [
                'date' => $key,
                'count' => (int) ($rows[$key] ?? 0),
            ];
        }

        return $series;
    }

    /**
     * @return list<array{key: string, count: int}>
     */
    private function ticketsByCategory(?Carbon $from, ?Carbon $to): array
    {
        $query = Ticket::query()
            ->join('events', 'events.id', '=', 'tickets.event_id')
            ->whereIn('tickets.status', ['valid', 'checked_in']);
        $this->constrain($query, 'tickets.created_at', $from, $to);

        return $query
            ->selectRaw('events.category as key, count(*) as count')
            ->groupBy('events.category')
            ->orderByDesc('count')
            ->get()
            ->map(fn ($row) => [
                'key' => (string) $row->key,
                'count' => (int) $row->count,
            ])
            ->values()
            ->all();
    }

    /**
     * @return list<array{key: string, count: int, amount: float}>
     */
    private function paymentsByMethod(?Carbon $from, ?Carbon $to): array
    {
        $query = Payment::query()->where('status', 'paid');
        $this->constrain($query, 'paid_at', $from, $to);

        return $query
            ->selectRaw('method as key, count(*) as count, sum(amount) as amount')
            ->groupBy('method')
            ->orderByDesc('count')
            ->get()
            ->map(fn ($row) => [
                'key' => (string) $row->key,
                'count' => (int) $row->count,
                'amount' => round((float) $row->amount, 2),
            ])
            ->values()
            ->all();
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function topEvents(?Carbon $from, ?Carbon $to): array
    {
        $query = Event::query()->withTicketCounts();
        $this->constrain($query, 'starts_at', $from, $to);

        return $query
            ->get()
            ->map(function (Event $event) {
                $reserved = (int) ($event->reserved_count ?? 0);
                $capacity = max(0, (int) $event->capacity);
                $fill = $capacity > 0 ? $reserved / $capacity : 0.0;

                return [
                    'id' => $event->id,
                    'title' => $event->title,
                    'category' => $event->category,
                    'capacity' => $capacity,
                    'reserved_count' => $reserved,
                    'checked_in_count' => (int) ($event->checked_in_count ?? 0),
                    'fill_rate' => round($fill, 4),
                    'starts_at' => AppDate::iso($event->starts_at),
                ];
            })
            ->sortByDesc('fill_rate')
            ->take(8)
            ->values()
            ->all();
    }

    /**
     * @return array{views: int, unique_viewers: int, saves: int, tickets: int, check_ins: int}
     */
    private function eventFunnel(Event $event, KpiRange $range): array
    {
        $viewsQuery = EventView::query()->where('event_id', $event->id);
        $this->constrain($viewsQuery, 'created_at', $range->from, $range->to);

        $uniqueQuery = EventView::query()
            ->where('event_id', $event->id)
            ->whereNotNull('user_id');
        $this->constrain($uniqueQuery, 'created_at', $range->from, $range->to);

        $guestQuery = EventView::query()
            ->where('event_id', $event->id)
            ->whereNull('user_id');
        $this->constrain($guestQuery, 'created_at', $range->from, $range->to);

        $savesQuery = SavedEvent::query()->where('event_id', $event->id);
        $this->constrain($savesQuery, 'created_at', $range->from, $range->to);

        $uniqueViewers = (int) $uniqueQuery->selectRaw('count(distinct user_id) as aggregate')->value('aggregate');

        return [
            'views' => $viewsQuery->count(),
            'unique_viewers' => $uniqueViewers + $guestQuery->count(),
            'saves' => $savesQuery->count(),
            'tickets' => (int) ($event->reserved_count ?? 0),
            'check_ins' => (int) ($event->checked_in_count ?? 0),
        ];
    }

    /**
     * @return list<array{label: string, offset_minutes: int, offset_hours: float, count: int}>
     */
    private function checkInsByHour(Event $event): array
    {
        $offsets = [-120, -90, -60, -30, 0, 30, 60, 90, 120];
        $buckets = array_fill_keys($offsets, 0);
        $labels = [
            -120 => '-2h',
            -90 => '-90m',
            -60 => '-1h',
            -30 => '-30m',
            0 => 'Start',
            30 => '+30m',
            60 => '+1h',
            90 => '+90m',
            120 => '+2h',
        ];

        $tickets = Ticket::query()
            ->where('event_id', $event->id)
            ->where('status', 'checked_in')
            ->whereNotNull('checked_in_at')
            ->get(['checked_in_at']);

        foreach ($tickets as $ticket) {
            $minutes = (int) floor($event->starts_at->floatDiffInMinutes($ticket->checked_in_at, false));
            $clamped = max(-120, min(120, $minutes));
            $bucket = (int) (floor($clamped / 30) * 30);
            $buckets[$bucket]++;
        }

        return collect($offsets)
            ->map(fn (int $offset) => [
                'label' => $labels[$offset],
                'offset_minutes' => $offset,
                'offset_hours' => $offset / 60,
                'count' => $buckets[$offset],
            ])
            ->values()
            ->all();
    }

    /**
     * @return list<array{key: string, count: int}>
     */
    private function attendeesByDepartment(string $eventId): array
    {
        return Ticket::query()
            ->join('users', 'users.id', '=', 'tickets.user_id')
            ->leftJoin('user_profiles', 'user_profiles.user_id', '=', 'users.id')
            ->where('tickets.event_id', $eventId)
            ->whereIn('tickets.status', ['valid', 'checked_in'])
            ->selectRaw("coalesce(user_profiles.department, 'Unknown') as key, count(*) as count")
            ->groupBy('key')
            ->orderByDesc('count')
            ->get()
            ->map(fn ($row) => [
                'key' => (string) $row->key,
                'count' => (int) $row->count,
            ])
            ->values()
            ->all();
    }

    /**
     * @return list<array{key: string, count: int}>
     */
    private function scanResults(string $eventId, ?Carbon $from, ?Carbon $to): array
    {
        $query = CheckInAttempt::query()->where('event_id', $eventId);
        $this->constrain($query, 'created_at', $from, $to);

        return $query
            ->selectRaw('result as key, count(*) as count')
            ->groupBy('result')
            ->orderByDesc('count')
            ->get()
            ->map(fn ($row) => [
                'key' => (string) $row->key,
                'count' => (int) $row->count,
            ])
            ->values()
            ->all();
    }

    /**
     * @return array{value: int, previous: int, delta_pct: float}
     */
    private function countMetric(int $current, int $previous): array
    {
        return [
            'value' => $current,
            'previous' => $previous,
            'delta_pct' => $this->pctChange($current, $previous),
        ];
    }

    /**
     * @return array{value: float, previous: float, delta_pts: float}
     */
    private function rateMetric(float $current, float $previous): array
    {
        return [
            'value' => round($current, 4),
            'previous' => round($previous, 4),
            'delta_pts' => round(($current - $previous) * 100, 1),
        ];
    }

    private function pctChange(float $current, float $previous): float
    {
        if ($previous == 0.0) {
            return $current == 0.0 ? 0.0 : 100.0;
        }

        return round((($current - $previous) / $previous) * 100, 1);
    }

    /**
     * @param  Builder<*>  $query
     */
    private function constrain(Builder $query, string $column, ?Carbon $from, ?Carbon $to): void
    {
        if ($from !== null) {
            $query->where($column, '>=', $from);
        }

        if ($to !== null) {
            $query->where($column, '<=', $to);
        }
    }
}
