import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/salary_service.dart';

class EmpSalary extends StatefulWidget {
  final UserModel user;
  const EmpSalary({super.key, required this.user});

  @override
  State<EmpSalary> createState() => _EmpSalaryState();
}

class _EmpSalaryState extends State<EmpSalary> {
  bool _loading = true;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _salaries = [];

  @override
  void initState() {
    super.initState();
    _loadSalaries();
  }

  Future<void> _loadSalaries() async {
    try {
      final data = await SalaryService.getMyHistory();
      setState(() {
        _salaries = data.map((s) => Map<String, dynamic>.from(s)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _monthName(int m) {
    const months = [
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
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    if (_salaries.isEmpty) {
      return Center(
        child: Text(
          'No salary records yet',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTealGray),
        ),
      );
    }

    final selected = _salaries[_selectedIndex];
    final isPaid = selected['status'] == 'paid';
    final base = (selected['base_salary'] as num).toDouble();
    final reimb = (selected['reimbursements'] as num).toDouble();
    final net = (selected['net_salary'] as num).toDouble();
    final month = _monthName(selected['month'] as int);
    final year = selected['year'].toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          Text(
            'Your monthly breakdown',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
          const SizedBox(height: 16),

          // Month selector
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _salaries.length,
              itemBuilder: (_, i) {
                final s = _salaries[i];
                final isSelected = i == _selectedIndex;
                final label = '${_monthName(s['month'] as int)} ${s['year']}';
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? kDeepBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? kDeepBlue : kBorder,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : kTealGray,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kDeepBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$month $year',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kBlueGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? kForest
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Pending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Net Take-Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: kBlueGray,
                  ),
                ),
                Text(
                  '₹${net.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown
          Text(
            'SALARY BREAKDOWN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                _BreakdownRow(
                  label: 'Base Salary',
                  value: '₹${base.toStringAsFixed(0)}',
                  valueColor: kDeepBlue,
                  icon: Icons.work_outline,
                ),
                const Divider(height: 20, color: kBorder),
                _BreakdownRow(
                  label: 'Reimbursements',
                  value: '+ ₹${reimb.toStringAsFixed(0)}',
                  valueColor: kForest,
                  icon: Icons.receipt_outlined,
                ),
                const Divider(height: 20, color: kBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Payable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                    Text(
                      '₹${net.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // History
          Text(
            'PAYMENT HISTORY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          ..._salaries.map((s) {
            final isPaidS = s['status'] == 'paid';
            final netS = (s['net_salary'] as num).toDouble();
            final monthS = _monthName(s['month'] as int);
            final yearS = s['year'].toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPaidS ? kSuccessBg : kWarnBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isPaidS ? Icons.check_circle_outline : Icons.schedule,
                      size: 18,
                      color: isPaidS ? kForest : kWarn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$monthS $yearS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kDeepBlue,
                          ),
                        ),
                        Text(
                          isPaidS && s['paid_at'] != null
                              ? 'Paid on ${(s['paid_at'] as String).substring(0, 10)}'
                              : 'Payment pending',
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
                        '₹${netS.toStringAsFixed(0)}',
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
                          color: isPaidS ? kSuccessBg : kWarnBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s['status'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isPaidS ? kForest : kWarn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final IconData icon;
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kOffWhite,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: kTealGray),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: kTealGray,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
