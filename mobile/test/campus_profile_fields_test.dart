import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/auth/profile/widgets/campus_profile_fields.dart';

void main() {
  testWidgets('CampusProfileFields shows optional campus inputs', (tester) async {
    final studentId = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusProfileFields(
            studentIdController: studentId,
            department: 'GIC',
            year: 3,
            onDepartmentChanged: (_) {},
            onYearChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Student ID (optional)'), findsOneWidget);
    expect(find.text('GIC'), findsOneWidget);
    expect(find.text('Year 3'), findsOneWidget);

    studentId.dispose();
  });
}
