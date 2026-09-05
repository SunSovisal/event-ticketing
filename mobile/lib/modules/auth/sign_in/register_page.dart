import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/sign_in/sign_in_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _auth.clearErrorMessage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _auth.errorMessage.value = 'Please enter your name.';
      return;
    }
    if (email.isEmpty) {
      _auth.errorMessage.value = 'Please enter your email.';
      return;
    }
    if (password.length < 6) {
      _auth.errorMessage.value = 'Password must be at least 6 characters.';
      return;
    }

    await _auth.registerWithEmail(name, email, password);
    if (_auth.isSignedIn && _auth.me.value != null) {
      openMainShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Create account',
      subtitle: 'Join GoITC to discover and book tickets.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => Get.off(() => SignInPage()),
            child: Text('Sign in'),
          ),
        ],
      ),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                helperText: 'At least 6 characters',
              ),
            ),
            if (_auth.errorMessage.value.isNotEmpty) ...[
              SizedBox(height: 16),
              AuthErrorBanner(message: _auth.errorMessage.value),
            ],
            SizedBox(height: 24),
            FilledButton(
              onPressed: _auth.isLoading.value ? null : _handleRegister,
              child: _auth.isLoading.value
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Create account'),
            ),
          ],
        );
      }),
    );
  }
}
