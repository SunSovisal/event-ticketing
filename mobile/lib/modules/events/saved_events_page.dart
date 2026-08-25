import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/events/bookmark_actions.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/saved_event_controller.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

class SavedEventsPage extends StatefulWidget {
  const SavedEventsPage({super.key});

  @override
  State<SavedEventsPage> createState() => _SavedEventsPageState();
}

class _SavedEventsPageState extends State<SavedEventsPage> {
  late final SavedEventController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      SavedEventController(apiClient: Get.find<ApiClient>()),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<SavedEventController>()) {
      Get.delete<SavedEventController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved events')),
      body: Obx(() {
        final savingIds = Get.isRegistered<EventController>()
            ? Get.find<EventController>().savingIds
            : <String>{};
        if (_controller.isLoading.value && _controller.events.isEmpty) {
          return const LoadingView(message: 'Loading saved events…');
        }

        if (_controller.errorMessage.value != null &&
            _controller.events.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: _controller.fetchSaved,
          );
        }

        final events = _controller.events;
        if (events.isEmpty) {
          return const EmptyStateView(
            icon: Icons.bookmark_border,
            message: 'No saved events yet',
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchSaved,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return EventListCard(
                event: event,
                onTap: () => Get.to(() => EventDetailPage(event: event)),
                onBookmark: () => toggleEventBookmark(context, event),
                isBookmarkBusy: savingIds.contains(event.id),
              );
            },
          ),
        );
      }),
    );
  }
}
