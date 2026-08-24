import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/admin/admin_event_controller.dart';
import 'package:itc_events/modules/admin/admin_event_form_page.dart';
// import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  late final AdminEventController _controller;

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
      appBar: AppBar(title: const Text('Manage events')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AdminEventFormPage()),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.events.isEmpty) {
          return const LoadingView(message: 'Loading events…');
        }

        if (_controller.errorMessage.value != null &&
            _controller.events.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: _controller.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: _controller.fetchEvents,
          );
        }

        final events = _controller.events;
        if (events.isEmpty) {
          return const EmptyStateView(
            icon: Icons.event_note_outlined,
            message: 'No events yet. Create a draft to get started.',
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchEvents,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return EventListCard(
                event: event,
                showAdminCounts: true,
                onTap: () => Get.to(() => AdminEventFormPage(event: event)),
              );
            },
          ),
        );
      }),
    );
  }
}
