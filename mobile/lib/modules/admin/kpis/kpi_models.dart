class KpiCountMetric {
  const KpiCountMetric({
    required this.value,
    required this.previous,
    required this.deltaPct,
  });

  final int value;
  final int previous;
  final double deltaPct;

  factory KpiCountMetric.fromJson(Map<String, dynamic> json) {
    return KpiCountMetric(
      value: _asInt(json['value']),
      previous: _asInt(json['previous']),
      deltaPct: _asDouble(json['delta_pct']),
    );
  }
}

class KpiRateMetric {
  const KpiRateMetric({
    required this.value,
    required this.previous,
    required this.deltaPts,
  });

  final double value;
  final double previous;
  final double deltaPts;

  factory KpiRateMetric.fromJson(Map<String, dynamic> json) {
    return KpiRateMetric(
      value: _asDouble(json['value']),
      previous: _asDouble(json['previous']),
      deltaPts: _asDouble(json['delta_pts']),
    );
  }
}

class KpiRevenueMetric {
  const KpiRevenueMetric({
    required this.usd,
    required this.khr,
    required this.previousUsd,
    required this.previousKhr,
    required this.deltaPct,
  });

  final double usd;
  final double khr;
  final double previousUsd;
  final double previousKhr;
  final double deltaPct;

  factory KpiRevenueMetric.fromJson(Map<String, dynamic> json) {
    return KpiRevenueMetric(
      usd: _asDouble(json['usd']),
      khr: _asDouble(json['khr']),
      previousUsd: _asDouble(json['previous_usd']),
      previousKhr: _asDouble(json['previous_khr']),
      deltaPct: _asDouble(json['delta_pct']),
    );
  }
}

class KpiDayPoint {
  const KpiDayPoint({required this.date, required this.count});

  final String date;
  final int count;

  factory KpiDayPoint.fromJson(Map<String, dynamic> json) {
    return KpiDayPoint(
      date: json['date']?.toString() ?? '',
      count: _asInt(json['count']),
    );
  }
}

class KpiNamedCount {
  const KpiNamedCount({required this.key, required this.count, this.amount});

  final String key;
  final int count;
  final double? amount;

  factory KpiNamedCount.fromJson(Map<String, dynamic> json) {
    return KpiNamedCount(
      key: json['key']?.toString() ?? '',
      count: _asInt(json['count']),
      amount: json.containsKey('amount') ? _asDouble(json['amount']) : null,
    );
  }
}

class KpiTopEvent {
  const KpiTopEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.capacity,
    required this.reservedCount,
    required this.checkedInCount,
    required this.fillRate,
    this.startsAt,
  });

  final String id;
  final String title;
  final String category;
  final int capacity;
  final int reservedCount;
  final int checkedInCount;
  final double fillRate;
  final DateTime? startsAt;

  factory KpiTopEvent.fromJson(Map<String, dynamic> json) {
    return KpiTopEvent(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      capacity: _asInt(json['capacity']),
      reservedCount: _asInt(json['reserved_count']),
      checkedInCount: _asInt(json['checked_in_count']),
      fillRate: _asDouble(json['fill_rate']),
      startsAt: _parseDate(json['starts_at']),
    );
  }
}

class KpiOverview {
  const KpiOverview({
    required this.range,
    required this.tickets,
    required this.fillRate,
    required this.checkInRate,
    required this.revenue,
    required this.ticketsByDay,
    required this.checkInsByDay,
    required this.ticketsByCategory,
    required this.paymentsByMethod,
    required this.topEvents,
  });

  final String range;
  final KpiCountMetric tickets;
  final KpiRateMetric fillRate;
  final KpiRateMetric checkInRate;
  final KpiRevenueMetric revenue;
  final List<KpiDayPoint> ticketsByDay;
  final List<KpiDayPoint> checkInsByDay;
  final List<KpiNamedCount> ticketsByCategory;
  final List<KpiNamedCount> paymentsByMethod;
  final List<KpiTopEvent> topEvents;

  bool get isEmpty => tickets.value == 0 && topEvents.isEmpty;

