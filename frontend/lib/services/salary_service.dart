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

  /// Net pay through payroll: base salary minus the absence deduction.
  static double netOf(Map<dynamic, dynamic> record) {
    final base = (record['base_salary'] as num?)?.toDouble() ?? 0;
    final deduction = (record['deduction'] as num?)?.toDouble() ?? 0;
    return base - deduction;
  }

  // ── Salary slips ──────────────────────────────────────────────────────────
  static Future<void> uploadSlip(
    String salaryId,
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    await Api.uploadFile(
      '/api/salary/$salaryId/slip',
      bytes,
      fileName,
      mimeType,
      field: 'slip',
    );
  }

  /// Short-lived link to the slip. Staff can open any; employees only theirs.
  static Future<String> getSlipUrl(String salaryId) async {
    final data = await Api.get('/api/salary/$salaryId/slip');
    return data['url'] as String;
  }
}
