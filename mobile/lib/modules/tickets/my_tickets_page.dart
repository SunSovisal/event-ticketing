import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/ticket.dart';
import 'package:itc_events/modules/tickets/view_ticket_page.dart';

// Standalone dummy data generator for local testing
List<Event> _getMockEvents() {
  return [
    Event(
      id: '1',
      title: 'Flutter Forward Conference 2026',
      description: 'Annual Flutter developer gathering.',
      startsAt: DateTime(2026, 10, 15, 9, 0),
      locationLabel: 'Hall A, Main Campus',
      capacity: 200,
      spotsRemaining: 45,
      status: 'published',
    ),
    Event(
      id: '2',
      title: 'Tech Expo & Hackathon',
      description: 'Showcase your tech projects.',
      startsAt: DateTime(2026, 11, 2, 10, 30),
      locationLabel: 'Auditorium 2',
      capacity: 150,
      spotsRemaining: 0,
      status: 'published',
    ),
  ];
}

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final _apiClient = Get.find<ApiClient>();
  final _auth = Get.find<AuthController>();
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();
  }

 
  Future<void> _fetchMyTickets() async {
  try {
    // 1. Retrieve the authentication token
    final token = await _auth.getIdToken();
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. Make backend API request
    final response = await _apiClient.getJson('/tickets', idToken: token);
    
    // 3. Extract tickets list safely
    final List data = response['data'] ?? [];

    // 4. Update state with parsed Event objects
    if (mounted) {
      setState(() {
        _tickets = data
    .where((item) => item['event'] != null)
    .map<Ticket>(
      (item) => Ticket.fromJson(
        item as Map<String, dynamic>,
      ),
    )
    .toList();
        _isLoading = false;
      });
    }
  } catch (e) {
    // Handle error & turn off loader
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'My tickets',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${_tickets.length} upcoming · tap for QR at entrance',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tickets.isEmpty
                ? const Center(child: Text('No upcoming tickets found.'))
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    return _TicketCard(ticket: _tickets[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  Event get event => ticket.event;

  // Simple date formatter (e.g., "15/10/2026 09:00")
  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
  onTap: () {
    Get.to(
      () => ViewTicketPage(
        event: event,
        ticketId: ticket.id,
      ),
    );
  },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPCOMING',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '${_formatDate(event.startsAt)} · ${event.locationLabel}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