  factory KpiOverview.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] as Map<String, dynamic>? ?? const {};
    final series = json['series'] as Map<String, dynamic>? ?? const {};
    final breakdowns = json['breakdowns'] as Map<String, dynamic>? ?? const {};

    return KpiOverview(
      range: json['range']?.toString() ?? '30d',
      tickets: KpiCountMetric.fromJson(
        overview['tickets'] as Map<String, dynamic>? ?? const {},
      ),
      fillRate: KpiRateMetric.fromJson(
        overview['fill_rate'] as Map<String, dynamic>? ?? const {},
      ),
      checkInRate: KpiRateMetric.fromJson(
        overview['check_in_rate'] as Map<String, dynamic>? ?? const {},
      ),
      revenue: KpiRevenueMetric.fromJson(
        overview['revenue'] as Map<String, dynamic>? ?? const {},
      ),
      ticketsByDay: _list(series['tickets_by_day'], KpiDayPoint.fromJson),
      checkInsByDay: _list(series['check_ins_by_day'], KpiDayPoint.fromJson),
      ticketsByCategory: _list(
        breakdowns['tickets_by_category'],
        KpiNamedCount.fromJson,
      ),
      paymentsByMethod: _list(
        breakdowns['payments_by_method'],
        KpiNamedCount.fromJson,
      ),
      topEvents: _list(json['top_events'], KpiTopEvent.fromJson),
    );
  }
}

class KpiFunnel {
  const KpiFunnel({
    required this.views,
    required this.uniqueViewers,
    required this.saves,
    required this.tickets,
    required this.checkIns,
  });

  final int views;
  final int uniqueViewers;
  final int saves;
  final int tickets;
  final int checkIns;

  factory KpiFunnel.fromJson(Map<String, dynamic> json) {
    return KpiFunnel(
      views: _asInt(json['views']),
      uniqueViewers: _asInt(json['unique_viewers']),
      saves: _asInt(json['saves']),
      tickets: _asInt(json['tickets']),
      checkIns: _asInt(json['check_ins']),
    );
  }
}

class KpiHourBucket {
  const KpiHourBucket({
    required this.label,
    required this.offsetMinutes,
    required this.count,
  });

  final String label;
  final int offsetMinutes;
  final int count;

  factory KpiHourBucket.fromJson(Map<String, dynamic> json) {
    final minutes = json.containsKey('offset_minutes')
        ? _asInt(json['offset_minutes'])
        : (_asDouble(json['offset_hours']) * 60).round();
    return KpiHourBucket(
      label: json['label']?.toString() ?? '',
      offsetMinutes: minutes,
      count: _asInt(json['count']),
    );
  }
}

class KpiEventInsights {
  const KpiEventInsights({
    required this.range,
    required this.eventId,
    required this.title,
    required this.category,
    required this.locationLabel,
    required this.capacity,
    required this.fillRate,
    required this.reservedCount,
    required this.checkInRate,
    required this.checkedInCount,
    required this.noShowRate,
    required this.noShowCount,
    required this.revenueUsd,
    required this.revenueKhr,
    required this.funnel,
    required this.checkInsByHour,
    required this.attendeesByDepartment,
    required this.scanResults,
  });

  final String range;
  final String eventId;
  final String title;
  final String category;
  final String locationLabel;
  final int capacity;
  final double fillRate;
  final int reservedCount;
  final double checkInRate;
  final int checkedInCount;
  final double noShowRate;
  final int noShowCount;
  final double revenueUsd;
  final double revenueKhr;
  final KpiFunnel funnel;
  final List<KpiHourBucket> checkInsByHour;
  final List<KpiNamedCount> attendeesByDepartment;
  final List<KpiNamedCount> scanResults;

  factory KpiEventInsights.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>? ?? const {};
    final overview = json['overview'] as Map<String, dynamic>? ?? const {};

    return KpiEventInsights(
      range: json['range']?.toString() ?? '30d',
      eventId: event['id']?.toString() ?? '',
      title: event['title'] as String? ?? '',
      category: event['category'] as String? ?? '',
      locationLabel: event['location_label'] as String? ?? '',
      capacity: _asInt(event['capacity']),
      fillRate: _asDouble(overview['fill_rate']),
      reservedCount: _asInt(overview['reserved_count']),
      checkInRate: _asDouble(overview['check_in_rate']),
      checkedInCount: _asInt(overview['checked_in_count']),
      noShowRate: _asDouble(overview['no_show_rate']),
      noShowCount: _asInt(overview['no_show_count']),
      revenueUsd: _asDouble(overview['revenue_usd']),
      revenueKhr: _asDouble(overview['revenue_khr']),
      funnel: KpiFunnel.fromJson(
        json['funnel'] as Map<String, dynamic>? ?? const {},
      ),
      checkInsByHour: _list(json['check_ins_by_hour'], KpiHourBucket.fromJson),
      attendeesByDepartment: _list(
        json['attendees_by_department'],
        KpiNamedCount.fromJson,
      ),
      scanResults: _list(json['scan_results'], KpiNamedCount.fromJson),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic> json) parse) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}
