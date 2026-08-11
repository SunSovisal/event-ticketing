class AppConfig {
  AppConfig._();

  // mac+ios : 127.0.0.1
  // window+andriod : 10.0.2.2
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // 
  static const Duration requestTimeout = Duration(seconds: 15);
}