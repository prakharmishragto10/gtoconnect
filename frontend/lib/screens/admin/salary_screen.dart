import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/salary_service.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  bool _loading = true;
  List<dynamic> _salaries = [];
  Map<String, dynamic> _summary = {};

  late int _month;
  late int _year;

  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final salaries = await SalaryService.getAllSalaries(_month, _year);
      final summary = await SalaryService.getSummary(_month, _year);
      setState(() {
        _salaries = salaries;
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markPaid(int index) async {
    try {
      final salary = _salaries[index];
      await SalaryService.markPaid(salary['id']);
      setState(() => _salaries[index]['status'] = 'paid');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Salary marked as paid',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: kForest,
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

  Future<void> _generateSalary() async {
    setState(() => _loading = true);
    try {
      await SalaryService.generate(_month, _year);
      await _loadData();
    } catch (e) {
      setState(() => _loading = false);
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

    final monthLabel = '${_monthNames[_month]} $_year';
    final gross = (_summary['gross'] as num?)?.toDouble() ?? 0;
    final reimb = (_summary['reimbursements'] as num?)?.toDouble() ?? 0;
    final net = (_summary['net'] as num?)?.toDouble() ?? 0;
    final paid = (_summary['paid'] as num?)?.toInt() ?? 0;
    final pend = (_summary['pending'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salary Management',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTealGray,
                    ),
                  ),
                ],
              ),
              if (_salaries.isEmpty)
                GestureDetector(
                  onTap: _generateSalary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: kDeepBlue,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Generate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_salaries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 48,
                      color: kBlueGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No salary records for $monthLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kTealGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap Generate to create payroll',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: kBlueGray,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Payroll summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kDeepBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PayrollRow(
                    'Gross Salaries',
                    '₹${gross.toStringAsFixed(0)}',
                    Colors.white,
                    false,
                  ),
                  _PayrollRow(
                    'Reimbursements',
                    '+ ₹${reimb.toStringAsFixed(0)}',
                    const Color(0xFF9FE1CB),
                    false,
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  _PayrollRow(
                    'Net Payable',
                    '₹${gross.toStringAsFixed(0)}',
                    Colors.white,
                    true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusChip('$paid Paid', kForest),
                      const SizedBox(width: 8),
                      _StatusChip('$pend Pending', kWarn),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'INDIVIDUAL SALARIES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kTealGray,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            ..._salaries.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final user = s['users'] as Map<String, dynamic>?;
              final name = user?['name'] ?? 'Unknown';
              final isPaid = s['status'] == 'paid';
              final sNet = (s['net_salary'] as num).toDouble();
              final sBase = (s['base_salary'] as num).toDouble();
              final sReimb = (s['reimbursements'] as num).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kInfoBg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              name.substring(0, 1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kDeepBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kDeepBlue,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${sBase.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kDeepBlue,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid ? kSuccessBg : kWarnBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s['status'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isPaid ? kForest : kWarn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kOffWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BreakdownItem(
                            'Gross',
                            '₹${sBase.toStringAsFixed(0)}',
                            kDeepBlue,
                          ),
                          _BreakdownItem(
                            'Reimb',
                            '₹${sReimb.toStringAsFixed(0)}',
                            kForest,
                          ),
                          _BreakdownItem(
                            'Net',
                            '₹${sBase.toStringAsFixed(0)}',
                            kDeepBlue,
                          ),
                        ],
                      ),
                    ),
                    if (!isPaid) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markPaid(i),
                          icon: const Icon(Icons.send, size: 14),
                          label: Text(
                            'Mark as Paid',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDeepBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PayrollRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _PayrollRow(this.label, this.value, this.color, this.bold);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: bold ? 16 : 13,
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _BreakdownItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTealGray),
        ),
      ],
    );
  }
}
