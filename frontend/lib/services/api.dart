import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000';

  // ── Get stored token ──────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── Save token ────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ── Clear token ───────────────────────────────────────
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ── Headers with auth ─────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  // ── POST ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  // ── PATCH ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  // ── Response handler ──────────────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Something went wrong');
  }
}
