import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          decoration: InputDecoration(
            labelText: 'student_id_optional'.tr,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue:
              department != null && kCampusDepartments.contains(department)
              ? department
              : '',
          decoration: InputDecoration(
            labelText: 'department_optional'.tr,
            prefixIcon: const Icon(Icons.apartment_outlined),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text('not_set'.tr),
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
          decoration: InputDecoration(
            labelText: 'year_optional'.tr,
            prefixIcon: const Icon(Icons.school_outlined),
          ),
          items: [
            DropdownMenuItem<int>(
              value: 0,
              child: Text('not_set'.tr),
            ),
            ...kCampusYears.map(
              (value) => DropdownMenuItem<int>(
                value: value,
                child: Text('year_n'.trParams({'year': '$value'})),
              ),
            ),
          ],
          onChanged: (value) => onYearChanged(value == 0 ? null : value),
        ),
      ],
    );
  }
}
