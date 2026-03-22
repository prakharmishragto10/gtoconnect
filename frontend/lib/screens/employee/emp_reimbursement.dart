import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/reimbursement_service.dart';

class EmpReimbursement extends StatefulWidget {
  final UserModel user;
  const EmpReimbursement({super.key, required this.user});

  @override
  State<EmpReimbursement> createState() => _EmpReimbursementState();
}

class _EmpReimbursementState extends State<EmpReimbursement> {
  bool _showForm = false;
  bool _submitting = false;
  bool _loading = true;

  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Sales Travel';

  List<Map<String, dynamic>> _claims = [];

  final List<String> _categories = [
    'Sales Travel',
    'Sales Fuel',
    'Client Meals',
    'Accommodation',
    'Travel',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      final data = await ReimbursementService.getMyClaims();
      setState(() {
        _claims = data.map((c) => Map<String, dynamic>.from(c)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitClaim() async {
    if (_amountCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final claim = await ReimbursementService.submitClaim(
        category: _selectedCategory,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        description: _descCtrl.text,
      );
      setState(() {
        _claims.insert(0, Map<String, dynamic>.from(claim));
        _submitting = false;
        _showForm = false;
        _amountCtrl.clear();
        _descCtrl.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claim submitted successfully',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: kForest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      setState(() => _submitting = false);
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                    'March 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTealGray,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _showForm ? kOffWhite : kDeepBlue,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _showForm ? kBorder : kDeepBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showForm ? Icons.close : Icons.add,
                        size: 15,
                        color: _showForm ? kTealGray : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showForm ? 'Cancel' : 'New Claim',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showForm ? kTealGray : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          Row(
            children: [
              _MiniStat(
                label: 'Pending',
                value: '${pending.length}',
                sub: '₹${pendingTotal.toStringAsFixed(0)}',
                color: kWarn,
                bg: kWarnBg,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Approved',
                value: '${approved.length}',
                sub: 'This month',
                color: kForest,
                bg: kSuccessBg,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Paid',
                value: '${paid.length}',
                sub: 'This month',
                color: kDeepBlue,
                bg: kInfoBg,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Rejected',
                value: '${rejected.length}',
                sub: 'This month',
                color: kDanger,
                bg: kDangerBg,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // New claim form
          if (_showForm) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit New Claim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FormLabel('Category'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kOffWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kDeepBlue,
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _FormLabel('Amount (₹)'),
                  const SizedBox(height: 6),
                  _FormInput(
                    controller: _amountCtrl,
                    hint: 'e.g. 800',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  _FormLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: kDeepBlue,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Brief description of the expense...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: kBlueGray,
                      ),
                      filled: true,
                      fillColor: kOffWhite,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: kTealGray,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _FormLabel('Receipt'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: kOffWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.upload_file_outlined,
                          size: 28,
                          color: kBlueGray,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload receipt photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: kTealGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'JPG, PNG — max 5MB',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: kBlueGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeepBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Claim',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Claims list
          if (_claims.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No claims submitted yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              _SectionLabel('PENDING APPROVAL'),
              const SizedBox(height: 8),
              ...pending.map((c) => _ClaimCard(claim: c)),
              const SizedBox(height: 12),
            ],
            if (approved.isNotEmpty) ...[
              _SectionLabel('APPROVED'),
              const SizedBox(height: 8),
              ...approved.map((c) => _ClaimCard(claim: c)),
              const SizedBox(height: 12),
            ],
            if (paid.isNotEmpty) ...[
              _SectionLabel('PAID'),
              const SizedBox(height: 8),
              ...paid.map((c) => _ClaimCard(claim: c)),
              const SizedBox(height: 12),
            ],
            if (rejected.isNotEmpty) ...[
              _SectionLabel('REJECTED'),
              const SizedBox(height: 8),
              ...rejected.map((c) => _ClaimCard(claim: c)),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value, sub;
  final Color color, bg;
  const _MiniStat({
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: kTealGray,
      letterSpacing: 0.4,
    ),
  );
}

class _FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _FormInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kDeepBlue),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kBlueGray),
      filled: true,
      fillColor: kOffWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kTealGray, width: 1.5),
      ),
    ),
  );
}

class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final status = claim['status'] as String;
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

    final amount = (claim['amount'] as num).toDouble();
    final date = (claim['created_at'] as String).substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sb,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    status == 'paid'
                        ? Icons.check_circle_outline
                        : status == 'rejected'
                        ? Icons.cancel_outlined
                        : Icons.receipt_outlined,
                    size: 18,
                    color: sc,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim['category'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDeepBlue,
                        ),
                      ),
                      Text(
                        claim['description'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: kTealGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: kBlueGray,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
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
          ),
          if (claim['receipt_url'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kOffWhite,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
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
                  Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kDeepBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
