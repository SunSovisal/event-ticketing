import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itc_events/app/services/api_client.dart';

class AuthController {
  AuthController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> me = Rxn<Map<String, dynamic>>();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isAdmin => me.value?['is_admin'] == true;

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
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      await fetchMe();
    } catch (error) {
      errorMessage.value = _messageFor(error, fallback: 'Google sign-in failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getIdToken() async {
    return currentUser?.getIdToken();
  }

  Future<void> fetchMe() async {
    final token = await getIdToken();
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

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    me.value = null;
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
