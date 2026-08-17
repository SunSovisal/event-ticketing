import 'package:flutter/material.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My tickets')),
      body: const EmptyStateView(
        icon: Icons.confirmation_number_outlined,
        message: 'Your tickets will show up here after you reserve a place.',
      ),
    );
  }
}
