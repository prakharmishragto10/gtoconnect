import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api.dart';
import 'location_service.dart';

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

  // ── Re-read the signed-in user from the server ────────────────────────
  // The copy saved at login goes stale if an admin edits the account or
  // changes its role. Falls back to the saved copy when offline.
  static Future<UserModel?> refreshCurrentUser() async {
    try {
      final data = await Api.get(
        '/api/auth/me',
      ).timeout(const Duration(seconds: 6));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data['user']));
      return UserModel.fromJson(data['user']);
    } catch (_) {
      return getCurrentUser();
    }
  }

  // ── Check if logged in ────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // ── Logout ────────────────────────────────────────────
  static Future<void> logout() async {
    // Tracking runs on a static timer, so it must be stopped here or it keeps
    // posting under whoever signs in next on this device.
    LocationService.stopTracking();
    await Api.clearToken();
  }

  static Future<Map<String, dynamic>> createEmployee({
    required String name,
    required String email,
    required String password,
    String? designation,
    String? location,
    String? upiId,
    num? baseSalary,
    DateTime? joiningDate,
  }) async {
    final data = await Api.post(
      '/api/auth/signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (designation != null && designation.isNotEmpty)
          'designation': designation,
        if (location != null && location.isNotEmpty) 'location': location,
        if (upiId != null && upiId.isNotEmpty) 'upi_id': upiId,
        'base_salary': ?baseSalary,
        if (joiningDate != null)
          'joining_date': joiningDate.toIso8601String().split('T')[0],
      },
    );
    return data;
  }

  /// With [date] (yyyy-MM-dd) each employee also carries `is_working_day`,
  /// false when that date is their weekly off.
  static Future<List<dynamic>> getEmployees({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final data = await Api.get('/api/auth/employees$query');
    return data['users'] ?? [];
  }

  static Future<void> deleteEmployee(String userId) async {
    await Api.delete('/api/auth/employees/$userId');
  }

  static Future<Map<String, dynamic>> updateEmployee(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final data = await Api.patch('/api/auth/employees/$userId', body: fields);
    return data;
  }
}
