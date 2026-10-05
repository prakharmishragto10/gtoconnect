import 'package:flutter/material.dart';
import 'api.dart';

class TravelService {
  // ── Employee ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submit({
    required String place,
    required String startDate,
    required String endDate,
    required String work,
    required String reason,
  }) async {
    return await Api.post('/api/travel', body: {
      'place': place,
      'start_date': startDate,
      'end_date': endDate,
      'work': work,
      'reason': reason,
    });
  }

  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    final res = await Api.get('/api/travel/my');
    final list = res['travels'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllRequests({
    String? status,
  }) async {
    final query = status != null ? '?status=$status' : '';
    final res = await Api.get('/api/travel/all$query');
    final list = res['travels'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    await Api.patch('/api/travel/$id/status', body: {'status': status});
  }
}

// ── Status badge helper ────────────────────────────────────────────────────────

class TravelStatusBadge extends StatelessWidget {
  final String status;
  const TravelStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon, String label) = switch (status) {
      'approved' => (
          const Color(0xFFEBF4EE),
          const Color(0xFF326A44),
          Icons.check_circle_outline,
          'Approved',
        ),
      'rejected' => (
          const Color(0xFFFAF0F0),
          const Color(0xFF8B2E2E),
          Icons.cancel_outlined,
          'Rejected',
        ),
      _ => (
          const Color(0xFFFBF4E6),
          const Color(0xFF7A5C1E),
          Icons.schedule,
          'Pending',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
