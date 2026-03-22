import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api.dart';

class AuthService {
  static const _tokenKey = 'token';
  static const _userKey = 'user';

  // ── Login ─────────────────────────────────────────────
  static Future<UserModel> login(String email, String password) async {
    final data = await Api.post(
      '/api/auth/login',
      body: {'email': email.trim().toLowerCase(), 'password': password.trim()},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token']);
    await prefs.setString(_userKey, jsonEncode(data['user']));

    return UserModel.fromJson(data['user']);
  }

  // ── Get current user from local storage ───────────────
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return UserModel.fromJson(jsonDecode(userStr));
  }

  // ── Check if logged in ────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // ── Logout ────────────────────────────────────────────
  static Future<void> logout() async {
    await Api.clearToken();
  }

  static Future<List<dynamic>> getEmployees() async {
    final data = await Api.get('/api/auth/employees');
    return data['users'] ?? [];
  }
}
