import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';

enum EmpAttendanceFilterMode { all, day, month, year }

class EmpAttendance extends StatefulWidget {
  final UserModel user;
  const EmpAttendance({super.key, required this.user});

  @override
  State<EmpAttendance> createState() => _EmpAttendanceState();
}

class _EmpAttendanceState extends State<EmpAttendance> {
  bool _loading = true;
  bool _historyLoading = false;
  String? _historyError;
  bool _isOnDuty = false;
  bool _alreadyDone = false;
  bool _locationOn = false;
  bool _toggling = false;
  String _checkInTime = '--:--';
  String _checkOutTime = '--:--';
  String? _liveLocationName;
  List<dynamic> _history = [];

  EmpAttendanceFilterMode _filterMode = EmpAttendanceFilterMode.all;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatMonthYear(DateTime dt) => '${_months[dt.month - 1]} ${dt.year}';
  String _formatFullDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  String _formatDateYMD(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = await AttendanceService.getToday();

      if (today != null) {
        final checkedIn = today['checked_in_at'] != null;
        final checkedOut = today['checked_out_at'] != null;

        if (checkedIn) {
          final dt = DateTime.parse(today['checked_in_at']).toLocal();
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
        if (checkedOut) {
          final dt = DateTime.parse(today['checked_out_at']).toLocal();
          _checkOutTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }

        _isOnDuty = checkedIn && !checkedOut;
        _alreadyDone = checkedIn && checkedOut;
        if (_isOnDuty) {
          if (!LocationService.isTracking) {
            try {
              await LocationService.startTracking();
            } catch (_) {}
          }
          _locationOn = LocationService.isTracking;
          LocationService.getCurrentLocationName().then((name) {
            if (name != null && mounted) {
              setState(() => _liveLocationName = name);
            }
          });
        }
      }

      await _fetchHistory();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    try {
      String? date;
      int? month;
      int? year;

      if (_filterMode == EmpAttendanceFilterMode.day) {
        date = _formatDateYMD(_selectedDate);
      } else if (_filterMode == EmpAttendanceFilterMode.month) {
        month = _selectedMonth;
        year = _selectedYear;
      } else if (_filterMode == EmpAttendanceFilterMode.year) {
        year = _selectedYear;
      }

      final history = await AttendanceService.getMyHistory(
        date: date,
        month: month,
        year: year,
      );

      if (mounted) {
        setState(() {
          _history = history;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString().replaceAll('Exception: ', '');
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAttendance() async {
    if (_toggling || _alreadyDone) return;
    setState(() => _toggling = true);

    try {
      if (_isOnDuty) {
        await AttendanceService.checkOut();
        LocationService.stopTracking();
        final now = DateTime.now();
        setState(() {
          _isOnDuty = false;
          _alreadyDone = true;
          _locationOn = false;
          _checkOutTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        });
        _showSnack('Checked out successfully', kForest);
      } else {
        // 1. Mandatory Location check
        final pos = await LocationService.ensureLocationForCheckIn();
        final place = await LocationService.getAddressFromCoords(
          pos.latitude,
          pos.longitude,
        );

        // 2. Check in with coordinates
        final att = await AttendanceService.checkIn(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );

        // 3. Automatically turn on location tracking
        try {
          await LocationService.startTracking();
        } catch (_) {}

        final dt = DateTime.parse(att['checked_in_at']).toLocal();
        final status = att['status']?.toString() ?? 'present';
        final isLate = status == 'late';

        setState(() {
          _isOnDuty = true;
          _alreadyDone = false;
          _locationOn = true;
          _liveLocationName = place;
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          _checkOutTime = '--:--';
        });

        _showSnack(
          isLate
              ? 'Checked in (Late - after 10:45 AM)'
              : 'Checked in successfully',
          isLate ? kWarn : kForest,
        );
      }
      _fetchHistory();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }

    if (mounted) {
      setState(() => _toggling = false);
    }
  }

  Future<void> _toggleLocation() async {
    if (_locationOn) {
      LocationService.stopTracking();
      setState(() => _locationOn = false);
      _showSnack('Location sharing stopped', kTealGray);
    } else {
      try {
        await LocationService.startTracking();
        final place = await LocationService.getCurrentLocationName();
        setState(() {
          _locationOn = true;
          if (place != null) _liveLocationName = place;
        });
        _showSnack('Location sharing started', kForest);
      } catch (e) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), kDanger);
      }
    }
  }

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
      _fetchHistory();
    }
  }

  void _nextPeriod() {
    setState(() {
      if (_filterMode == EmpAttendanceFilterMode.day) {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == EmpAttendanceFilterMode.month) {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      } else if (_filterMode == EmpAttendanceFilterMode.year) {
        _selectedYear++;
      }
    });
    _fetchHistory();
  }

  void _prevPeriod() {
    setState(() {
      if (_filterMode == EmpAttendanceFilterMode.day) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == EmpAttendanceFilterMode.month) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      } else if (_filterMode == EmpAttendanceFilterMode.year) {
        _selectedYear--;
      }
    });
    _fetchHistory();
  }

  String _getPeriodDisplayName() {
    if (_filterMode == EmpAttendanceFilterMode.day) {
      return DateFormat('dd MMM yyyy').format(_selectedDate);
    } else if (_filterMode == EmpAttendanceFilterMode.month) {
      return '${_monthNames[_selectedMonth - 1]} $_selectedYear';
    } else if (_filterMode == EmpAttendanceFilterMode.year) {
      return '$_selectedYear';
    }
    return 'All Time';
  }

  void _showSnack(String msg, Color color) {
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

  int get _presentCount => _history.where((h) => h['status'] == 'present').length;
  int get _lateCount => _history.where((h) => h['status'] == 'late').length;
  int get _absentCount => _history.where((h) => h['status'] == 'absent').length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    Color btnColor = _alreadyDone
        ? kTealGray
        : _isOnDuty
        ? const Color(0xFF8B2E2E)
        : kForest;

    String btnText = _alreadyDone
        ? 'Done for today'
        : _isOnDuty
        ? 'Check Out'
        : 'Check In';

    return RefreshIndicator(
      color: kDeepBlue,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kDeepBlue,
              ),
            ),
            Text(
              _formatMonthYear(DateTime.now()),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
            ),
            const SizedBox(height: 16),

            // Today card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kDeepBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: kBlueGray,
                            ),
                          ),
                          Text(
                            _formatFullDate(DateTime.now()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _alreadyDone
                              ? kTealGray
                              : _isOnDuty
                              ? kForest
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _alreadyDone
                              ? 'Completed'
                              : _isOnDuty
                              ? 'On Duty'
                              : 'Off Duty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeBox(label: 'Check In', time: _checkInTime),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeBox(label: 'Check Out', time: _checkOutTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_toggling || _alreadyDone)
                          ? null
                          : _toggleAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kTealGray,
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: _toggling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              btnText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: kBlueGray,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Sharing',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _locationOn
                                  ? '${_liveLocationName ?? widget.user.location ?? "Live Location"} — active'
                                  : 'Location off',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: _locationOn
                                    ? const Color(0xFF68D391)
                                    : kBlueGray,
                                fontWeight: _locationOn
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleLocation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 46,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _locationOn
                                  ? kForest
                                  : const Color(0xFFCDD5D5),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _locationOn
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Attendance Filter Controls ──────────────────────────────────
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
                      _buildFilterTab('All', Icons.all_inclusive, EmpAttendanceFilterMode.all),
                      const SizedBox(width: 6),
                      _buildFilterTab('Day', Icons.calendar_today_outlined, EmpAttendanceFilterMode.day),
                      const SizedBox(width: 6),
                      _buildFilterTab('Month', Icons.calendar_view_month_outlined, EmpAttendanceFilterMode.month),
                      const SizedBox(width: 6),
                      _buildFilterTab('Year', Icons.date_range_outlined, EmpAttendanceFilterMode.year),
                    ],
                  ),
                  if (_filterMode != EmpAttendanceFilterMode.all) ...[
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
                          onTap: _filterMode == EmpAttendanceFilterMode.day ? _pickDate : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _filterMode == EmpAttendanceFilterMode.day
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

            // Summary Stats
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    label: 'Present',
                    value: '$_presentCount',
                    color: kForest,
                    bg: kSuccessBg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    label: 'Late',
                    value: '$_lateCount',
                    color: kWarn,
                    bg: kWarnBg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    label: 'Absent',
                    value: '$_absentCount',
                    color: kDanger,
                    bg: kDangerBg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    label: 'Total',
                    value: '${_history.length}',
                    color: kDeepBlue,
                    bg: kInfoBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Log Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATTENDANCE LOG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kTealGray,
                    letterSpacing: 1.2,
                  ),
                ),
                if (!_historyLoading)
                  Text(
                    '${_history.length} record${_history.length == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kTealGray,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_historyLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: kDeepBlue),
                ),
              )
            else if (_historyError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: kDanger, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        _historyError!,
                        style: GoogleFonts.plusJakartaSans(color: kDanger, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
                        child: Text('Retry', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_outlined, size: 36, color: kTealGray.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        'No attendance records found for selected period',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: kTealGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._history.map((h) => _HistoryRow(record: h)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, IconData icon, EmpAttendanceFilterMode mode) {
    final isSelected = _filterMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_filterMode != mode) {
            setState(() => _filterMode = mode);
            _fetchHistory();
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

// ── Widgets ───────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String label, time;
  const _TimeBox({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kBlueGray),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
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
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryRow({required this.record});

  String _formatDateDisplay(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? 'present';
    Color sc = status == 'present'
        ? kForest
        : status == 'late'
        ? kWarn
        : kDanger;
    Color sb = status == 'present'
        ? kSuccessBg
        : status == 'late'
        ? kWarnBg
        : kDangerBg;

    String formatTime(String? t) {
      if (t == null) return '--:--';
      try {
        final dt = DateTime.parse(t).toLocal();
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {
        return '--:--';
      }
    }

    final checkIn = formatTime(record['checked_in_at']);
    final checkOut = formatTime(record['checked_out_at']);
    final date = _formatDateDisplay(record['date']);
    final lat = record['latitude'] != null ? (record['latitude'] as num).toDouble() : null;
    final lng = record['longitude'] != null ? (record['longitude'] as num).toDouble() : null;
    final rawLoc = record['location']?.toString();

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
              color: sb,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              status == 'present'
                  ? Icons.check_circle_outline
                  : status == 'late'
                  ? Icons.watch_later_outlined
                  : Icons.cancel_outlined,
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
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  'In: $checkIn  ·  Out: $checkOut',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: kTealGray,
                  ),
                ),
                if ((lat != null && lng != null) || (rawLoc != null && rawLoc.isNotEmpty && rawLoc != '—')) ...[
                  const SizedBox(height: 3),
                  LocationNameBadge(
                    latitude: lat,
                    longitude: lng,
                    rawLocation: rawLoc,
                    iconSize: 11,
                    iconColor: kForest,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kDeepBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sb,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: sc,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
