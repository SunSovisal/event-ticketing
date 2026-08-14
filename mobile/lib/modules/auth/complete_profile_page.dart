import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/profile_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveNameEmail() async {
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

    await _auth.updateNameEmail(name, email);

    if (_auth.errorMessage.value.isEmpty &&
        _auth.me.value?['name']?.toString().isNotEmpty == true && _auth.me.value?['email']?.toString().isNotEmpty == true) {
      Get.offAll(() => const ProfilePage());
    }
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthPageLayout(
        title: 'Complete your profile',
        subtitle: 'Enter the name that will appear on your tickets.',
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveNameEmail(),
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16,),
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveNameEmail(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (_auth.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: _auth.errorMessage.value),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _auth.isLoading.value ? null : _saveNameEmail,
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
      ),
    );
  }
}