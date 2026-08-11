// all http in one place
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:itc_events/app/config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

// feature code (health, events, tickets) call this
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // reused for every request
  final http.Client _client;

  // Join base URL from [AppConfig] with a path like `/health`.
  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .get(_uri(path), headers: _jsonHeaders(headers))
        .timeout(AppConfig.requestTimeout);
    return _decodeJsonResponse(response);
  }

  // standard headers
  Map<String, String> _jsonHeaders(Map<String, String>? extra) {
    return {'Accept': 'application/json', ...?extra};
  }

  // GET request expecting a JSON object response
  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body ?? <String, dynamic>{};
    }
    // match Laravel error shape
    final error = body?['error'];
    final message = error is Map
        ? (error['message'] as String? ?? 'Request failed')
        : 'Request failed (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }

  // practice clean code
  void dispose() {
    _client.close();
  }
}
