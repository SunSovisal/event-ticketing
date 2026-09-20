import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/admin/kpis/models/kpi_models.dart';

class KpiTrendChart extends StatelessWidget {
  const KpiTrendChart({
    super.key,
    required this.tickets,
    required this.checkIns,
  });

  final List<KpiDayPoint> tickets;
  final List<KpiDayPoint> checkIns;

  @override
  Widget build(BuildContext context) {
    if (tickets.every((point) => point.count == 0) &&
        checkIns.every((point) => point.count == 0)) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'kpi_no_chart_data'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final spotsTickets = _spots(tickets);
    final spotsCheckIns = _spots(checkIns);
    final maxY = [
      ...tickets.map((point) => point.count),
      ...checkIns.map((point) => point.count),
      1,
    ].reduce((a, b) => a > b ? a : b).toDouble();
    final chartMax = (maxY * 1.2).ceilToDouble();
    final yInterval = chartMax <= 4 ? 1.0 : (chartMax / 4).ceilToDouble();
    final xInterval = tickets.length <= 8
        ? 1.0
        : (tickets.length / 5).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KpiSeriesLegend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                clipData: const FlClipData.all(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipBorder: BorderSide(
                      color: AppTheme.borderOf(context),
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return [
                        for (final spot in touchedSpots)
                          LineTooltipItem(
                            '${spot.y.toInt()}',
                            TextStyle(
                              color:
                                  spot.bar.color ??
                                  AppTheme.textPrimaryOf(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ];
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if ((value - meta.max).abs() < 0.01) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= tickets.length) {
                          return const SizedBox.shrink();
                        }
                        if ((value - index).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        final date = tickets[index].date;
                        final label = date.length >= 10
                            ? date.substring(8)
                            : date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsTickets,
                    color: AppTheme.primary,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: spotsCheckIns,
                    color: AppTheme.success,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _spots(List<KpiDayPoint> points) {
    return [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].count.toDouble()),
    ];
  }
}

class KpiSeriesLegend extends StatelessWidget {
  const KpiSeriesLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        _swatch(AppTheme.primary),
        const SizedBox(width: 6),
        Text('kpi_tickets'.tr, style: style),
        const SizedBox(width: 16),
        _swatch(AppTheme.success),
        const SizedBox(width: 6),
        Text('kpi_check_ins'.tr, style: style),
      ],
    );
  }

  Widget _swatch(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class KpiHourChart extends StatelessWidget {
  const KpiHourChart({super.key, required this.buckets});

  final List<KpiHourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty || buckets.every((bucket) => bucket.count == 0)) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'kpi_no_chart_data'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final total = buckets.fold<int>(0, (sum, bucket) => sum + bucket.count);
    final peak = _peakBucket(buckets);
    final before = buckets
        .where((bucket) => bucket.offsetMinutes < 0)
        .fold<int>(0, (sum, bucket) => sum + bucket.count);
    final after = buckets
        .where((bucket) => bucket.offsetMinutes > 0)
        .fold<int>(0, (sum, bucket) => sum + bucket.count);
    final maxY = buckets
        .map((bucket) => bucket.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final chartMax = (maxY * 1.35).clamp(1, double.infinity).ceilToDouble();
    final yInterval = chartMax <= 4 ? 1.0 : (chartMax / 4).ceilToDouble();
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final peakPercent = total == 0 ? 0 : ((peak.count / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'kpi_arrival_peak'.trParams({
            'label': peak.label,
            'count': '${peak.count}',
            'percent': '$peakPercent',
          }),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (before + after > 0) ...[
          const SizedBox(height: 2),
          Text(
            'kpi_arrival_split'.trParams({
              'before': '$before',
              'after': '$after',
            }),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 8),
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderOf(context).withValues(alpha: 0.45),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.surface,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipBorder: BorderSide(
                      color: AppTheme.borderOf(context),
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= buckets.length) {
                        return null;
                      }
                      final bucket = buckets[groupIndex];
                      return BarTooltipItem(
                        '${bucket.label}\n${bucket.count}',
                        TextStyle(
                          color: AppTheme.textPrimaryOf(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if ((value - meta.max).abs() < 0.01) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: labelStyle,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        if ((value - index).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        final bucket = buckets[index];
                        final isMajorTick =
                            bucket.offsetMinutes % 60 == 0 ||
                            bucket.offsetMinutes == 0;
                        if (!isMajorTick) {
                          return const SizedBox.shrink();
                        }
                        final isStart = bucket.offsetMinutes == 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            bucket.label,
                            style: labelStyle?.copyWith(
                              fontWeight: isStart
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isStart
                                  ? AppTheme.primary
                                  : AppTheme.textSecondaryOf(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].count.toDouble(),
                          width: buckets.length > 6 ? 12 : 16,
                          color: _barColor(buckets[i], peak),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMax,
                            color: AppTheme.borderOf(
                              context,
                            ).withValues(alpha: 0.28),
                          ),
                          label: BarChartRodLabel(
                            show:
                                buckets[i].offsetMinutes ==
                                    peak.offsetMinutes &&
                                buckets[i].count > 0,
                            text: '${buckets[i].count}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                            offset: const Offset(0, -2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _barColor(KpiHourBucket bucket, KpiHourBucket peak) {
    if (bucket.offsetMinutes == peak.offsetMinutes && bucket.count > 0) {
      return AppTheme.primary;
    }
    if (bucket.offsetMinutes == 0) {
      return AppTheme.heroIndigo.withValues(alpha: 0.55);
    }
    return AppTheme.primary.withValues(alpha: 0.28);
  }

  KpiHourBucket _peakBucket(List<KpiHourBucket> buckets) {
    var peak = buckets.first;
    for (final bucket in buckets.skip(1)) {
      if (bucket.count > peak.count) {
        peak = bucket;
        continue;
      }
      if (bucket.count == peak.count &&
          bucket.offsetMinutes.abs() < peak.offsetMinutes.abs()) {
        peak = bucket;
      }
    }
    return peak;
  }
}

const _pieColors = [
  AppTheme.primary,
  AppTheme.heroIndigo,
  Color(0xFF0EA5E9),
  AppTheme.success,
  AppTheme.warning,
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  AppTheme.heroBlue,
  Color(0xFF64748B),
];

class KpiNamedPie extends StatelessWidget {
  const KpiNamedPie({super.key, required this.items, this.labelOf});

  final List<KpiNamedCount> items;
  final String Function(String key)? labelOf;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) {
      return Text(
        'kpi_no_chart_data'.tr,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (var i = 0; i < items.length; i++)
                  PieChartSectionData(
                    value: items[i].count.toDouble(),
                    title: _sliceTitle(items[i].count, total),
                    color: _pieColors[i % _pieColors.length],
                    radius: 48,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < items.length; i++)
              _PieLegendItem(
                color: _pieColors[i % _pieColors.length],
                label:
                    '${_label(items[i].key)} ${items[i].count} (${_percent(items[i].count, total)}%)',
              ),
          ],
        ),
      ],
    );
  }

  String _label(String key) => labelOf?.call(key) ?? key;

  String _sliceTitle(int count, int total) {
    final percent = _percent(count, total);
    return percent >= 8 ? '$percent%' : '';
  }

  int _percent(int count, int total) => ((count / total) * 100).round();
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class KpiPaymentPie extends StatelessWidget {
  const KpiPaymentPie({super.key, required this.methods});

  final List<KpiNamedCount> methods;

  @override
  Widget build(BuildContext context) {
    return KpiNamedPie(
      items: methods,
      labelOf: (key) => key == 'aba_pay' ? 'ABA Pay' : key.toUpperCase(),
    );
  }
}
