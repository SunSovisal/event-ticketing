class AppConfig {
  AppConfig._();

  // mac+ios : 127.0.0.1
  // window+andriod : 10.0.2.2
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://127.0.0.1:8000/api/v1',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Web OAuth client ID (Firebase Console → Authentication → Google → Web client ID).
  /// Required on Android for Google Sign-In tokens Laravel can verify.
  static const String firebaseWebClientId = String.fromEnvironment(
    'FIREBASE_WEB_CLIENT_ID',
    defaultValue:
        '674255742143-da251k5gdgdp4pf5a3cf8bh5s2tpc39j.apps.googleusercontent.com',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
