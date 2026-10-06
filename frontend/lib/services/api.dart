import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../core/env.dart';

class Api {
  static const String baseUrl = Env.baseUrl;

  /// Called when the server rejects the stored token (expired, or the account
  /// was removed). The app uses it to return to the login screen.
  static void Function()? onUnauthorized;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Without a timeout a dropped connection leaves screens on a spinner forever
  static Future<http.Response> _send(
    Future<http.Response> request, {
    int seconds = 30,
  }) async {
    try {
      return await request.timeout(Duration(seconds: seconds));
    } on TimeoutException {
      throw Exception('The server took too long to respond. Please try again.');
    } on http.ClientException {
      throw Exception(
        'Could not reach the server. Check your internet connection.',
      );
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await _send(
      http.get(Uri.parse('$baseUrl$endpoint'), headers: await _headers()),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _send(
      http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _send(
      http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final res = await _send(
      http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _headers()),
    );
    return _handle(res);
  }

  static Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = {'data': decoded};
      }
    } catch (_) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {};
      }
      throw Exception('Server error (${res.statusCode}): ${res.reasonPhrase ?? "Unexpected error"}');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    // A 401 from login just means wrong credentials; anywhere else the
    // session is no longer valid.
    final isLogin = res.request?.url.path.endsWith('/api/auth/login') ?? false;
    if (res.statusCode == 401 && !isLogin) {
      onUnauthorized?.call();
      throw Exception('Session expired. Please sign in again.');
    }
    throw Exception(data['error'] ?? 'Something went wrong (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    List<int> fileBytes,
    String fileName,
    String mimeType, {
    String field = 'receipt',
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        field,
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final res = await _send(
      request.send().then(http.Response.fromStream),
      seconds: 90,
    );
    return _handle(res);
  }
}
