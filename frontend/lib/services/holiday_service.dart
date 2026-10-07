import 'api.dart';

/// Company holidays. A holiday on an employee's working day is a paid day
/// off: salary and attendance never count it as an absence.
class HolidayService {
  /// Holidays in a month, oldest first. Each has `id`, `date` (yyyy-MM-dd)
  /// and `name`.
  static Future<List<Map<String, dynamic>>> getHolidays(
    int month,
    int year,
  ) async {
    final data = await Api.get('/api/holidays?month=$month&year=$year');
    final list = data['holidays'] as List? ?? [];
    return list.map((h) => Map<String, dynamic>.from(h as Map)).toList();
  }

  // Admin only
  static Future<void> addHoliday(String date, String name) async {
    await Api.post('/api/holidays', body: {'date': date, 'name': name});
  }

  // Admin only
  static Future<void> deleteHoliday(String id) async {
    await Api.delete('/api/holidays/$id');
  }
}
