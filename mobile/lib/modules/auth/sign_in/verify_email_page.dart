import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/sign_in/sign_in_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late final AuthController _auth;
  bool _resent = false;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _auth.clearErrorMessage();
  }

  Future<void> _resend() async {
    setState(() => _resent = false);
    await _auth.resendVerificationEmail();
    if (_auth.errorMessage.value.isEmpty && mounted) {
      setState(() => _resent = true);
    }
  }

  Future<void> _goToSignIn() async {
    if (_auth.isSignedIn) {
      await _auth.signOut(openShell: false);
    }
    Get.off(() => const SignInPage());
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'verify_email_title'.tr,
      subtitle: 'verify_email_subtitle'.trParams({'email': widget.email}),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_resent && _auth.errorMessage.value.isEmpty) ...[
              Text(
                'verification_sent'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (_auth.errorMessage.value.isNotEmpty) ...[
              AuthErrorBanner(message: _auth.errorMessage.value),
              const SizedBox(height: 16),
            ],
            if (_auth.isSignedIn) ...[
              OutlinedButton(
                onPressed: _auth.isLoading.value ? null : _resend,
                child: Text('resend_verification'.tr),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _auth.isLoading.value ? null : _goToSignIn,
              child: _auth.isLoading.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('sign_in'.tr),
            ),
          ],
        );
      }),
    );
  }
}
