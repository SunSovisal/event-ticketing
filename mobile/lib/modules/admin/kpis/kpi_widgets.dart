import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/modules/admin/kpis/kpi_controller.dart';

class KpiRangeChips extends StatelessWidget {
  const KpiRangeChips({super.key, required this.controller, this.eventId});

  final KpiController controller;
  final String? eventId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final key in KpiController.ranges)
            ChoiceChip(
              label: Text('kpi_range_$key'.tr),
              selected: controller.range.value == key,
              onSelected: (_) => controller.setRange(key, eventId: eventId),
            ),
        ],
      );
    });
  }
}

class KpiStatCard extends StatelessWidget {
  const KpiStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    this.positive,
  });

  final String label;
  final String value;
  final String delta;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final deltaColor = positive == null
        ? AppTheme.textSecondaryOf(context)
        : (positive! ? AppTheme.success : AppTheme.error);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            delta,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: deltaColor),
          ),
        ],
      ),
    );
  }
}

class KpiSectionCard extends StatelessWidget {
  const KpiSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class KpiProgressRow extends StatelessWidget {
  const KpiProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.borderOf(context),
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String formatPctDelta(double value) {
  final sign = value > 0 ? '+' : '';
  final amount = '$sign${value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)}%';
  return 'kpi_vs_prior_pct'.trParams({'value': amount});
}

String formatPtsDelta(double value) {
  final sign = value > 0 ? '+' : '';
  final amount = '$sign${value.toStringAsFixed(1)}';
  return 'kpi_vs_prior_pts'.trParams({'value': amount});
}

String formatPercent(double rate) => '${(rate * 100).round()}%';

String formatUsd(double amount) => '\$${amount.toStringAsFixed(2)}';
