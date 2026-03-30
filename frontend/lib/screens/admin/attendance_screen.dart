import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  String? _error;

  // Merged list: one entry per employee
  List<_EmpAttEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch all employees + today's check-ins in parallel
      final results = await Future.wait([
        AuthService.getEmployees(),
        AttendanceService.getAllToday(),
      ]);

      final employees = results[0] as List<dynamic>;
      final checkins = results[1] as List<dynamic>;

      // Build a lookup: userId → attendance record
      final attMap = <String, Map<String, dynamic>>{};
      for (final att in checkins) {
        final uid = (att['user_id'] ?? att['users']?['id'])?.toString();
        if (uid != null) attMap[uid] = att as Map<String, dynamic>;
      }

      // Merge
      final entries = employees.map((emp) {
        final id = emp['id']?.toString() ?? '';
        final att = attMap[id];
        return _EmpAttEntry.fromRaw(emp as Map<String, dynamic>, att);
      }).toList();

      // Sort: present/late first, absent last
      entries.sort((a, b) {
        const order = {'present': 0, 'late': 1, 'absent': 2};
        return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
      });

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Summary counts ───────────────────────────────────────────────────────────
  int get _presentCount => _entries.where((e) => e.status == 'present').length;
  int get _lateCount => _entries.where((e) => e.status == 'late').length;
  int get _absentCount => _entries.where((e) => e.status == 'absent').length;

  // ── Month label ──────────────────────────────────────────────────────────────
  static const _months = [
    '',
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  String get _monthLabel {
    final now = DateTime.now();
    return '${_months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

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
                // ── Header ─────────────────────────────────────────────────
                Text(
                  _monthLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kTealGray,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team Attendance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: _loading ? null : _loadData,
                      icon: const Icon(Icons.refresh, size: 20),
                      color: kTealGray,
                      tooltip: 'Refresh',
                    ),
                  ],
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
                      _SummaryChip(
                        label: 'Absent',
                        value: '$_absentCount',
                        color: kDanger,
                        bg: kDangerBg,
                      ),
                      _SummaryChip(
                        label: 'Total',
                        value: '${_entries.length}',
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
                else if (_entries.isEmpty)
                  _EmptyState()
                else
                  isDesktop
                      ? _DesktopGrid(entries: _entries)
                      : _MobileList(entries: _entries),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _EmpAttEntry {
  final String name;
  final String role;
  final String location;
  final String status; // present | late | absent
  final String checkIn;
  final String checkOut;

  const _EmpAttEntry({
    required this.name,
    required this.role,
    required this.location,
    required this.status,
    required this.checkIn,
    required this.checkOut,
  });

  factory _EmpAttEntry.fromRaw(
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

    final status = att?['status']?.toString() ?? 'absent';
    return _EmpAttEntry(
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

// ── Employee card ─────────────────────────────────────────────────────────────
class _EmployeeAttCard extends StatelessWidget {
  final _EmpAttEntry entry;
  const _EmployeeAttCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == 'present';
    final isLate = entry.status == 'late';
    final Color sc = isPresent
        ? kForest
        : isLate
        ? kWarn
        : kDanger;
    final Color sb = isPresent
        ? kSuccessBg
        : isLate
        ? kWarnBg
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: avatar + name + status badge ─────────────────────────
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
                    Text(
                      '${entry.role} · ${entry.location}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: kTealGray,
                      ),
                      overflow: TextOverflow.ellipsis,
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

          // ── Bottom row: check-in / check-out chips ────────────────────────
          Row(
            children: [
              _InfoChip(icon: Icons.login, label: 'In', value: entry.checkIn),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.logout,
                label: 'Out',
                value: entry.checkOut,
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kTealGray),
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 40,
              color: kTealGray.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No employees found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: kTealGray,
                fontWeight: FontWeight.w500,
              ),
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
              color: kDanger.withOpacity(0.7),
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
