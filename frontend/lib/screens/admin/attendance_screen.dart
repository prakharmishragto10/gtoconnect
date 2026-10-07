import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'employee_history_screen.dart';

enum AttendanceFilterMode { day, month, year }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  String? _error;

  AttendanceFilterMode _filterMode = AttendanceFilterMode.day;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Merged list: one entry per employee (Day mode) or raw check-in entries (Month/Year mode)
  List<_EmpAttEntry> _entries = [];
  List<dynamic> _rawRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDateYMD(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_filterMode == AttendanceFilterMode.day) {
        final dateStr = _formatDateYMD(_selectedDate);
        final results = await Future.wait([
          AuthService.getEmployees(date: dateStr),
          AttendanceService.getAllToday(date: dateStr),
        ]);

        final employees = results[0];
        final checkins = results[1];

        final attMap = <String, Map<String, dynamic>>{};
        for (final att in checkins) {
          final uid = (att['user_id'] ?? att['users']?['id'])?.toString();
          if (uid != null) attMap[uid] = att as Map<String, dynamic>;
        }

        final entries = employees.map((emp) {
          final id = emp['id']?.toString() ?? '';
          final att = attMap[id];
          return _EmpAttEntry.fromRaw(id, emp as Map<String, dynamic>, att);
        }).toList();

        entries.sort((a, b) {
          const order = {
            'present': 0,
            'late': 1,
            'absent': 2,
            'holiday': 3,
            'off': 4,
          };
          return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
        });

        if (mounted) {
          setState(() {
            _entries = entries;
            _rawRecords = checkins;
            _loading = false;
          });
        }
      } else if (_filterMode == AttendanceFilterMode.month) {
        final records = await AttendanceService.getAllToday(
          month: _selectedMonth,
          year: _selectedYear,
        );

        if (mounted) {
          setState(() {
            _rawRecords = records;
            _loading = false;
          });
        }
      } else {
        // Year mode
        final records = await AttendanceService.getAllToday(
          year: _selectedYear,
        );

        if (mounted) {
          setState(() {
            _rawRecords = records;
            _loading = false;
          });
        }
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

  // ── Summary counts ───────────────────────────────────────────────────────────
  int get _presentCount {
    if (_filterMode == AttendanceFilterMode.day) {
      return _entries.where((e) => e.status == 'present').length;
    }
    return _rawRecords.where((r) => r['status'] == 'present').length;
  }

  int get _lateCount {
    if (_filterMode == AttendanceFilterMode.day) {
      return _entries.where((e) => e.status == 'late').length;
    }
    return _rawRecords.where((r) => r['status'] == 'late').length;
  }

  int get _absentCount {
    if (_filterMode == AttendanceFilterMode.day) {
      return _entries.where((e) => e.status == 'absent').length;
    }
    return 0;
  }

  // Staff on their weekly off who did not check in (Day mode only)
  int get _offCount => _filterMode == AttendanceFilterMode.day
      ? _entries.where((e) => e.status == 'off').length
      : 0;

  int get _holidayCount => _filterMode == AttendanceFilterMode.day
      ? _entries.where((e) => e.status == 'holiday').length
      : 0;

  int get _totalCount {
    if (_filterMode == AttendanceFilterMode.day) {
      return _entries.length;
    }
    return _rawRecords.length;
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

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
      _loadData();
    }
  }

  void _nextPeriod() {
    setState(() {
      if (_filterMode == AttendanceFilterMode.day) {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == AttendanceFilterMode.month) {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      } else {
        _selectedYear++;
      }
    });
    _loadData();
  }

  void _prevPeriod() {
    setState(() {
      if (_filterMode == AttendanceFilterMode.day) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _selectedMonth = _selectedDate.month;
        _selectedYear = _selectedDate.year;
      } else if (_filterMode == AttendanceFilterMode.month) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      } else {
        _selectedYear--;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    String filterHeaderLabel;
    if (_filterMode == AttendanceFilterMode.day) {
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;
      filterHeaderLabel = isToday
          ? 'TODAY, ${DateFormat('dd MMM yyyy').format(_selectedDate).toUpperCase()}'
          : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate).toUpperCase();
    } else if (_filterMode == AttendanceFilterMode.month) {
      filterHeaderLabel =
          '${_monthNames[_selectedMonth - 1].toUpperCase()} $_selectedYear';
    } else {
      filterHeaderLabel = 'YEAR $_selectedYear';
    }

    return RefreshIndicator(
      color: kDeepBlue,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sub-header label ───────────────────────────────────────
                Text(
                  filterHeaderLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kTealGray,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // ── Title & Refresh ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team Attendance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _loadData,
                      icon: const Icon(Icons.refresh, size: 20),
                      color: kTealGray,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Mode Switcher & Date Controls ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      // Toggle buttons for Day / Month / Year
                      Row(
                        children: [
                          _buildFilterTab(
                            title: 'Day',
                            icon: Icons.calendar_today_outlined,
                            isSelected: _filterMode == AttendanceFilterMode.day,
                            onTap: () {
                              if (_filterMode != AttendanceFilterMode.day) {
                                setState(() => _filterMode = AttendanceFilterMode.day);
                                _loadData();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterTab(
                            title: 'Month',
                            icon: Icons.calendar_view_month_outlined,
                            isSelected: _filterMode == AttendanceFilterMode.month,
                            onTap: () {
                              if (_filterMode != AttendanceFilterMode.month) {
                                setState(() => _filterMode = AttendanceFilterMode.month);
                                _loadData();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterTab(
                            title: 'Year',
                            icon: Icons.date_range_outlined,
                            isSelected: _filterMode == AttendanceFilterMode.year,
                            onTap: () {
                              if (_filterMode != AttendanceFilterMode.year) {
                                setState(() => _filterMode = AttendanceFilterMode.year);
                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: kBorder, height: 20),

                      // Navigator bar
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
                            onTap: _filterMode == AttendanceFilterMode.day
                                ? _pickDate
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _filterMode == AttendanceFilterMode.day
                                        ? Icons.edit_calendar_outlined
                                        : Icons.event,
                                    size: 16,
                                    color: kDeepBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getPeriodDisplayName(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kDeepBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_filterMode == AttendanceFilterMode.day)
                                TextButton(
                                  onPressed: () {
                                    final now = DateTime.now();
                                    setState(() {
                                      _selectedDate = now;
                                      _selectedMonth = now.month;
                                      _selectedYear = now.year;
                                    });
                                    _loadData();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: kDeepBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Today',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Summary chips ───────────────────────────────────────────
                if (!_loading && _error == null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(
                        label: 'Present',
                        value: '$_presentCount',
                        color: kForest,
                        bg: kSuccessBg,
                      ),
                      _SummaryChip(
                        label: 'Late',
                        value: '$_lateCount',
                        color: kWarn,
                        bg: kWarnBg,
                      ),
                      if (_filterMode == AttendanceFilterMode.day)
                        _SummaryChip(
                          label: 'Absent',
                          value: '$_absentCount',
                          color: kDanger,
                          bg: kDangerBg,
                        ),
                      if (_holidayCount > 0)
                        _SummaryChip(
                          label: 'Holiday',
                          value: '$_holidayCount',
                          color: kDeepBlue,
                          bg: kInfoBg,
                        ),
                      if (_offCount > 0)
                        _SummaryChip(
                          label: 'Weekly off',
                          value: '$_offCount',
                          color: kTealGray,
                          bg: Colors.white,
                        ),
                      _SummaryChip(
                        label: _filterMode == AttendanceFilterMode.day
                            ? 'Total Team'
                            : 'Check-ins',
                        value: '$_totalCount',
                        color: kDeepBlue,
                        bg: kInfoBg,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Body ────────────────────────────────────────────────────
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: kDeepBlue),
                    ),
                  )
                else if (_error != null)
                  _ErrorState(message: _error!, onRetry: _loadData)
                else if (_filterMode == AttendanceFilterMode.day)
                  _entries.isEmpty
                      ? _EmptyState(text: 'No employee records found')
                      : isDesktop
                          ? _DesktopGrid(entries: _entries)
                          : _MobileList(entries: _entries)
                else
                  _rawRecords.isEmpty
                      ? _EmptyState(
                          text: _filterMode == AttendanceFilterMode.month
                              ? 'No attendance records in ${_monthNames[_selectedMonth - 1]} $_selectedYear'
                              : 'No attendance records in $_selectedYear',
                        )
                      : _MonthYearRecordsList(records: _rawRecords),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? kDeepBlue : kOffWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : kTealGray,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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

  String _getPeriodDisplayName() {
    if (_filterMode == AttendanceFilterMode.day) {
      return DateFormat('dd MMM yyyy').format(_selectedDate);
    } else if (_filterMode == AttendanceFilterMode.month) {
      return '${_monthNames[_selectedMonth - 1]} $_selectedYear';
    } else {
      return '$_selectedYear';
    }
  }
}

// ── Data model for Day mode ───────────────────────────────────────────────────
class _EmpAttEntry {
  final String id;
  final String name;
  final String role;
  final String location;
  final String status; // present | late | absent | off (weekly off) | holiday
  final String checkIn;
  final String checkOut;

  const _EmpAttEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.status,
    required this.checkIn,
    required this.checkOut,
  });

  factory _EmpAttEntry.fromRaw(
    String id,
    Map<String, dynamic> emp,
    Map<String, dynamic>? att,
  ) {
    String fmtTime(String? raw) {
      if (raw == null) return '—';
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0
              ? 12
              : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }

    // No check-in on the employee's weekly off is "off", not an absence
    final status =
        att?['status']?.toString() ??
        (emp['is_working_day'] == false
            ? 'off'
            : emp['is_holiday'] == true
            ? 'holiday'
            : 'absent');
    return _EmpAttEntry(
      id: id,
      name: emp['name']?.toString() ?? 'Unknown',
      role: emp['designation']?.toString() ?? emp['role']?.toString() ?? '—',
      location: emp['location']?.toString() ?? '—',
      status: status,
      checkIn: fmtTime(att?['checked_in_at']?.toString()),
      checkOut: fmtTime(att?['checked_out_at']?.toString()),
    );
  }

  String get initials =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}

// ── Desktop: 2-column grid ────────────────────────────────────────────────────
class _DesktopGrid extends StatelessWidget {
  final List<_EmpAttEntry> entries;
  const _DesktopGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _EmployeeAttCard(entry: entries[i]),
    );
  }
}

// ── Mobile: vertical list ─────────────────────────────────────────────────────
class _MobileList extends StatelessWidget {
  final List<_EmpAttEntry> entries;
  const _MobileList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((e) => _EmployeeAttCard(entry: e)).toList(),
    );
  }
}

// ── Employee card (Day Mode) ──────────────────────────────────────────────────
class _EmployeeAttCard extends StatelessWidget {
  final _EmpAttEntry entry;
  const _EmployeeAttCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == 'present';
    final isLate = entry.status == 'late';
    final isOff = entry.status == 'off';
    final isHoliday = entry.status == 'holiday';
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHistoryScreen(
              employeeId: entry.id,
              employeeName: entry.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kInfoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      entry.initials,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDeepBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.role,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: kTealGray,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.location.isNotEmpty && entry.location != '—') ...[
                            const SizedBox(width: 4),
                            Text('·', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTealGray)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: LocationNameBadge(
                                rawLocation: entry.location,
                                iconSize: 11,
                                iconColor: kForest,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kDeepBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sb,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sc,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(icon: Icons.login, label: 'In', value: entry.checkIn),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.logout, label: 'Out', value: entry.checkOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Records List for Month / Year Mode ────────────────────────────────────────
class _MonthYearRecordsList extends StatelessWidget {
  final List<dynamic> records;
  const _MonthYearRecordsList({required this.records});

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _fmtTime(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        final user = r['users'] as Map<String, dynamic>?;
        final name = user?['name']?.toString() ?? 'Employee';
        final role = user?['designation']?.toString() ?? '—';
        final status = r['status']?.toString() ?? 'present';
        final isPresent = status == 'present';
        final isLate = status == 'late';

        final Color sc = isPresent ? kForest : isLate ? kWarn : kDanger;
        final Color sb = isPresent ? kSuccessBg : isLate ? kWarnBg : kDangerBg;

        return InkWell(
          onTap: () {
            final uid = (r['user_id'] ?? user?['id'])?.toString();
            if (uid != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeHistoryScreen(
                    employeeId: uid,
                    employeeName: name,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kInfoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${_fmtDate(r['date'])} · $role',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: kTealGray,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((user?['location']?.toString() ?? '').isNotEmpty && user?['location'] != '—') ...[
                            const SizedBox(width: 4),
                            Text('·', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTealGray)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: LocationNameBadge(
                                rawLocation: user!['location'].toString(),
                                iconSize: 11,
                                iconColor: kForest,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kDeepBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.login,
                            label: 'In',
                            value: _fmtTime(r['checked_in_at']),
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.logout,
                            label: 'Out',
                            value: _fmtTime(r['checked_out_at']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sb,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sc,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip (check-in / check-out) ─────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kTealGray),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTealGray),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kDeepBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({this.text = 'No attendance records found'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: kTealGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: kTealGray,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 36,
              color: kDanger.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kDanger),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Try again',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDeepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
