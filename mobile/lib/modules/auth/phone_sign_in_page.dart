import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/complete_profile_page.dart';
import 'package:itc_events/modules/auth/profile_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  State<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final _phoneController = TextEditingController(text: '+855');
  final _codeController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();

    if (!phone.startsWith('+') || phone.length < 8) {
      _auth.errorMessage.value = 'Enter a complete phone number including +855';
      return;
    }

    await _auth.sendPhoneCode(phone);
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    final name = _auth.me.value?['name']?.toString().trim() ?? '';

    if (code.length != 6) {
      _auth.errorMessage.value = 'Enter the six-digit code';
      return;
    }

    await _auth.confirmPhoneCode(code);

    if (_auth.isSignedIn && _auth.me.value != null) {
      if (name.isEmpty) {
        Get.offAll(() => const CompleteProfilePage());
      } else {
        Get.offAll(() => const ProfilePage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Phone sign in',
      subtitle: 'Enter your phone number to receive a verification code.',
      footer: TextButton(onPressed: Get.back, child: Text('Back to sign in')),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              enabled: !_auth.phoneCodeSent.value && !_auth.isLoading.value,
              keyboardType: TextInputType.phone,
              autofillHints: [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+85512345678',
              ),
            ),
            if (_auth.phoneCodeSent.value) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: [AutofillHints.oneTimeCode],
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
            ],
            if (_auth.errorMessage.value.isNotEmpty) ...[
              SizedBox(height: 16),
              AuthErrorBanner(message: _auth.errorMessage.value),
            ],
            SizedBox(height: 24),
            FilledButton(
              onPressed: _auth.isLoading.value
                  ? null
                  : _auth.phoneCodeSent.value
                  ? _confirmCode
                  : _sendCode,
              child: _auth.isLoading.value
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _auth.phoneCodeSent.value
                          ? 'Verify and sign in'
                          : 'Send code',
                    ),
            ),
            if (_auth.phoneCodeSent.value)
              TextButton(
                onPressed: _auth.isLoading.value ? null : _sendCode,
                child: Text('Resend code'),
              ),
          ],
        );
      }),
    );
  }
}
