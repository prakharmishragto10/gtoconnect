import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../login_screen.dart';
import 'attendance_screen.dart';
import 'employees_screen.dart';
import 'claims_screen.dart';
import 'salary_screen.dart';
import 'location_screen.dart';

// ── Nav item definition ───────────────────────────────────────────────────────
typedef _NavItem = ({IconData icon, IconData activeIcon, String label});

const List<_NavItem> _navItems = [
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
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardTab(user: widget.user),
      const AttendanceScreen(),
      const LocationScreen(),
      const ClaimsScreen(),
      const SalaryScreen(),
      const EmployeesScreen(),
    ];
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: kDeepBlue,
        elevation: 0,
        toolbarHeight: 52,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'GTO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kBlueGray,
                ),
              ),
              TextSpan(
                text: 'Connect',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isDesktop) ...[
            _AppBarAvatar(name: widget.user.name),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 16, color: kBlueGray),
            label: Text(
              'Sign out',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: kBlueGray,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isDesktop
          ? _AdminDesktopLayout(
              currentIndex: _currentIndex,
              onNav: (i) => setState(() => _currentIndex = i),
              child: _screens[_currentIndex],
            )
          : _screens[_currentIndex],
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: kDeepBlue,
              unselectedItemColor: kBlueGray,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
              items: _navItems
                  .map(
                    (n) => BottomNavigationBarItem(
                      icon: Icon(n.icon),
                      activeIcon: Icon(n.activeIcon),
                      label: n.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ── Desktop sidebar + content ─────────────────────────────────────────────────
class _AdminDesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNav;
  final Widget child;

  const _AdminDesktopLayout({
    required this.currentIndex,
    required this.onNav,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Sidebar ──────────────────────────────────────────────────────────
        Container(
          width: 210,
          color: kDeepBlue,
          child: ListView(
            padding: const EdgeInsets.only(top: 12),
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = i == currentIndex;
              return InkWell(
                onTap: () => onNav(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.08)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: active ? Colors.blue : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 18,
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Content area ─────────────────────────────────────────────────────
        Expanded(child: child),
      ],
    );
  }
}

// ── App bar avatar ────────────────────────────────────────────────────────────
class _AppBarAvatar extends StatelessWidget {
  final String name;
  const _AppBarAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white.withOpacity(0.15),
          child: Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
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
  int _totalEmp = 0;
  int _presentToday = 0;
  int _pendingClaims = 0;
  String _salaryTotal = '—';
  List<dynamic> _todayAttendance = [];
  List<dynamic> _recentClaims = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final employees = await AuthService.getEmployees();
      final attendance = await AttendanceService.getAllToday();
      final claims = await ReimbursementService.getAllClaims(status: 'pending');
      final summary = await SalaryService.getSummary(now.month, now.year);

      setState(() {
        _totalEmp = employees.length;
        _presentToday = attendance.length;
        _pendingClaims = claims.length;
        _salaryTotal = summary['net'] != null
            ? '₹${((summary['net'] as num) / 1000).toStringAsFixed(0)}K'
            : '—';
        _todayAttendance = attendance;
        _recentClaims = claims.take(3).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
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
            _SectionLabel('TODAY\'S OVERVIEW'),
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
          'Good morning,',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kBlueGray),
        ),
        Text(
          widget.user.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
              _GreetingStat(label: 'Total Staff', value: '$_totalEmp'),
              const SizedBox(width: 24),
              _GreetingStat(label: 'Present', value: '$_presentToday'),
              const SizedBox(width: 24),
              _GreetingStat(label: 'Pending Claims', value: '$_pendingClaims'),
            ],
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeepBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: greetingContent),
                if (quickStats != null) quickStats,
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
        label: 'Salary (Mar)',
        value: _salaryTotal,
        icon: Icons.payments_outlined,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.6 : 1.7,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return _StatCard(
          label: c.label,
          value: c.value,
          icon: c.icon,
          color: c.color,
          bg: c.bg,
        );
      },
    );
  }

  // ── Recent claims section ────────────────────────────────────────────────────
  Widget _buildRecentClaimsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('RECENT CLAIMS'),
            Text(
              'See all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kDeepBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentClaims.isEmpty)
          _EmptyState('No pending claims')
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
        const _SectionLabel('TEAM ATTENDANCE TODAY'),
        const SizedBox(height: 10),
        if (_todayAttendance.isEmpty)
          _EmptyState('No one checked in yet')
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

// ── Greeting quick-stat chip (desktop only) ───────────────────────────────────
class _GreetingStat extends StatelessWidget {
  final String label, value;
  const _GreetingStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kBlueGray),
        ),
      ],
    );
  }
}

// ── Shared: section label ─────────────────────────────────────────────────────
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

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
      ),
    ),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: kTealGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
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
                Text(
                  '$category · $date',
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
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending ? kWarnBg : kSuccessBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isPending ? kWarn : kForest,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final isPresent = status == 'present';
    final isLate = status == 'late';
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
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kInfoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
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
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  '$role · $location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: kTealGray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              const SizedBox(height: 3),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: kTealGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ContentCap — caps max width on wide screens ───────────────────────────────
class ContentCap extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentCap({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
