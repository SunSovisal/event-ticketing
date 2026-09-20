import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/admin/events/admin_event_controller.dart';
import 'package:itc_events/modules/admin/events/admin_event_form_page.dart';
import 'package:itc_events/modules/admin/events/admin_event_logs_page.dart';
import 'package:itc_events/modules/admin/kpis/kpi_binding.dart';
import 'package:itc_events/modules/admin/kpis/event_kpi_page.dart';
import 'package:itc_events/modules/events/models/event.dart';

class AdminEventDetailPage extends StatefulWidget {
  const AdminEventDetailPage({super.key, required this.event});

  final Event event;

  @override
  State<AdminEventDetailPage> createState() => _AdminEventDetailPageState();
}

class _AdminEventDetailPageState extends State<AdminEventDetailPage> {
  late final AdminEventController _controller;
  late Event _event;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminEventController>();
    _event = widget.event;
  }

  Future<void> _refresh() async {
    await _controller.fetchEvents();
    final index = _controller.events.indexWhere((item) => item.id == _event.id);
    if (index >= 0) {
      setState(() => _event = _controller.events[index]);
    }
  }

  Future<void> _openEdit() async {
    await Get.to(() => AdminEventFormPage(event: _event));
    if (!mounted) return;
    final index = _controller.events.indexWhere((item) => item.id == _event.id);
    if (index < 0) {
      Navigator.pop(context);
      return;
    }
    final updated = _controller.events[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _event = updated);
    });
  }

  void _openLogs() {
    Get.to(() => AdminEventLogsPage(event: _event));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(
        title: 'event_detail'.tr,
        actions: [
          TextButton(
            onPressed: _openEdit,
            child: Text(_event.canEdit ? 'edit'.tr : 'view'.tr),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SummaryCard(event: _event),
            const SizedBox(height: 16),
            _LogsNavCard(
              key: const Key('admin_event_kpi_nav'),
              icon: Icons.insights_outlined,
              title: 'event_insights'.tr,
              subtitle: 'event_insights_subtitle'.tr,
              onTap: () => Get.to(
                () => EventKpiPage(eventId: _event.id),
                binding: EventKpiBinding(_event.id),
              ),
            ),
            const SizedBox(height: 12),
            _LogsNavCard(
              key: const Key('admin_event_manage_nav'),
              icon: Icons.manage_accounts_outlined,
              title: 'manage_event'.tr,
              subtitle: 'manage_event_subtitle'.tr,
              onTap: _openLogs,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip.eventStatus(event.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            EventDate.format(event.startsAt),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            event.locationLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'reserved_checked_in'.trParams({
              'reserved': '${event.reservedCount}',
              'checkedIn': '${event.checkedInCount}',
            }),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LogsNavCard extends StatelessWidget {
  const _LogsNavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.textSecondaryOf(context)),
        ],
      ),
    );
  }
}
