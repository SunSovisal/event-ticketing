import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/events/event.dart';

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
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();
  }

  Future<void> _fetchMyTickets() async {
    // Simulate brief network delay for testing loading states
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _events = _getMockEvents();
        _isLoading = false;
      });
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
              '${_events.length} upcoming · swipe for QR at entrance',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _events.isEmpty
                ? const Center(child: Text('No upcoming tickets found.'))
                : InkWell(
                    onTap: () {},
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        return _TicketCard(event: _events[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.event});

  final Event event;

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
    return Container(
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
    );
  }
}
