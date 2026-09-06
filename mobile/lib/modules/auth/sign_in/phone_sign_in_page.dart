import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/profile/complete_profile_page.dart';
import 'package:itc_events/modules/auth/widgets/auth_page_layout.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class PhoneSignInPage extends StatefulWidget {
  // Set linkMode to true when the user is already signed in and wants to
  // link a phone number to their existing Firebase account.
  const PhoneSignInPage({super.key, this.linkMode = false});

  final bool linkMode;

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
    _auth.clearErrorMessage();
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
      _auth.errorMessage.value = 'enter_complete_phone'.tr;
      return;
    }

    if (widget.linkMode) {
      await _auth.sendPhoneLinkCode(phone);
    } else {
      await _auth.sendPhoneCode(phone);
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _auth.errorMessage.value = 'enter_six_digit_code'.tr;
      return;
    }

    if (widget.linkMode) {
      await _auth.confirmPhoneLinkCode(code);
      if (_auth.errorMessage.value.isEmpty && mounted) {
        Get.back(); // return to ProfilePage
      }
      return;
    }

    // -- original sign-in path 
    // read name after fetchMe() to get value from DB
    await _auth.confirmPhoneCode(code);
    if (_auth.isSignedIn && _auth.me.value != null) {
      final name = _auth.me.value?['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        Get.offAll(() => const CompleteProfilePage());
      } else {
        openMainShell();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: widget.linkMode ? 'link_phone_number'.tr : 'phone_sign_in'.tr,
      subtitle: widget.linkMode
          ? 'phone_link_subtitle'.tr
          : 'phone_sign_in_subtitle'.tr,
      footer: TextButton(
        onPressed: () {
          _auth.resetPhoneVerification();
          Get.back();
        },
        child: Text(widget.linkMode ? 'cancel'.tr : 'back_to_sign_in'.tr),
      ),
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
                labelText: 'phone_number'.tr,
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
                  labelText: 'verification_code'.tr,
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
                          ? 'verify_and_sign_in'.tr
                          : 'send_code'.tr,
                    ),
            ),
            if (_auth.phoneCodeSent.value)
              TextButton(
                onPressed: _auth.isLoading.value ? null : _sendCode,
                child: Text('resend_code'.tr),
              ),
          ],
        );
      }),
    );
  }
}
