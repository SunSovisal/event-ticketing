import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/admin/kpis/kpi_models.dart';

void main() {
  test('KpiOverview.fromJson maps headline cards and series', () {
    final overview = KpiOverview.fromJson({
      'range': '30d',
      'overview': {
        'tickets': {'value': 342, 'previous': 290, 'delta_pct': 18},
        'fill_rate': {'value': 0.72, 'previous': 0.68, 'delta_pts': 4},
        'check_in_rate': {'value': 0.61, 'previous': 0.64, 'delta_pts': -3},
        'revenue': {
          'usd': 48.2,
          'khr': 0,
          'previous_usd': 43,
          'previous_khr': 0,
          'delta_pct': 12.1,
        },
      },
      'series': {
        'tickets_by_day': [
          {'date': '2026-09-03', 'count': 12},
        ],
        'check_ins_by_day': [
          {'date': '2026-09-03', 'count': 7},
        ],
      },
      'breakdowns': {
        'tickets_by_category': [
          {'key': 'Workshop', 'count': 86},
        ],
        'payments_by_method': [
          {'key': 'khqr', 'count': 20, 'amount': 12.5},
        ],
      },
      'top_events': [
        {
          'id': 'evt-1',
          'title': 'ITC Coding Day',
          'category': 'Workshop',
          'capacity': 40,
          'reserved_count': 38,
          'checked_in_count': 29,
          'fill_rate': 0.95,
          'starts_at': '2026-09-11T16:00:00+07:00',
        },
      ],
    });

    expect(overview.tickets.value, 342);
    expect(overview.fillRate.deltaPts, 4);
    expect(overview.revenue.usd, 48.2);
    expect(overview.ticketsByCategory.single.key, 'Workshop');
    expect(overview.topEvents.single.title, 'ITC Coding Day');
    expect(overview.isEmpty, isFalse);
  });

  test('KpiEventInsights.fromJson maps funnel and scan results', () {
    final insights = KpiEventInsights.fromJson({
      'range': '30d',
      'event': {
        'id': 'evt-1',
        'title': 'ITC Coding Day',
        'category': 'Workshop',
        'location_label': 'Building A - Hall',
        'capacity': 40,
      },
      'overview': {
        'fill_rate': 0.95,
        'reserved_count': 38,
        'check_in_rate': 0.76,
        'checked_in_count': 29,
        'no_show_rate': 0.24,
        'no_show_count': 9,
        'revenue_usd': 0.38,
        'revenue_khr': 0,
      },
      'funnel': {
        'views': 420,
        'unique_viewers': 300,
        'saves': 86,
        'tickets': 38,
        'check_ins': 29,
      },
      'check_ins_by_hour': [
        {'label': 'Start', 'offset_minutes': 0, 'count': 14},
      ],
      'attendees_by_department': [
        {'key': 'GIC', 'count': 14},
      ],
      'scan_results': [
        {'key': 'success', 'count': 29},
      ],
    });

    expect(insights.title, 'ITC Coding Day');
    expect(insights.funnel.views, 420);
    expect(insights.checkInsByHour.single.label, 'Start');
    expect(insights.checkInsByHour.single.offsetMinutes, 0);
    expect(insights.scanResults.single.key, 'success');
  });

  test('KpiHourBucket.fromJson falls back from offset_hours', () {
    final bucket = KpiHourBucket.fromJson({
      'label': '+30m',
      'offset_hours': 0.5,
      'count': 3,
    });

    expect(bucket.offsetMinutes, 30);
    expect(bucket.count, 3);
  });
}
