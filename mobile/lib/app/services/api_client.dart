// all http in one place
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itc_events/app/config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.fields});
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? fields;

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
    String? idToken,
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .get(_uri(path), headers: _jsonHeaders(headers, idToken: idToken))
        .timeout(AppConfig.requestTimeout);
    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? idToken,
    Map<String, String>? header,
  }) async {
    final response = await _client
        .patch(
          _uri(path),
          headers: _jsonHeaders(header, idToken: idToken),
          body: jsonEncode(body),
        )
        .timeout(AppConfig.requestTimeout);
    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? idToken,
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _jsonHeaders(headers, idToken: idToken),
          body: jsonEncode(body),
        )
        .timeout(AppConfig.requestTimeout);

    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? idToken,
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .delete(_uri(path), headers: _jsonHeaders(headers, idToken: idToken))
        .timeout(AppConfig.requestTimeout);
    return _decodeJsonResponse(response);
  }

  // standard headers
  Map<String, String> _jsonHeaders(
    Map<String, String>? extra, {
    String? idToken,
  }) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
      ...?extra,
    };
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
    var message = 'Request failed ${response.statusCode}';
    String? code;
    Map<String, dynamic>? fields;
    if (error is Map) {
      message = error['message'] as String? ?? message;
      code = error['code'] as String?;
      final rawFields = error['fields'];
      if (rawFields is Map<String, dynamic>) {
        fields = rawFields;
      }
    } else if (body?['message'] is String) {
      message = body!['message'] as String;
    }
    throw ApiException(
      message,
      statusCode: response.statusCode,
      code: code,
      fields: fields,
    );
  }

  // practice clean code
  void dispose() {
    _client.close();
  }
}
