import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/auth/profile/widgets/campus_profile_fields.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  late final AuthController _auth;
  String? _department;
  int? _year;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    final me = _auth.me.value;
    _nameController.text = me?['name']?.toString() ?? '';
    _emailController.text = me?['email']?.toString() ?? '';
    _studentIdController.text = me?['student_id']?.toString() ?? '';
    _department = me?['department']?.toString();
    _year = _yearFrom(me?['year']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _auth.errorMessage.value = 'enter_your_name'.tr;
      return;
    }

    if (name.length > 120) {
      _auth.errorMessage.value = 'name_max_120'.tr;
      return;
    }

    await _auth.updateProfile(
      name: name,
      studentId: _studentIdController.text,
      department: _department,
      year: _year,
    );

    if (_auth.errorMessage.value.isEmpty &&
        _auth.me.value?['name']?.toString().isNotEmpty == true) {
      openMainShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthPageLayout(
        title: 'complete_profile_title'.tr,
        subtitle: 'complete_profile_subtitle'.tr,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'full_name'.tr,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              if (_emailController.text.trim().isNotEmpty) ...[
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'email'.tr,
                    helperText: 'email_from_sign_in'.tr,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CampusProfileFields(
                studentIdController: _studentIdController,
                department: _department,
                year: _year,
                onDepartmentChanged: (value) =>
                    setState(() => _department = value),
                onYearChanged: (value) => setState(() => _year = value),
              ),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_auth.errorMessage.value.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: _auth.errorMessage.value),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _auth.isLoading.value ? null : _saveProfile,
                      child: _auth.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('continue'.tr),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

int? _yearFrom(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
