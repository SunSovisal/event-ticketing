import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/auth/sign_in/sign_in_page.dart';

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
    _auth.clearErrorMessage();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppSnackbar.error('please_enter_email_address'.tr);
      return;
    }

    if (!GetUtils.isEmail(email)) {
      AppSnackbar.error('please_enter_valid_email_address'.tr);
      return;
    }

    await _auth.forgotPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'forgot_password_title'.tr,
      subtitle: 'forgot_password_subtitle'.tr,
      showBack: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'remember_password_q'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => Get.off(() => const SignInPage()),
            child: Text('sign_in'.tr),
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
              decoration: InputDecoration(
                labelText: 'email'.tr,
                hintText: 'enter_your_email'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
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
                  : Text('send_reset_email'.tr),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _auth.isLoading.value
                  ? null
                  : () => Get.off(() => const SignInPage()),
              child: Text('back_to_sign_in'.tr),
            ),
          ],
        );
      }),
    );
  }
}
