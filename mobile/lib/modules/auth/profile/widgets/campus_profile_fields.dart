import 'package:flutter/material.dart';

const kCampusDepartments = <String>[
  'GIC',
  'GEE',
  'GCA',
  'GGG',
  'GIM',
  'GTR',
  'GRU',
  'AMS',
  'GTI',
  'Foundation',
];

const kCampusYears = <int>[1, 2, 3, 4, 5];

/// Student ID, department, and year — stored on `user_profiles`.
class CampusProfileFields extends StatelessWidget {
  const CampusProfileFields({
    super.key,
    required this.studentIdController,
    required this.department,
    required this.year,
    required this.onDepartmentChanged,
    required this.onYearChanged,
  });

  final TextEditingController studentIdController;
  final String? department;
  final int? year;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: studentIdController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Student ID (optional)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue:
              department != null && kCampusDepartments.contains(department)
              ? department
              : '',
          decoration: const InputDecoration(
            labelText: 'Department (optional)',
            prefixIcon: Icon(Icons.apartment_outlined),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Not set'),
            ),
            ...kCampusDepartments.map(
              (code) => DropdownMenuItem<String>(
                value: code,
                child: Text(code),
              ),
            ),
          ],
          onChanged: (value) =>
              onDepartmentChanged(value == null || value.isEmpty ? null : value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: year != null && kCampusYears.contains(year) ? year : 0,
          decoration: const InputDecoration(
            labelText: 'Year (optional)',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: 0,
              child: Text('Not set'),
            ),
            ...kCampusYears.map(
              (value) => DropdownMenuItem<int>(
                value: value,
                child: Text('Year $value'),
              ),
            ),
          ],
          onChanged: (value) => onYearChanged(value == 0 ? null : value),
        ),
      ],
    );
  }
}
