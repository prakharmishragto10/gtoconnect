import 'api.dart';

class AttendanceService {
  // ── Check In ──────────────────────────────────────────
  static Future<Map<String, dynamic>> checkIn() async {
    final data = await Api.post('/api/attendance/checkin');
    return data['attendance'];
  }

  // ── Check Out ─────────────────────────────────────────
  static Future<Map<String, dynamic>> checkOut() async {
    final data = await Api.post('/api/attendance/checkout');
    return data['attendance'];
  }

  // ── Today's status ────────────────────────────────────
  static Future<Map<String, dynamic>?> getToday() async {
    final data = await Api.get('/api/attendance/today');
    return data['attendance'];
  }

  // ── My history ────────────────────────────────────────
  static Future<List<dynamic>> getMyHistory() async {
    final data = await Api.get('/api/attendance/my');
    return data['attendance'] ?? [];
  }

  // ── All today (admin) ─────────────────────────────────
  static Future<List<dynamic>> getAllToday() async {
    final data = await Api.get('/api/attendance/all');
    return data['attendance'] ?? [];
  }

  // ── Monthly report (admin) ────────────────────────────
  static Future<List<dynamic>> getReport(int month, int year) async {
    final data = await Api.get(
      '/api/attendance/report?month=$month&year=$year',
    );
    return data['attendance'] ?? [];
  }
}
