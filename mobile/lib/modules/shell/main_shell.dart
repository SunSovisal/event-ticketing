import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/profile/profile_page.dart';
import 'package:itc_events/modules/auth/sign_in/sign_in_page.dart';
import 'package:itc_events/modules/chat/chat_binding.dart';
import 'package:itc_events/modules/chat/chat_page.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/home_page.dart';
import 'package:itc_events/modules/health/health_binding.dart';
import 'package:itc_events/modules/health/health_page.dart';
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
      Get.put(
        EventController(apiClient: Get.find<ApiClient>(), fetchOnStart: false),
      );
    }
    if (!Get.isRegistered<TicketController>()) {
      Get.put(
        TicketController(apiClient: Get.find<ApiClient>(), fetchOnStart: true),
      );
    }

    final auth = Get.find<AuthController>();
    if (auth.isSignedIn && auth.me.value == null) {
      auth.restoreSession();
    } else {
      Get.find<EventController>().fetchEvents();
    }
  }

  void _openChat() {
    final auth = Get.find<AuthController>();
    if (!auth.isSignedIn) {
      AppSnackbar.warning('chat_sign_in_required'.tr);
      Get.to(() => const SignInPage());
      return;
    }

    Get.to(() => const ChatPage(), binding: ChatBinding());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), MyTicketsPage(), ProfilePage()],
      ),
      floatingActionButton: Obx(() {
        final auth = Get.find<AuthController>();
        // Always read Rx so Obx has an observer (avoid `&&` short-circuit).
        final isAdmin = auth.me.value?['is_admin'] == true;
        final showHealth = _index == 2 && isAdmin;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showHealth) ...[
              FloatingActionButton.small(
                heroTag: 'health_fab',
                tooltip: 'GoITC',
                onPressed: () {
                  Get.to(() => HealthPage(), binding: HealthBinding());
                },
                child: const Icon(Icons.network_check),
              ),
              const SizedBox(height: 12),
            ],
            FloatingActionButton(
              heroTag: 'chat_fab',
              tooltip: 'chat_title'.tr,
              onPressed: _openChat,
              child: const Icon(Icons.smart_toy_outlined),
            ),
          ],
        );
      }),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppTheme.primary),
            label: 'nav_home'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(
              Icons.confirmation_number,
              color: AppTheme.primary,
            ),
            label: 'nav_tickets'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: AppTheme.primary),
            label: 'nav_profile'.tr,
          ),
        ],
      ),
    );
  }
}
