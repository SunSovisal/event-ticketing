import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/auth/sign_in_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppSnackbar.error('Please enter your email address');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      AppSnackbar.error('Please enter a valid email address');
      return;
    }

    await _auth.forgotPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Forgot password?',
      subtitle:
          'Enter your email address and we will send you a link to reset your password.',
      showBack: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Remember your password?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => Get.off(() => const SignInPage()),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleForgotPassword(),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            if (_auth.errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(message: _auth.errorMessage.value),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _auth.isLoading.value ? null : _handleForgotPassword,
              child: _auth.isLoading.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send reset email'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _auth.isLoading.value
                  ? null
                  : () => Get.off(() => const SignInPage()),
              child: const Text('Back to sign in'),
            ),
          ],
        );
      }),
    );
  }
}
