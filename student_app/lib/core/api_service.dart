import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static String? authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? params]) {
    final base = '${AppConstants.apiBaseUrl}$endpoint';
    if (params != null && params.isNotEmpty) {
      final query = params.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse(query.isNotEmpty ? '$base?$query' : base);
    }
    return Uri.parse(base);
  }

  static Future<dynamic> get(String endpoint, {Map<String, dynamic>? params}) async {
    final uri = _buildUri(endpoint, params);
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  static Future<dynamic> getAuth(String endpoint, {Map<String, dynamic>? params}) async {
    return get(endpoint, params: params);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = _buildUri(endpoint);
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Future<dynamic> postAuth(String endpoint, Map<String, dynamic> body) async {
    return post(endpoint, body);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = _buildUri(endpoint);
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static dynamic _processResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (json is Map<String, dynamic>) {
          return {
            'status': json['status'] ?? 'success',
            'data': json['data'] ?? json,
            'message': json['message'] ?? 'Success',
            ...json,
          };
        }
        return {'status': 'success', 'data': json};
      } else {
        final msg = json is Map ? (json['message'] ?? 'API Request Failed') : 'API Request Failed';
        return {'status': 'error', 'message': msg};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Invalid response: $e'};
    }
  }
}
