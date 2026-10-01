import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../services/attendance_service.dart';

enum EmpHistoryFilterMode { all, day, month, year }

class EmployeeHistoryScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _history = [];

  EmpHistoryFilterMode _filterMode = EmpHistoryFilterMode.all;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

      final data = await AttendanceService.getEmployeeHistory(
        widget.employeeId,
        date: date,
        month: month,
        year: year,
      );

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
                      Icon(Icons.event_busy_outlined, size: 40, color: kTealGray.withOpacity(0.5)),
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

                  final Color sc = isPresent ? kForest : isLate ? kWarn : kDanger;
                  final Color sb = isPresent ? kSuccessBg : isLate ? kWarnBg : kDangerBg;

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
                              _formatDate(record['date']),
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
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sc,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
