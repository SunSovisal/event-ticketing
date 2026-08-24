import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class ViewTicketPage extends StatelessWidget {
  const ViewTicketPage({
    super.key,
    required this.event,
    required this.ticketId,
  });

  final Event event;
  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Your Ticket', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ticket ID: $ticketId',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TicketRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: EventDate.formatShort(event.startsAt),
                    ),
                    const SizedBox(height: 16),
                    _TicketRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: event.locationLabel,
                    ),
                    const Divider(height: 32),
                    Container(
                      height: 260,
                      width: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 200),
                          Text(
                            'Scan at Entrance',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton(
            onPressed: () => Get.to(() => MainShell()),
            child: const Text('Back to Events'),
          ),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
