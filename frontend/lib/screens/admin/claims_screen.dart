import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/reimbursement_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _claims = [];

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      final data = await ReimbursementService.getAllClaims();
      setState(() {
        _claims = data.map((c) => Map<String, dynamic>.from(c)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int index, String status) async {
    try {
      final claim = _claims[index];
      await ReimbursementService.updateStatus(claim['id'], status);
      setState(() => _claims[index]['status'] = status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claim $status',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: status == 'approved' ? kForest : kDanger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    final pending = _claims.where((c) => c['status'] == 'pending').toList();
    final approved = _claims.where((c) => c['status'] == 'approved').toList();
    final paid = _claims.where((c) => c['status'] == 'paid').toList();
    final rejected = _claims.where((c) => c['status'] == 'rejected').toList();
    final pendingTotal = pending.fold(
      0.0,
      (s, c) => s + (c['amount'] as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reimbursements',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          Text(
            'Review and approve claims',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
          const SizedBox(height: 16),

          // Summary
          Row(
            children: [
              _SummaryCard(
                label: 'Pending',
                value: '${pending.length}',
                sub: '₹${pendingTotal.toStringAsFixed(0)}',
                color: kWarn,
                bg: kWarnBg,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                label: 'Approved',
                value: '${approved.length}',
                sub: 'This month',
                color: kForest,
                bg: kSuccessBg,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                label: 'Paid',
                value: '${paid.length}',
                sub: 'This month',
                color: kDeepBlue,
                bg: kInfoBg,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (pending.isNotEmpty) ...[
            _SectionLabel('PENDING APPROVAL'),
            const SizedBox(height: 8),
            ...pending.asMap().entries.map(
              (e) => _ClaimCard(
                claim: e.value,
                onApprove: () =>
                    _updateStatus(_claims.indexOf(e.value), 'approved'),
                onReject: () =>
                    _updateStatus(_claims.indexOf(e.value), 'rejected'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (approved.isNotEmpty) ...[
            _SectionLabel('APPROVED'),
            const SizedBox(height: 8),
            ...approved.map((c) => _ClaimCard(claim: c)),
            const SizedBox(height: 16),
          ],

          if (paid.isNotEmpty) ...[
            _SectionLabel('PAID'),
            const SizedBox(height: 8),
            ...paid.map((c) => _ClaimCard(claim: c)),
            const SizedBox(height: 16),
          ],

          if (rejected.isNotEmpty) ...[
            _SectionLabel('REJECTED'),
            const SizedBox(height: 8),
            ...rejected.map((c) => _ClaimCard(claim: c)),
          ],

          if (_claims.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No claims yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: kTealGray,
      letterSpacing: 1.2,
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final Color color, bg;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  const _ClaimCard({required this.claim, this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    final status = claim['status'] as String;
    final submitter = claim['submitter'] as Map<String, dynamic>?;
    final name = submitter?['name'] ?? 'Unknown';
    final amount = (claim['amount'] as num).toDouble();
    final date = (claim['created_at'] as String).substring(0, 10);

    Color sc = status == 'pending'
        ? kWarn
        : status == 'approved'
        ? kForest
        : status == 'paid'
        ? kDeepBlue
        : kDanger;
    Color sb = status == 'pending'
        ? kWarnBg
        : status == 'approved'
        ? kSuccessBg
        : status == 'paid'
        ? kInfoBg
        : kDangerBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kInfoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDeepBlue,
                      ),
                    ),
                    Text(
                      '${claim['category']} · $date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: kTealGray,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: sc,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (claim['description'] != null) ...[
            const SizedBox(height: 6),
            Text(
              claim['description'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kTealGray,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (claim['receipt_url'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kOffWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 12, color: kTealGray),
                  const SizedBox(width: 4),
                  Text(
                    'Receipt attached',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kTealGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final url = claim['receipt_url'] as String;
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Text(
                      'View',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: kDeepBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onApprove != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDanger,
                      side: const BorderSide(color: kDanger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kForest,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
