import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/location_service.dart';
import '../../services/travel_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/dashboard_widgets.dart';
import 'attendance_screen.dart';
import 'employees_screen.dart';
import 'claims_screen.dart';
import 'salary_screen.dart';
import 'location_screen.dart';
import 'admin_travel_screen.dart';

const List<ShellNavItem> _navItems = [
  (
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  (
    icon: Icons.access_time_outlined,
    activeIcon: Icons.access_time,
    label: 'Attendance',
  ),
  (
    icon: Icons.location_on_outlined,
    activeIcon: Icons.location_on,
    label: 'Location',
  ),
  (icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Claims'),
  (icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Salary'),
  (icon: Icons.flight_outlined, activeIcon: Icons.flight, label: 'Travel'),
  (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Team'),
];

// ── AdminHome ─────────────────────────────────────────────────────────────────
class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late final List<Widget> _screens = [
    AdminDashboardTab(user: widget.user),
    const AttendanceScreen(),
    const LocationScreen(),
    const ClaimsScreen(),
    const SalaryScreen(),
    const AdminTravelScreen(),
    const EmployeesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      user: widget.user,
      items: _navItems,
      screens: _screens,
      // Team is the last tab; its table filters on the search box
      searchable: const {6},
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class AdminDashboardTab extends StatefulWidget {
  final UserModel user;
  const AdminDashboardTab({super.key, required this.user});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _loading = true;
  String? _error;
  int _totalEmp = 0;
  int _presentToday = 0;
  int _pendingClaims = 0;
  int _pendingTravel = 0;
  String _salaryTotal = '—';
  List<dynamic> _todayAttendance = [];
  List<dynamic> _recentClaims = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Future<void> _loadData() async {
    try {
      final employees = await AuthService.getEmployees();
      final attendance = await AttendanceService.getAllToday();
      final claims = await ReimbursementService.getAllClaims(status: 'pending');
      int pendingTravelCount = 0;
      try {
        final travel = await TravelService.getAllRequests(status: 'pending');
        pendingTravelCount = travel.length;
      } catch (_) {}

      // ── Fix 1: Calculate salary total from employee base_salary ──────────
      final totalSalary = employees.fold<num>(
        0,
        (sum, emp) => sum + ((emp['base_salary'] as num?) ?? 0),
      );

      // ── Fix 2: Deduplicate attendance by user_id ──────────────────────────
      final seen = <String>{};
      final uniqueAttendance = attendance.where((a) {
        final uid = a['user_id']?.toString() ?? '';
        return uid.isNotEmpty ? seen.add(uid) : true;
      }).toList();

      if (!mounted) return;
      setState(() {
        _totalEmp = employees.length;
        _presentToday = uniqueAttendance.length;
        _pendingClaims = claims.length;
        _pendingTravel = pendingTravelCount;
        _salaryTotal = totalSalary > 0
            ? '₹${(totalSalary / 1000).toStringAsFixed(0)}K'
            : '—';
        _todayAttendance = uniqueAttendance;
        _recentClaims = claims.take(3).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kDanger),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: kDanger,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Try again',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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

    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: ContentCap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(isDesktop),
            const SizedBox(height: 20),
            const DashSectionHeader('Today\'s overview'),
            const SizedBox(height: 10),
            _buildStatsGrid(isDesktop),
            const SizedBox(height: 24),
            if (isDesktop)
              // Desktop: claims + attendance side by side
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRecentClaimsSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildAttendanceSection()),
                  ],
                ),
              )
            else ...[
              _buildRecentClaimsSection(),
              const SizedBox(height: 20),
              _buildAttendanceSection(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────────
  Widget _buildGreeting(bool isDesktop) {
    final greetingContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(),
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kBlueGray),
        ),
        Text(
          widget.user.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Admin · GTO Portal',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kBlueGray),
          ),
        ),
      ],
    );

    // Desktop: show quick summary stats inline on the right
    final quickStats = isDesktop
        ? Row(
            children: [
              HeroStat(label: 'Total Staff', value: '$_totalEmp'),
              const SizedBox(width: 10),
              HeroStat(label: 'Present', value: '$_presentToday'),
              const SizedBox(width: 10),
              HeroStat(label: 'Pending Claims', value: '$_pendingClaims'),
            ],
          )
        : null;

    return DashHero(
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: greetingContent),
                ?quickStats,
              ],
            )
          : greetingContent,
    );
  }

  // ── Stats grid ───────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool isDesktop) {
    final cards = [
      (
        label: 'Total Employees',
        value: '$_totalEmp',
        icon: Icons.people,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
      (
        label: 'Present Today',
        value: '$_presentToday',
        icon: Icons.check_circle_outline,
        color: kForest,
        bg: kSuccessBg,
      ),
      (
        label: 'Pending Claims',
        value: '$_pendingClaims',
        icon: Icons.receipt_outlined,
        color: kWarn,
        bg: kWarnBg,
      ),
      (
        label:
            'Salary (${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][DateTime.now().month - 1]})',
        value: _salaryTotal,
        icon: Icons.payments_outlined,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
      (
        label: 'Pending Travel',
        value: '$_pendingTravel',
        icon: Icons.flight_outlined,
        color: kWarn,
        bg: kWarnBg,
      ),
    ];

    return DashStatGrid(
      maxColumns: 5,
      children: [for (final c in cards) DashStatCard(
          label: c.label,
          value: c.value,
          icon: c.icon,
          color: c.color,
          bg: c.bg,
        )],
    );
  }

  // ── Recent claims section ────────────────────────────────────────────────────
  Widget _buildRecentClaimsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader('Pending claims'),
        const SizedBox(height: 10),
        if (_recentClaims.isEmpty)
          const DashEmptyState(
            'No pending claims',
            icon: Icons.receipt_long_outlined,
          )
        else
          ..._recentClaims.map((c) {
            final submitter = c['submitter'] as Map<String, dynamic>?;
            final name = submitter?['name'] ?? 'Unknown';
            final amount = (c['amount'] as num).toDouble();
            final date = (c['created_at'] as String).substring(0, 10);
            return _ClaimTile(
              name: name,
              category: c['category'] ?? '',
              amount: '₹${amount.toStringAsFixed(0)}',
              status: c['status'] ?? '',
              date: date,
            );
          }),
      ],
    );
  }

  // ── Team attendance section ──────────────────────────────────────────────────
  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader('Team attendance today'),
        const SizedBox(height: 10),
        if (_todayAttendance.isEmpty)
          const DashEmptyState(
            'No one checked in yet',
            icon: Icons.access_time_rounded,
          )
        else
          ..._todayAttendance.map((a) {
            final user = a['users'] as Map<String, dynamic>?;
            final name = user?['name'] ?? 'Unknown';
            final role = user?['designation'] ?? '';
            final loc = user?['location'] ?? '—';
            String checkIn = '—';
            if (a['checked_in_at'] != null) {
              final dt = DateTime.parse(a['checked_in_at']).toLocal();
              checkIn =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }
            return _AttendanceTile(
              name: name,
              role: role,
              location: loc,
              status: a['status'] ?? 'absent',
              time: checkIn,
            );
          }),
      ],
    );
  }
}

// ── Claim Tile ────────────────────────────────────────────────────────────────
class _ClaimTile extends StatelessWidget {
  final String name, category, amount, status, date;
  const _ClaimTile({
    required this.name,
    required this.category,
    required this.amount,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return DashListTile(
      leading: InitialAvatar(name),
      title: name,
      subtitle: Text(
        '$category · $date',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTealGray),
      ),
      trailingText: amount,
      status: status,
    );
  }
}

// ── Attendance Tile ───────────────────────────────────────────────────────────
class _AttendanceTile extends StatelessWidget {
  final String name, role, location, status, time;
  const _AttendanceTile({
    required this.name,
    required this.role,
    required this.location,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return DashListTile(
      leading: InitialAvatar(name),
      title: name,
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kTealGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (location.isNotEmpty && location != '—') ...[
            const SizedBox(width: 4),
            Text(
              '·',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kTealGray,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: LocationNameBadge(
                rawLocation: location,
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
      trailingText: time,
      status: status,
    );
  }
}

// ── ContentCap — caps max width on wide screens ───────────────────────────────
