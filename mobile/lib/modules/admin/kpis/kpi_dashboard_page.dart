import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/admin/kpis/event_kpi_page.dart';
import 'package:itc_events/modules/admin/kpis/kpi_charts.dart';
import 'package:itc_events/modules/admin/kpis/kpi_controller.dart';
import 'package:itc_events/modules/admin/kpis/kpi_models.dart';
import 'package:itc_events/modules/admin/kpis/kpi_widgets.dart';

class KpiDashboardPage extends StatefulWidget {
  const KpiDashboardPage({super.key, this.fetchOnStart = true});

  final bool fetchOnStart;

  @override
  State<KpiDashboardPage> createState() => _KpiDashboardPageState();
}

class _KpiDashboardPageState extends State<KpiDashboardPage> {
  late final KpiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(KpiController(apiClient: Get.find<ApiClient>()));
    if (widget.fetchOnStart) {
      _controller.fetchOverview();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<KpiController>()) {
      Get.delete<KpiController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'kpi_dashboard'.tr),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.overview.value == null) {
          return LoadingView(message: 'loading_kpis'.tr);
        }

        if (_controller.errorMessage.value != null &&
            _controller.overview.value == null) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.errorMessage.value!,
            actionLabel: 'retry'.tr,
            onAction: _controller.fetchOverview,
          );
        }

        final data = _controller.overview.value;
        if (data == null) {
          return EmptyStateView(
            icon: Icons.insights_outlined,
            message: 'kpi_empty'.tr,
            subtitle: 'kpi_empty_subtitle'.tr,
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchOverview,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              KpiRangeChips(controller: _controller),
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
                    label: 'kpi_tickets'.tr,
                    value: '${data.tickets.value}',
                    delta: formatPctDelta(data.tickets.deltaPct),
                    positive: data.tickets.deltaPct >= 0,
                  ),
                  KpiStatCard(
                    label: 'kpi_fill_rate'.tr,
                    value: formatPercent(data.fillRate.value),
                    delta: formatPtsDelta(data.fillRate.deltaPts),
                    positive: data.fillRate.deltaPts >= 0,
                  ),
                  KpiStatCard(
                    label: 'kpi_check_in_rate'.tr,
                    value: formatPercent(data.checkInRate.value),
                    delta: formatPtsDelta(data.checkInRate.deltaPts),
                    positive: data.checkInRate.deltaPts >= 0,
                  ),
                  KpiStatCard(
                    label: 'kpi_revenue'.tr,
                    value: formatUsd(data.revenue.usd),
                    delta: formatPctDelta(data.revenue.deltaPct),
                    positive: data.revenue.deltaPct >= 0,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_tickets_and_check_ins'.tr,
                child: KpiTrendChart(
                  tickets: data.ticketsByDay,
                  checkIns: data.checkInsByDay,
                ),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_tickets_by_category'.tr,
                child: data.ticketsByCategory.isEmpty
                    ? Text('kpi_no_chart_data'.tr)
                    : Column(
                        children: [
                          for (final item in data.ticketsByCategory)
                            KpiProgressRow(
                              label: item.key,
                              value: item.count,
                              max: data.ticketsByCategory.first.count,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_payments'.tr,
                child: KpiPaymentPie(methods: data.paymentsByMethod),
              ),
              const SizedBox(height: 12),
              KpiSectionCard(
                title: 'kpi_top_events'.tr,
                child: data.topEvents.isEmpty
                    ? Text('kpi_no_chart_data'.tr)
                    : Column(
                        children: [
                          for (final event in data.topEvents)
                            _TopEventRow(event: event),
                        ],
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TopEventRow extends StatelessWidget {
  const _TopEventRow({required this.event});

  final KpiTopEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => EventKpiPage(eventId: event.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.category} · ${event.reservedCount} / ${event.capacity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              formatPercent(event.fillRate),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }
}
