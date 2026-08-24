import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/view_ticket_page.dart';

class ConfirmTicketPage extends StatelessWidget {
  const ConfirmTicketPage({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              // Green Check Circle
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FADF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF12B76A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "You're in!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'Your ticket for '),
                    TextSpan(
                      text: event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const TextSpan(text: ' is ready. Show the QR at the entrance.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Dashed Ticket Stub Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      EventDate.formatShort(event.startsAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Navigation Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigate to View Ticket or Ticket List
                    Get.to(() => ViewTicketPage(event: event, ticketId: 'TKT_01JABC123XYZ'));
                  },
                  child: const Text(
                    'View my ticket',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}