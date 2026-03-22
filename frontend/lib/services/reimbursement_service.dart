import 'api.dart';

class ReimbursementService {
  static Future<List<dynamic>> getMyClaims() async {
    final data = await Api.get('/api/reimbursements/my');
    return data['reimbursements'] ?? [];
  }

  static Future<List<dynamic>> getAllClaims({String? status}) async {
    final url = status != null
        ? '/api/reimbursements/all?status=$status'
        : '/api/reimbursements/all';
    final data = await Api.get(url);
    return data['reimbursements'] ?? [];
  }

  static Future<Map<String, dynamic>> submitClaim({
    required String category,
    required double amount,
    required String description,
  }) async {
    final data = await Api.post(
      '/api/reimbursements',
      body: {
        'category': category,
        'amount': amount,
        'description': description,
      },
    );
    return data['reimbursement'];
  }

  static Future<Map<String, dynamic>> updateStatus(
    String claimId,
    String status,
  ) async {
    final data = await Api.patch(
      '/api/reimbursements/$claimId/status',
      body: {'status': status},
    );
    return data['reimbursement'];
  }

  static Future<Map<String, dynamic>> getPendingTotal() async {
    final data = await Api.get('/api/reimbursements/pending-total');
    return data;
  }
}
