import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

enum EmpHistoryFilterMode { all, day, month, year }

class EmployeeHistoryScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  /// Month to open on. Defaults to the current month.
  final int? initialMonth;
  final int? initialYear;

  const EmployeeHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _history = [];

  // Opens on the month view: it is the one that lists absent and off days
  EmpHistoryFilterMode _filterMode = EmpHistoryFilterMode.month;
  DateTime _selectedDate = DateTime.now();
  late int _selectedMonth = widget.initialMonth ?? DateTime.now().month;
  late int _selectedYear = widget.initialYear ?? DateTime.now().year;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Only the admin may override attendance; sub-admins just view it
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    AuthService.getCurrentUser().then((user) {
      if (mounted) setState(() => _isAdmin = user?.isAdmin ?? false);
    });
    _loadHistory();
  }

  // Asks before overriding attendance. Returns true to go ahead.
  Future<bool> _confirmMarkPresent(String name, String dateLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark present?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: kDeepBlue,
            fontSize: 16,
          ),
        ),
        content: Text(
          '$name will be recorded as present on $dateLabel.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTealGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: kTealGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kForest,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mark present',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markPresent(DateTime date) async {
    final ok = await _confirmMarkPresent(
      widget.employeeName,
      DateFormat('d MMM yyyy').format(date),
    );
    if (!ok) return;
    try {
      await AttendanceService.markPresent(
        widget.employeeId,
        _formatDateYMD(date),
      );
      _toast('Marked present', kForest);
      await _loadHistory();
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), kDanger);
    }
  }

  // App-bar action: pick any past date (or today) and mark it present
  Future<void> _pickAndMarkPresent() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Mark present on',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kDeepBlue,
            onPrimary: Colors.white,
            onSurface: kDeepBlue,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) await _markPresent(picked);
  }

  String _formatDateYMD(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? date;
      int? month;
      int? year;

      if (_filterMode == EmpHistoryFilterMode.day) {
        date = _formatDateYMD(_selectedDate);
      } else if (_filterMode == EmpHistoryFilterMode.month) {
        month = _selectedMonth;
        year = _selectedYear;
      } else if (_filterMode == EmpHistoryFilterMode.year) {
        year = _selectedYear;
      }

      final List<dynamic> data;
      if (_filterMode == EmpHistoryFilterMode.month) {
        // Month view includes the days with no check-in (absent / weekly off)
        final calendar = await AttendanceService.getEmployeeCalendar(
          widget.employeeId,
          _selectedMonth,
          _selectedYear,
        );
        data = calendar['days'] as List<dynamic>? ?? [];
      } else {
        data = await AttendanceService.getEmployeeHistory(
          widget.employeeId,
          date: date,
          month: month,
          year: year,
        );
      }

      if (mounted) {
        setState(() {
          _history = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '—';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  int get _presentCount => _history.where((r) => r['status'] == 'present').length;
  int get _lateCount => _history.where((r) => r['status'] == 'late').length;
  int get _absentCount =>
      _history.where((r) => r['status'] == 'absent').length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kDeepBlue,
              onPrimary: Colors.white,
              onSurface: kDeepBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
      _loadHistory();
    }
  }

  void _nextPeriod() {
    setState(() {
      if (_filterMode == EmpHistoryFilterMode.day) {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == EmpHistoryFilterMode.month) {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      } else if (_filterMode == EmpHistoryFilterMode.year) {
        _selectedYear++;
      }
    });
    _loadHistory();
  }

  void _prevPeriod() {
    setState(() {
      if (_filterMode == EmpHistoryFilterMode.day) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == EmpHistoryFilterMode.month) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      } else if (_filterMode == EmpHistoryFilterMode.year) {
        _selectedYear--;
      }
    });
    _loadHistory();
  }

  String _getPeriodDisplayName() {
    if (_filterMode == EmpHistoryFilterMode.day) {
      return DateFormat('dd MMM yyyy').format(_selectedDate);
    } else if (_filterMode == EmpHistoryFilterMode.month) {
      return '${_monthNames[_selectedMonth - 1]} $_selectedYear';
    } else if (_filterMode == EmpHistoryFilterMode.year) {
      return '$_selectedYear';
    }
    return 'All Time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '${widget.employeeName}\'s Attendance',
          style: GoogleFonts.plusJakartaSans(
            color: kDeepBlue,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: kDeepBlue),
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: _loading ? null : _pickAndMarkPresent,
              icon: const Icon(
                Icons.event_available_outlined,
                size: 20,
                color: kForest,
              ),
              tooltip: 'Mark present on a date',
            ),
          IconButton(
            onPressed: _loading ? null : _loadHistory,
            icon: const Icon(Icons.refresh, size: 20, color: kDeepBlue),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter Controls ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildFilterTab('All', Icons.all_inclusive, EmpHistoryFilterMode.all),
                      const SizedBox(width: 6),
                      _buildFilterTab('Day', Icons.calendar_today_outlined, EmpHistoryFilterMode.day),
                      const SizedBox(width: 6),
                      _buildFilterTab('Month', Icons.calendar_view_month_outlined, EmpHistoryFilterMode.month),
                      const SizedBox(width: 6),
                      _buildFilterTab('Year', Icons.date_range_outlined, EmpHistoryFilterMode.year),
                    ],
                  ),
                  if (_filterMode != EmpHistoryFilterMode.all) ...[
                    const Divider(color: kBorder, height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _prevPeriod,
                          icon: const Icon(Icons.chevron_left, color: kDeepBlue),
                          tooltip: 'Previous',
                          splashRadius: 20,
                        ),
                        InkWell(
                          onTap: _filterMode == EmpHistoryFilterMode.day ? _pickDate : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _filterMode == EmpHistoryFilterMode.day
                                      ? Icons.edit_calendar_outlined
                                      : Icons.event,
                                  size: 16,
                                  color: kDeepBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getPeriodDisplayName(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kDeepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nextPeriod,
                          icon: const Icon(Icons.chevron_right, color: kDeepBlue),
                          tooltip: 'Next',
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Stats Summary ───────────────────────────────────────────────
            if (!_loading && _error == null) ...[
              Row(
                children: [
                  _SummaryMiniChip(
                    label: 'Present',
                    value: '$_presentCount',
                    color: kForest,
                    bg: kSuccessBg,
                  ),
                  const SizedBox(width: 8),
                  _SummaryMiniChip(
                    label: 'Late',
                    value: '$_lateCount',
                    color: kWarn,
                    bg: kWarnBg,
                  ),
                  const SizedBox(width: 8),
                  if (_filterMode == EmpHistoryFilterMode.month)
                    _SummaryMiniChip(
                      label: 'Absent',
                      value: '$_absentCount',
                      color: kDanger,
                      bg: kDangerBg,
                    )
                  else
                    _SummaryMiniChip(
                      label: 'Total',
                      value: '${_history.length}',
                      color: kDeepBlue,
                      bg: kInfoBg,
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Main Content ────────────────────────────────────────────────
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: kDeepBlue),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: kDanger, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.plusJakartaSans(color: kDanger, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
                      child: Text('Retry', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    ),
                  ],
                ),
              )
            else if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_outlined, size: 40, color: kTealGray.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No attendance records found for selected period',
                        style: GoogleFonts.plusJakartaSans(color: kTealGray, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final record = _history[index];
                  final status = record['status']?.toString() ?? 'absent';
                  final isPresent = status == 'present';
                  final isLate = status == 'late';
                  final isOff = status == 'off';
                  final isHoliday = status == 'holiday';
                  final holidayName = record['holiday_name']?.toString();
                  final checkedIn = isPresent || isLate;

                  final Color sc = isPresent
                      ? kForest
                      : isLate
                      ? kWarn
                      : isHoliday
                      ? kDeepBlue
                      : isOff
                      ? kTealGray
                      : kDanger;
                  final Color sb = isPresent
                      ? kSuccessBg
                      : isLate
                      ? kWarnBg
                      : isHoliday
                      ? kInfoBg
                      : isOff
                      ? kOffWhite
                      : kDangerBg;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isHoliday && holidayName != null
                                  ? '${_formatDate(record['date'])} · $holidayName'
                                  : _formatDate(record['date']),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: kDeepBlue,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: sb,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOff ? 'WEEKLY OFF' : status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sc,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Admin can turn any other day into a present day
                        if (_isAdmin &&
                            !isPresent &&
                            DateTime.tryParse(
                                  record['date']?.toString() ?? '',
                                ) !=
                                null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _markPresent(
                                DateTime.parse(record['date'].toString()),
                              ),
                              icon: const Icon(Icons.check, size: 14),
                              label: Text(
                                'Mark present',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: kForest,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: const Size(0, 30),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        // Absent and weekly-off days have no times to show
                        if (checkedIn) const SizedBox(height: 10),
                        if (checkedIn)
                        Row(
                          children: [
                            Expanded(
                              child: _TimeInfo(
                                icon: Icons.login,
                                label: 'Check In',
                                time: _formatTime(record['checked_in_at']),
                              ),
                            ),
                            Expanded(
                              child: _TimeInfo(
                                icon: Icons.logout,
                                label: 'Check Out',
                                time: _formatTime(record['checked_out_at']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, IconData icon, EmpHistoryFilterMode mode) {
    final isSelected = _filterMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_filterMode != mode) {
            setState(() => _filterMode = mode);
            _loadHistory();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? kDeepBlue : kOffWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? Colors.white : kTealGray),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : kTealGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMiniChip extends StatelessWidget {
  final String label, value;
  final Color color, bg;

  const _SummaryMiniChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kTealGray),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: kTealGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kDeepBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
