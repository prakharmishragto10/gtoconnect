import 'api.dart';

class AttendanceService {
  // ── Check In ──────────────────────────────────────────
  static Future<Map<String, dynamic>> checkIn({
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final data = await Api.post(
      '/api/attendance/checkin',
      body: body.isNotEmpty ? body : null,
    );
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
  static Future<List<dynamic>> getMyHistory({
    String? date,
    int? month,
    int? year,
  }) async {
    final params = <String>[];
    if (date != null && date.isNotEmpty) params.add('date=$date');
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await Api.get('/api/attendance/my$query');
    return data['attendance'] ?? [];
  }

  // ── All / Filtered by date, month, year (admin) ─────────
  static Future<List<dynamic>> getAllToday({
    String? date,
    int? month,
    int? year,
  }) async {
    final params = <String>[];
    if (date != null && date.isNotEmpty) params.add('date=$date');
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await Api.get('/api/attendance/all$query');
    return data['attendance'] ?? [];
  }

  // ── Monthly report (admin) ────────────────────────────
  static Future<List<dynamic>> getReport(int month, int year) async {
    final data = await Api.get(
      '/api/attendance/report?month=$month&year=$year',
    );
    return data['attendance'] ?? [];
  }

  // ── All history (admin) ───────────────────────────────
  static Future<List<dynamic>> getAllHistory() async {
    final data = await Api.get('/api/attendance/all-history');
    return data['attendance'] ?? [];
  }

  // ── Employee specific history (admin) ─────────────────
  static Future<List<dynamic>> getEmployeeHistory(
    String userId, {
    String? date,
    int? month,
    int? year,
  }) async {
    final params = <String>[];
    if (date != null && date.isNotEmpty) params.add('date=$date');
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await Api.get('/api/attendance/employee/$userId$query');
    return data['attendance'] ?? [];
  }
}
