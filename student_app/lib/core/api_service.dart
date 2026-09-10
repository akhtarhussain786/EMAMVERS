import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Thrown when the server rejects the session. The app shell listens for this
/// via [ApiService.onUnauthorized] and returns the user to the login screen.
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Your session has expired. Please sign in again.']);
  @override
  String toString() => message;
}

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _accountTypeKey = 'account_type';

  static String? authToken;
  static const Duration timeoutDuration = Duration(seconds: 20);

  /// Invoked when any request comes back 401 so the shell can sign the user out.
  static void Function()? onUnauthorized;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // ── Session persistence ────────────────────────────────────────────────
  // The token used to live only in this static field, so every cold start
  // forced a fresh login regardless of the "Remember me" setting.

  /// Restores a stored token. Returns true when a session was resumed.
  /// Account type of the restored session ('student' or 'teacher').
  static String accountType = 'student';

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tokenKey);
    if (stored == null || stored.isEmpty) return false;
    authToken = stored;
    accountType = prefs.getString(_accountTypeKey) ?? 'student';
    return true;
  }

  /// Stores the token when [remember] is set, otherwise keeps it in memory only.
  static Future<void> setSession(String? token, {bool remember = true, String type = 'student'}) async {
    authToken = token;
    accountType = type;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty && remember) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_accountTypeKey, type);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_accountTypeKey);
    }
  }

  static Future<void> clearSession() async {
    authToken = null;
    accountType = 'student';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accountTypeKey);
  }

  // ── Requests ───────────────────────────────────────────────────────────

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? params]) {
    final base = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    if (params == null || params.isEmpty) return base;

    final query = <String, String>{...base.queryParameters};
    params.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isEmpty) return;
      query[key] = text;
    });
    return base.replace(queryParameters: query.isEmpty ? null : query);
  }

  static Future<dynamic> get(String endpoint, {Map<String, dynamic>? params}) =>
      _send(() => http.get(_buildUri(endpoint, params), headers: _headers));

  static Future<dynamic> getAuth(String endpoint, {Map<String, dynamic>? params}) =>
      get(endpoint, params: params);

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) =>
      _send(() => http.post(_buildUri(endpoint), headers: _headers, body: jsonEncode(body)));

  static Future<dynamic> postAuth(String endpoint, Map<String, dynamic> body) =>
      post(endpoint, body);

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) =>
      _send(() => http.put(_buildUri(endpoint), headers: _headers, body: jsonEncode(body)));

  static Future<dynamic> delete(String endpoint) =>
      _send(() => http.delete(_buildUri(endpoint), headers: _headers));

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeoutDuration);
    } on TimeoutException {
      throw Exception('Server connection timed out. Check your connection and try again.');
    } on SocketException {
      throw Exception('Cannot reach the EXAMVERSE server. Check your network connection.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
    return _processResponse(response);
  }

  /// Unwraps the standard `{status, message, data, errors}` envelope.
  ///
  /// Always returns `data` when the envelope is present — including when it is
  /// a List — so callers get one predictable shape instead of sometimes
  /// receiving the raw envelope.
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      final message = _messageFrom(response.body) ?? 'Your session has expired. Please sign in again.';
      onUnauthorized?.call();
      throw UnauthorizedException(message);
    }

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      throw Exception('Server returned ${response.statusCode} with an empty body.');
    }

    final dynamic json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Invalid response from server (HTTP ${response.statusCode}).');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json is Map<String, dynamic> && json.containsKey('data') && json.containsKey('status')) {
        return json['data'];
      }
      return json;
    }

    throw Exception(_messageFrom(response.body) ?? 'Request failed (HTTP ${response.statusCode}).');
  }

  static String? _messageFrom(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String && (decoded['message'] as String).isNotEmpty) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Non-JSON error body; fall through to the caller's default.
    }
    return null;
  }
}
