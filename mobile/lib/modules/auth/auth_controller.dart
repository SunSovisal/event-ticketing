import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/services/api_client.dart';

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

  /// Provider IDs currently linked to the signed-in Firebase account
  List<String> get linkedProviderIds =>
      currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

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
      await credential.user?.getIdToken(true);
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(error, fallback: 'Registration failed');
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
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(error, fallback: 'Sign-in failed');
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
        fallback: 'Google sign-in failed',
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
              fallback: 'Automatic phone verification failed',
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
            fallback: 'Could not send verification code',
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
          fallback: 'Could not start phone verification',
        );
        isLoading.value = false;
      }
    }
  }

  Future<void> confirmPhoneCode(String smsCode) async {
    if (phoneVerificationId.value.isEmpty) {
      errorMessage.value = 'Request a verification code first';
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
        fallback: 'Invalid verification code',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return currentUser?.getIdToken(forceRefresh);
  }

  Future<void> restoreSession() async {
    if (currentUser == null || me.value != null) return;
    try {
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

  Future<void> updateNameEmail(String name, String email) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final token = await getIdToken();
      if (token == null) {
        throw ApiException('Not signed in', statusCode: 401);
      }

      final response = await _apiClient.patchJson(
        '/me',
        idToken: token,
        body: {'name': name.trim(), 'email': email.trim()},
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
        fallback: 'Could not update name',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    me.value = null;
  }

  // Provider linking
  /// Links the Google provider to the currently signed-in Firebase account.
  Future<void> linkWithGoogle() async {
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
      await currentUser!.linkWithCredential(credential);
      await currentUser!.reload();
      await currentUser!.getIdToken(
        true,
      ); // force fresh token with updated claims
      await fetchMe(); // sync new claims to the database now
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _messageFor(e, fallback: 'Could not link Google');
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'Could not link Google',
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
            await currentUser!.reload();
            await currentUser!.getIdToken(
              true,
            ); // force fresh token with updated claims
            await fetchMe(); // sync new claims to the database now
          } catch (error) {
            errorMessage.value = _messageFor(
              error,
              fallback: 'Automatic phone linking failed',
            );
          } finally {
            isLoading.value = false;
          }
        },
        verificationFailed: (error) {
          errorMessage.value = _messageFor(
            error,
            fallback: 'Could not send verification code',
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
        fallback: 'Could not start phone linking',
      );
      isLoading.value = false;
    }
  }

  /// Confirms the SMS code and completes phone-provider linking.
  Future<void> confirmPhoneLinkCode(String smsCode) async {
    if (phoneVerificationId.value.isEmpty) {
      errorMessage.value = 'Request a verification code first';
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
      await currentUser!.reload();
      await currentUser!.getIdToken(
        true,
      ); // force fresh token with updated claims
      await fetchMe(); // sync new claims to the database now

      phoneVerificationId.value = '';
      phoneCodeSent.value = false;
    } catch (error) {
      errorMessage.value = _messageFor(
        error,
        fallback: 'Invalid verification code',
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
      return error.message ?? fallback;
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
