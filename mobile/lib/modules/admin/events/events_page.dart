import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/admin/events/event_controller.dart';
import 'package:itc_events/modules/admin/events/event_detail_page.dart';
import 'package:itc_events/modules/admin/events/event_form_page.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

enum _EventSegment { draft, published, cancelled }

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  late final AdminEventController _controller;
  _EventSegment _segment = _EventSegment.published;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      AdminEventController(apiClient: Get.find<ApiClient>()),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<AdminEventController>()) {
      Get.delete<AdminEventController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'manage_events'.tr),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AdminEventFormPage()),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.events.isEmpty) {
          return LoadingView(message: 'loading_events'.tr);
        }

        if (_controller.errorMessage.value != null &&
            _controller.events.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.errorMessage.value!,
            actionLabel: 'retry'.tr,
            onAction: _controller.fetchEvents,
          );
        }

        final events = switch (_segment) {
          _EventSegment.draft => _controller.drafts,
          _EventSegment.published => _controller.published,
          _EventSegment.cancelled => _controller.cancelled,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EventStatusTabs(
              selected: _segment,
              onSelected: (value) => setState(() => _segment = value),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.fetchEvents,
                child: events.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.55,
                            child: EmptyStateView(
                              icon: Icons.event_note_outlined,
                              message: switch (_segment) {
                                _EventSegment.draft => 'no_draft_events'.tr,
                                _EventSegment.published =>
                                  'no_published_events'.tr,
                                _EventSegment.cancelled =>
                                  'no_cancelled_events'.tr,
                              },
                              subtitle: switch (_segment) {
                                _EventSegment.draft =>
                                  'create_draft_hint'.tr,
                                _EventSegment.published =>
                                  'published_events_hint'.tr,
                                _EventSegment.cancelled =>
                                  'cancelled_events_hint'.tr,
                              },
                              actionLabel: switch (_segment) {
                                _EventSegment.draft => 'create_draft'.tr,
                                _EventSegment.published ||
                                _EventSegment.cancelled => 'refresh'.tr,
                              },
                              onAction: switch (_segment) {
                                _EventSegment.draft =>
                                  () => Get.to(() => AdminEventFormPage()),
                                _EventSegment.published ||
                                _EventSegment.cancelled =>
                                  _controller.fetchEvents,
                              },
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final Event event = events[index];
                          return EventListCard(
                            event: event,
                            showAdminCounts: true,
                            onTap: () => Get.to(
                              () => AdminEventDetailPage(event: event),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _EventStatusTabs extends StatelessWidget {
  const _EventStatusTabs({required this.selected, required this.onSelected});

  final _EventSegment selected;
  final ValueChanged<_EventSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
      ),
      child: Row(
        children: [
          for (final segment in _EventSegment.values)
            Expanded(
              child: _StatusTab(
                label: switch (segment) {
                  _EventSegment.draft => 'tab_draft'.tr,
                  _EventSegment.published => 'tab_published'.tr,
                  _EventSegment.cancelled => 'tab_cancelled'.tr,
                },
                selected: selected == segment,
                onTap: () => onSelected(segment),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.textSecondaryOf(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 36 : 0,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
