import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/modules/auth/auth_linking.dart';
import 'package:itc_events/modules/chat/chat_controller.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class AuthController {
  AuthController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.firebaseWebClientId.isEmpty
        ? null
        : AppConfig.firebaseWebClientId,
  );

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> me = Rxn<Map<String, dynamic>>();

  final RxString phoneVerificationId = ''.obs;
  final RxBool phoneCodeSent = false.obs;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isAdmin => me.value?['is_admin'] == true;

  /// Campus admin address. It is not a real inbox, so it cannot confirm a link.
  static const skippedVerificationEmail = 'admin@itc.edu.kh';

  /// Email/password accounts stay out of the app until Firebase marks the
  /// address verified. Google and phone sign-in are already verified.
  bool get needsEmailVerification {
    final user = currentUser;
    if (user == null || user.emailVerified) return false;
    if (_skipsEmailVerification(user.email)) return false;

    final providers = user.providerData.map((info) => info.providerId).toSet();
    if (providers.contains('google.com') || providers.contains('phone')) {
      return false;
    }

    return providers.contains('password');
  }

  bool _skipsEmailVerification(String? email) {
    return email?.trim().toLowerCase() == skippedVerificationEmail;
  }

  /// Clears [errorMessage] after the current frame so Obx listeners are not
  /// marked dirty mid-build (e.g. Register → Sign in via Get.off).
  void clearErrorMessage() {
    if (errorMessage.value.isEmpty) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      errorMessage.value = '';
    });
  }

  /// Provider IDs currently linked to the signed-in Firebase account
  List<String> get linkedProviderIds =>
      currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

  /// Email used to detect a mismatch when linking Google or email/password.
  String? get accountEmailForLinking {
    String? passwordEmail;
    for (final info in currentUser?.providerData ?? const <UserInfo>[]) {
      if (info.providerId == 'password') {
        passwordEmail = info.email;
        break;
      }
    }
    return resolveAccountEmailForLinking(
      passwordProviderEmail: passwordEmail,
      firebaseEmail: currentUser?.email,
      profileEmail: me.value?['email']?.toString(),
    );
  }

  Future<bool> _confirmEmailMismatch({
    required String? incomingEmail,
    required Future<bool> Function(String accountEmail, String incomingEmail)?
    confirmDifferentEmail,
  }) async {
    final accountEmail = accountEmailForLinking;
    if (!emailsDifferForLinking(accountEmail, incomingEmail)) {
      return true;
    }
    if (confirmDifferentEmail == null) {
      return false;
    }
    isLoading.value = false;
    return confirmDifferentEmail(accountEmail!, incomingEmail!.trim());
  }

  Future<void> _completeProviderLink() async {
    await currentUser!.reload();
    await currentUser!.getIdToken(true);
    await fetchMe();
  }

  Future<void> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      await _sendEmailVerificationIfNeeded();
      await currentUser?.reload();
      if (needsEmailVerification) {
        return;
      }
      await currentUser?.getIdToken(true);
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'registration_failed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await currentUser?.reload();
      if (needsEmailVerification) {
        return;
      }
      await currentUser?.getIdToken(true);
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(error, fallback: 'sign_in_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'google_sign_in_failed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPhoneCode(String phoneNumber) async {
    isLoading.value = true;
    errorMessage.value = '';
    phoneCodeSent.value = false;
    phoneVerificationId.value = '';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithCredential(credential);
            await fetchMe();
          } catch (error) {
            errorMessage.value = _messageFor(
              error,
              fallback: 'auto_phone_verify_failed'.tr,
            );
          } finally {
            isLoading.value = false;
          }
        },
        verificationFailed: (error) {
          log("Firebase Auth Error Code: ${error.code}");
          log("Firebase Auth Error Message: ${error.message}");

          errorMessage.value = _messageFor(
            error,
            fallback: 'could_not_send_code'.tr,
          );
          isLoading.value = false;
        },
        codeSent: (verificationId, resendToken) {
          phoneVerificationId.value = verificationId;
          phoneCodeSent.value = true;
          isLoading.value = false;
        },
        codeAutoRetrievalTimeout: (verificationId) {
          phoneVerificationId.value = verificationId;
          isLoading.value = false;
        },
      );
    } catch (error) {
      if (error is FirebaseAuthException) {
        errorMessage.value = _messageFor(
          error,
          fallback: 'could_not_start_phone_verify'.tr,
        );
        isLoading.value = false;
      }
    }
  }

  Future<void> confirmPhoneCode(String smsCode) async {
    if (phoneVerificationId.value.isEmpty) {
      errorMessage.value = 'request_code_first'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: phoneVerificationId.value,
        smsCode: smsCode.trim(),
      );

      await _auth.signInWithCredential(credential);
      await fetchMe();

      phoneVerificationId.value = '';
      phoneCodeSent.value = false;
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'invalid_verification_code'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return currentUser?.getIdToken(forceRefresh);
  }

  Future<void> restoreSession() async {
    final user = currentUser;
    if (user == null || me.value != null) return;
    try {
      await user.reload();
      if (needsEmailVerification) {
        await _auth.signOut();
        me.value = null;
        return;
      }
      await fetchMe();
    } catch (_) {
      // Profile stays in the signed-out layout until the user signs in again.
    }
  }

  Future<void> fetchMe() async {
    // Fresh token for /me so Laravel always gets the latest Firebase ID token.
    final token = await getIdToken(forceRefresh: true);
    if (token == null) {
      throw ApiException('Not signed in', statusCode: 401);
    }

    final response = await _apiClient.getJson('/me', idToken: token);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      me.value = data;
      return;
    }
    throw ApiException('Unexpected /me response');
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? studentId,
    String? department,
    int? year,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final token = await getIdToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final body = <String, dynamic>{
        'name': name.trim(),
        'student_id': _blankToNull(studentId),
        'department': _blankToNull(department),
        'year': year,
      };
      final trimmedEmail = email?.trim();
      if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
        body['email'] = trimmedEmail;
      }

      final response = await _apiClient.patchJson(
        '/me',
        idToken: token,
        body: body,
      );

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        me.value = data;
      } else {
        throw ApiException('Unexpected /me response');
      }
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'could_not_update_profile'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendEmailVerificationIfNeeded() async {
    final user = currentUser;
    if (user == null ||
        user.emailVerified ||
        user.email == null ||
        _skipsEmailVerification(user.email)) {
      return;
    }

    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Sign-in already succeeded. The address stays unverified until this send works.
    }
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> signOut({bool openShell = true}) async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    me.value = null;
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().clearChat();
    }
    if (openShell) {
      openMainShell();
    }
  }

  Future<void> resendVerificationEmail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await currentUser?.reload();
      final user = currentUser;
      if (user == null || user.emailVerified) {
        return;
      }
      await user.sendEmailVerification();
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'could_not_send_verification'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Links the Google provider to the currently signed-in Firebase account.
  ///
  /// When the Google email differs from the account email, [confirmDifferentEmail]
  /// must return true before the link is applied (policy: allow, but warn).
  Future<void> linkWithGoogle({
    Future<bool> Function(String accountEmail, String googleEmail)?
    confirmDifferentEmail,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final confirmed = await _confirmEmailMismatch(
        incomingEmail: googleUser.email,
        confirmDifferentEmail: confirmDifferentEmail,
      );
      if (!confirmed) {
        await _googleSignIn.signOut();
        return;
      }
      isLoading.value = true;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await currentUser!.linkWithCredential(credential);
      await _completeProviderLink();
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _messageFor(e, fallback: 'could_not_link_google'.tr);
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'could_not_link_google'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Links email/password to the currently signed-in Firebase account.
  Future<void> linkWithEmailPassword({
    required String email,
    required String password,
    Future<bool> Function(String accountEmail, String newEmail)?
    confirmDifferentEmail,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final confirmed = await _confirmEmailMismatch(
        incomingEmail: email,
        confirmDifferentEmail: confirmDifferentEmail,
      );
      if (!confirmed) {
        return;
      }
      isLoading.value = true;

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await currentUser!.linkWithCredential(credential);
      await currentUser!.reload();
      await _sendEmailVerificationIfNeeded();
      await _completeProviderLink();
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _messageFor(e, fallback: 'could_not_link_email'.tr);
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'could_not_link_email'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends an SMS verification code for linking a phone number.
  /// Mirrors sendPhoneCode() but uses linkWithCredential() on auto-retrieval.
  Future<void> sendPhoneLinkCode(String phoneNumber) async {
    isLoading.value = true;
    errorMessage.value = '';
    phoneCodeSent.value = false;
    phoneVerificationId.value = '';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await currentUser!.linkWithCredential(credential);
            await _completeProviderLink();
          } catch (error) {
            errorMessage.value = _messageFor(
              error,
              fallback: 'auto_phone_link_failed'.tr,
            );
          } finally {
            isLoading.value = false;
          }
        },
        verificationFailed: (error) {
          errorMessage.value = _messageFor(
            error,
            fallback: 'could_not_send_code'.tr,
          );
          isLoading.value = false;
        },
        codeSent: (verificationId, resendToken) {
          phoneVerificationId.value = verificationId;
          phoneCodeSent.value = true;
          isLoading.value = false;
        },
        codeAutoRetrievalTimeout: (verificationId) {
          phoneVerificationId.value = verificationId;
          isLoading.value = false;
        },
      );
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'could_not_start_phone_link'.tr,
      );
      isLoading.value = false;
    }
  }

  /// Confirms the SMS code and completes phone-provider linking.
  Future<void> confirmPhoneLinkCode(String smsCode) async {
    if (phoneVerificationId.value.isEmpty) {
      errorMessage.value = 'request_code_first'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: phoneVerificationId.value,
        smsCode: smsCode.trim(),
      );

      await currentUser!.linkWithCredential(credential);
      await _completeProviderLink();

      phoneVerificationId.value = '';
      phoneCodeSent.value = false;
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'invalid_verification_code'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetPhoneVerification() {
    errorMessage.value = '';
    phoneCodeSent.value = false;
    phoneVerificationId.value = '';
  }

  String _messageFor(Object error, {required String fallback}) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'provider-already-linked':
          return 'provider_already_linked'.tr;
        case 'credential-already-in-use':
        case 'email-already-in-use':
          return 'credential_already_in_use'.tr;
        case 'weak-password':
          return 'password_min_8'.tr;
        case 'requires-recent-login':
          return 'requires_recent_login'.tr;
        case 'invalid-email':
          return 'enter_valid_email'.tr;
        default:
          return error.message ?? fallback;
      }
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      AppSnackbar.success(
        'password_reset_sent'.trParams({'email': email.trim()}),
      );
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _messageFor(e, fallback: 'could_not_send_reset'.tr);

      AppSnackbar.error(errorMessage.value);
    } catch (error) {
      errorMessage.value = error.toString();

      AppSnackbar.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}
