import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/admin/kpis/kpi_binding.dart';
import 'package:itc_events/modules/admin/kpis/kpi_charts.dart';
import 'package:itc_events/modules/admin/kpis/kpi_controller.dart';
import 'package:itc_events/modules/admin/kpis/kpi_widgets.dart';
import 'package:itc_events/modules/admin/kpis/models/kpi_models.dart';

class EventKpiPage extends StatefulWidget {
  const EventKpiPage({
    super.key,
    required this.eventId,
    this.fetchOnStart = true,
  });

  final String eventId;
  final bool fetchOnStart;

  @override
  State<EventKpiPage> createState() => _EventKpiPageState();
}

class _EventKpiPageState extends State<EventKpiPage> {
  late final KpiController _controller;

  @override
  void initState() {
    super.initState();
    EventKpiBinding(widget.eventId).dependencies();
    _controller = Get.find<KpiController>(tag: widget.eventId);
    if (widget.fetchOnStart) {
      _controller.fetchEvent(widget.eventId);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<KpiController>(tag: widget.eventId)) {
      Get.delete<KpiController>(tag: widget.eventId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'event_insights'.tr),
      body: Obx(() {
        if (_controller.isLoading.value &&
            _controller.eventInsights.value == null) {
          return LoadingView(message: 'loading_kpis'.tr);
        }

        if (_controller.errorMessage.value != null &&
            _controller.eventInsights.value == null) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.errorMessage.value!,
            actionLabel: 'retry'.tr,
            onAction: () => _controller.fetchEvent(widget.eventId),
          );
        }

        final data = _controller.eventInsights.value;
        if (data == null) {
          return EmptyStateView(
            icon: Icons.insights_outlined,
            message: 'kpi_empty'.tr,
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.fetchEvent(widget.eventId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.category} · ${data.locationLabel} · ${data.capacity} ${'kpi_capacity'.tr}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              KpiRangeChips(controller: _controller, eventId: widget.eventId),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35,
                children: [
                  KpiStatCard(
                    label: 'kpi_fill_rate'.tr,
                    value: formatPercent(data.fillRate),
                    delta: 'kpi_reserved_count'.trParams({
                      'count': '${data.reservedCount}',
                    }),
                  ),
                  KpiStatCard(
                    label: 'kpi_check_in_rate'.tr,
                    value: formatPercent(data.checkInRate),
                    delta: 'kpi_checked_in_of'.trParams({
                      'checked': '${data.checkedInCount}',
                      'reserved': '${data.reservedCount}',
                    }),
                  ),
                  KpiStatCard(
                    label: 'kpi_no_shows'.tr,
                    value: formatPercent(data.noShowRate),
                    delta: 'kpi_no_show_count'.trParams({
                      'count': '${data.noShowCount}',
                    }),
                    positive: data.noShowRate <= 0.25,
                  ),
                  KpiStatCard(
                    label: 'kpi_revenue'.tr,
                    value: formatUsd(data.revenueUsd),
                    delta: data.revenueKhr > 0
                        ? '${data.revenueKhr.round()} ៛'
                        : 'KHQR',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_funnel'.tr,
                child: Column(
                  children: [
                    KpiProgressRow(
                      label: 'kpi_views'.tr,
                      value: data.funnel.views,
                      max: _funnelMax(data),
                    ),
                    KpiProgressRow(
                      label: 'kpi_saves'.tr,
                      value: data.funnel.saves,
                      max: _funnelMax(data),
                    ),
                    KpiProgressRow(
                      label: 'kpi_tickets'.tr,
                      value: data.funnel.tickets,
                      max: _funnelMax(data),
                    ),
                    KpiProgressRow(
                      label: 'kpi_check_ins'.tr,
                      value: data.funnel.checkIns,
                      max: _funnelMax(data),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_check_ins_by_hour'.tr,
                child: KpiHourChart(buckets: data.checkInsByHour),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_attendees_by_department'.tr,
                child: KpiNamedPie(items: data.attendeesByDepartment),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_scan_results'.tr,
                child: data.scanResults.isEmpty
                    ? Text('kpi_no_chart_data'.tr)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in data.scanResults)
                            Chip(
                              label: Text(
                                '${_scanLabel(item.key)} ${item.count}',
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  int _funnelMax(KpiEventInsights data) {
    final values = [
      data.funnel.views,
      data.funnel.saves,
      data.funnel.tickets,
      data.funnel.checkIns,
    ];
    return values.reduce((a, b) => a > b ? a : b);
  }

  String _scanLabel(String key) {
    return 'kpi_scan_$key'.tr;
  }
}
