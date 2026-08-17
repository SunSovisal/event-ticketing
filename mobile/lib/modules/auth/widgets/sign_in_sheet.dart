import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/phone_sign_in_page.dart';
import 'package:itc_events/modules/auth/register_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

/// Presents sign-in as a dismissible sheet so guests can return to event detail.
Future<bool> showSignInSheet(BuildContext context) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: const SignInSheet(),
    ),
  );

  return signedIn ?? false;
}

class SignInSheet extends StatefulWidget {
  const SignInSheet({super.key});

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _auth.errorMessage.value = '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _completeSignIn() async {
    if (_auth.isSignedIn && _auth.me.value != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleEmailSignIn() async {
    await _auth.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );
    await _completeSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to reserve',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Use your ITC account to hold a free ticket.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleEmailSignIn(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                if (_auth.errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: _auth.errorMessage.value),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _auth.isLoading.value ? null : _handleEmailSignIn,
                  child: _auth.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign in & reserve'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _auth.isLoading.value
                      ? null
                      : () async {
                          await _auth.signInWithGoogle();
                          await _completeSignIn();
                        },
                  icon: Image.asset(
                    'assets/google_logo.jpeg',
                    height: 26,
                    width: 26,
                  ),
                  label: const Text('Google'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _auth.isLoading.value
                      ? null
                      : () {
                          _auth.resetPhoneVerification();
                          Navigator.pop(context);
                          Get.to(() => const PhoneSignInPage());
                        },
                  icon: const Icon(Icons.phone),
                  label: const Text('Phone / SMS'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue browsing'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.to(() => const RegisterPage());
                  },
                  child: const Text('Create account'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
