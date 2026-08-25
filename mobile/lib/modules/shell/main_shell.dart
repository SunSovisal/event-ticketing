import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/profile_page.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/home_page.dart';
import 'package:itc_events/modules/tickets/my_tickets_page.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';

void openMainShell({int index = 0}) {
  Get.offAll(() => MainShell(initialIndex: index));
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    if (!Get.isRegistered<EventController>()) {
      Get.put(EventController(apiClient: Get.find<ApiClient>()));
    } else {
      Get.find<EventController>().fetchEvents();
    }
    if (!Get.isRegistered<TicketController>()) {
      Get.put(TicketController(apiClient: Get.find<ApiClient>()));
    } else {
      Get.find<TicketController>().fetchTickets();
    }
    Get.find<AuthController>().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), MyTicketsPage(), ProfilePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(
              Icons.confirmation_number,
              color: AppTheme.primary,
            ),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
