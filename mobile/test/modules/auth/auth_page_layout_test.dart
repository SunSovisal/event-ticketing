import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

void main() {
  testWidgets('auth error banner displays its message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthErrorBanner(message: 'Sign-in failed'),
        ),
      ),
    );

    expect(find.text('Sign-in failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}