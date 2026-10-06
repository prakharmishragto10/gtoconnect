import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/salary_service.dart';
import 'employee_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  bool _loading = true;
  List<dynamic> _salaries = [];
  Map<String, dynamic> _summary = {};
  String? _loadError;

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
    final month = _month;
    final year = _year;
    try {
      final salaries = await SalaryService.getAllSalaries(month, year);
      final summary = await SalaryService.getSummary(month, year);
      // Ignore the answer if the admin moved to another month meanwhile
      if (!mounted || month != _month || year != _year) return;
      setState(() {
        _salaries = salaries;
        _summary = summary;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _changeMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    setState(() {
      _month = m;
      _year = y;
      _salaries = [];
      _summary = {};
      _loadError = null;
      _loading = true;
    });
    _loadData();
  }

  Future<void> _markPaid(int index) async {
    try {
      final salary = _salaries[index];
      await SalaryService.markPaid(salary['id']);
      await _loadData();
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

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Id of the salary record whose slip is being uploaded or opened
  String? _slipBusyId;

  static const _slipMimeTypes = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };

  Future<void> _uploadSlip(String salaryId) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _slipMimeTypes.keys.toList(),
    );
    if (picked.isEmpty || !mounted) return;
    final file = picked.first;

    final mime = _slipMimeTypes[(file.extension ?? '').toLowerCase()];
    if (mime == null) {
      _snack('Choose a PDF, JPG or PNG file', kDanger);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 4 * 1024 * 1024) {
      _snack('Salary slip must be under 4 MB', kDanger);
      return;
    }

    setState(() => _slipBusyId = salaryId);
    try {
      await SalaryService.uploadSlip(salaryId, bytes, file.name, mime);
      await _loadData();
      _snack('Salary slip uploaded', kForest);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }
    if (mounted) setState(() => _slipBusyId = null);
  }

  Future<void> _viewSlip(String salaryId) async {
    try {
      final url = await SalaryService.getSlipUrl(salaryId);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) _snack('Could not open the salary slip', kDanger);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }
  }

  Future<void> _generateSalary() async {
    setState(() => _loading = true);
    try {
      await SalaryService.generate(_month, _year);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    // Salaries are final, and payable, only once the month is over. The
    // server enforces this and recalculates from the full month on payment.
    final payableFrom = DateTime(_year, _month + 1, 1);
    final monthOver = !DateTime.now().isBefore(payableFrom);
    final gross = (_summary['gross'] as num?)?.toDouble() ?? 0;
    final reimb = (_summary['reimbursements'] as num?)?.toDouble() ?? 0;
    final deductions = (_summary['deductions'] as num?)?.toDouble() ?? 0;
    final net = (_summary['net'] as num?)?.toDouble() ?? gross;
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _changeMonth(-1),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: kDeepBlue,
                          ),
                        ),
                      ),
                      Text(
                        monthLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTealGray,
                        ),
                      ),
                      InkWell(
                        onTap: () => _changeMonth(1),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: kDeepBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Shown for existing payroll too: it adds new employees and
              // refreshes unpaid records, and never changes paid ones.
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
                      _salaries.isEmpty ? 'Generate' : 'Refresh',
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
                      _loadError != null
                          ? 'Could not load salaries'
                          : 'No salary records for $monthLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _loadError != null ? kDanger : kTealGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError ?? 'Tap Generate to create payroll',
                      textAlign: TextAlign.center,
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
                    'Absence deductions',
                    '− ₹${deductions.toStringAsFixed(0)}',
                    const Color(0xFFF5B7A8),
                    false,
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  _PayrollRow(
                    'Net Payable',
                    '₹${net.toStringAsFixed(0)}',
                    Colors.white,
                    true,
                  ),
                  _PayrollRow(
                    'Claims (paid separately)',
                    '₹${reimb.toStringAsFixed(0)}',
                    const Color(0xFF9FE1CB),
                    false,
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
              final sBase = (s['base_salary'] as num).toDouble();
              final sReimb = (s['reimbursements'] as num).toDouble();
              final sDeduction = (s['deduction'] as num?)?.toDouble() ?? 0;
              final sNet = SalaryService.netOf(s as Map);
              // Null on records generated before absences were tracked
              final workingDays = s['working_days'] as num?;
              final paidDays = s['paid_days'] as num?;
              final absentDays = s['absent_days'] as num?;
              final salaryId = s['id'].toString();
              final hasSlip = s['slip_path'] != null;
              final slipBusy = _slipBusyId == salaryId;
              // Joined part-way through this month: days before are unpaid
              final joined = DateTime.tryParse(
                (user?['joining_date'] ?? '').toString(),
              );
              final joinedThisMonth =
                  joined != null &&
                  joined.year == _year &&
                  joined.month == _month &&
                  joined.day > 1;

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
                              '₹${sNet.toStringAsFixed(0)}',
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
                            'Base',
                            '₹${sBase.toStringAsFixed(0)}',
                            kDeepBlue,
                          ),
                          _BreakdownItem(
                            'Absent',
                            absentDays == null ? '—' : '${absentDays}d',
                            kDanger,
                          ),
                          _BreakdownItem(
                            'Deduction',
                            '− ₹${sDeduction.toStringAsFixed(0)}',
                            kDanger,
                          ),
                          _BreakdownItem(
                            'Net',
                            '₹${sNet.toStringAsFixed(0)}',
                            kForest,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if (joinedThisMonth)
                                'Joined ${joined.day} ${_monthNames[_month]}',
                              if (workingDays != null)
                                'Paid ${paidDays ?? 0} of $workingDays working days',
                              if (sReimb > 0)
                                'Claims ₹${sReimb.toStringAsFixed(0)} paid separately',
                            ].join(' · '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: kTealGray,
                            ),
                          ),
                        ),
                        // Opens the day-by-day list with the absent dates
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeeHistoryScreen(
                                employeeId: s['user_id'].toString(),
                                employeeName: name.toString(),
                                initialMonth: _month,
                                initialYear: _year,
                              ),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: kDeepBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View absences',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: slipBusy
                                ? null
                                : () => _uploadSlip(salaryId),
                            icon: slipBusy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kDeepBlue,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_outlined,
                                    size: 16,
                                  ),
                            label: Text(
                              hasSlip ? 'Replace slip' : 'Upload slip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kDeepBlue,
                              side: const BorderSide(color: kBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                        if (hasSlip) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _viewSlip(salaryId),
                              icon: const Icon(
                                Icons.description_outlined,
                                size: 16,
                              ),
                              label: Text(
                                'View slip',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kForest,
                                side: const BorderSide(color: kForest),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isPaid) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: monthOver ? () => _markPaid(i) : null,
                          icon: Icon(
                            monthOver ? Icons.send : Icons.lock_clock_outlined,
                            size: 14,
                          ),
                          label: Text(
                            monthOver
                                ? 'Mark as Paid'
                                : 'Payable from 1 ${_monthNames[payableFrom.month]}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDeepBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: kOffWhite,
                            disabledForegroundColor: kTealGray,
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
