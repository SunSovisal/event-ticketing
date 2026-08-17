import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';
import 'package:itc_events/modules/events/mock_events.dart';
import 'package:itc_events/modules/events/widgets/event_list_card.dart';

class AdminEventsPage extends StatelessWidget {
  const AdminEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = MockEvents.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage events')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create event form comes in a later week.'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: events.isEmpty
          ? const EmptyStateView(
              icon: Icons.event_note_outlined,
              message: 'No events yet. Create a draft to get started.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return EventListCard(
                  event: event,
                  showAdminCounts: true,
                  onTap: () => Get.to(() => EventDetailPage(event: event)),
                );
              },
            ),
    );
  }
}
