import 'api.dart';

class SalaryService {
  static Future<Map<String, dynamic>?> getMySalary(int month, int year) async {
    final data = await Api.get('/api/salary/my?month=$month&year=$year');
    return data['salary'];
  }

  static Future<List<dynamic>> getMyHistory() async {
    final data = await Api.get('/api/salary/my/history');
    return data['salaries'] ?? [];
  }

  static Future<List<dynamic>> getAllSalaries(int month, int year) async {
    final data = await Api.get('/api/salary/all?month=$month&year=$year');
    return data['salaries'] ?? [];
  }

  static Future<Map<String, dynamic>> getSummary(int month, int year) async {
    final data = await Api.get('/api/salary/summary?month=$month&year=$year');
    return data['summary'];
  }

  static Future<void> generate(int month, int year) async {
    await Api.post(
      '/api/salary/generate',
      body: {'month': month, 'year': year},
    );
  }

  static Future<void> markPaid(String salaryId) async {
    await Api.patch('/api/salary/$salaryId/paid');
  }
}
