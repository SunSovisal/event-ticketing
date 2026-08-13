import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/profile_page.dart';
import 'package:itc_events/modules/auth/register_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    await _auth.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );
    if (_auth.isSignedIn && _auth.me.value != null) {
      Get.off(() => ProfilePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to browse events and manage your tickets.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('New here?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(
            onPressed: () => Get.off(() => RegisterPage()),
            child: Text('Create account'),
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
              onSubmitted: (_) => _handleEmailSignIn(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            if (_auth.errorMessage.value.isNotEmpty) ...[
              SizedBox(height: 16),
              AuthErrorBanner(message: _auth.errorMessage.value),
            ],
            SizedBox(height: 24),
            FilledButton(
              onPressed: _auth.isLoading.value ? null : _handleEmailSignIn,
              child: _auth.isLoading.value
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Sign in'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _auth.isLoading.value
                  ? null
                  : () async {
                      await _auth.signInWithGoogle();
                      if (_auth.isSignedIn && _auth.me.value != null) {
                        Get.off(() => ProfilePage());
                      }
                    },
              icon: Image.asset(
                'assets/google_logo.jpeg',
                height: 26,
                width: 26,
              ),
              label: Text('Continue with Google'),
            ),
          ],
        );
      }),
    );
  }
}
