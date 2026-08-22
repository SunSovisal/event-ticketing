import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/auth/widgets/campus_profile_fields.dart';
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
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      _auth.errorMessage.value = 'Enter your name';
      return;
    }

    if (name.length > 120) {
      _auth.errorMessage.value = 'Name cannot exceed 120 characters';
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _auth.errorMessage.value = 'Enter a valid email';
      return;
    }

    await _auth.updateProfile(
      name: name,
      email: email,
      studentId: _studentIdController.text,
      department: _department,
      year: _year,
    );

    if (_auth.errorMessage.value.isEmpty &&
        _auth.me.value?['name']?.toString().isNotEmpty == true &&
        _auth.me.value?['email']?.toString().isNotEmpty == true) {
      openMainShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthPageLayout(
        title: 'Complete your profile',
        subtitle: 'Enter the name that will appear on your tickets. Campus details are optional.',
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
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
                          : const Text('Continue'),
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
