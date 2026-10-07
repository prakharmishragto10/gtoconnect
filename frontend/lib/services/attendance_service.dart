import 'api.dart';

class AttendanceService {
  /// Time left until today's 6:30 PM IST automatic check-out, or null once it
  /// has passed. The server does the check-out; screens use this to refresh.
  static Duration? untilAutoCheckout() {
    final ist = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final cutoff = DateTime.utc(ist.year, ist.month, ist.day, 18, 30);
    final left = cutoff.difference(ist);
    return left.isNegative ? null : left;
  }

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

  // ── Month calendar: check-ins plus absent / weekly-off days ───────────
  // Returns { days: [...], summary: {...}, joining_date }.
  static Future<Map<String, dynamic>> getMyCalendar(int month, int year) {
    return Api.get('/api/attendance/my/calendar?month=$month&year=$year');
  }

  static Future<Map<String, dynamic>> getEmployeeCalendar(
    String userId,
    int month,
    int year,
  ) {
    return Api.get(
      '/api/attendance/employee/$userId/calendar?month=$month&year=$year',
    );
  }

  // ── Admin override: mark an employee present on a date (yyyy-MM-dd) ────
  static Future<void> markPresent(String userId, String date) async {
    await Api.post(
      '/api/attendance/mark-present',
      body: {'userId': userId, 'date': date},
    );
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
