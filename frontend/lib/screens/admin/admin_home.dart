import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
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
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: kDeepBlue,
        elevation: 0,
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
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Claims',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Salary',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────
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

      // All employees
      final employees = await AuthService.getEmployees();

      // Today's attendance
      final attendance = await AttendanceService.getAllToday();

      // Pending claims
      final claims = await ReimbursementService.getAllClaims(status: 'pending');

      // Salary summary
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kDeepBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: kBlueGray,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Admin · GTO Portal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kBlueGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Text(
            'TODAY\'S OVERVIEW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _StatCard(
                label: 'Total Employees',
                value: '$_totalEmp',
                icon: Icons.people,
                color: kDeepBlue,
                bg: kInfoBg,
              ),
              _StatCard(
                label: 'Present Today',
                value: '$_presentToday',
                icon: Icons.check_circle_outline,
                color: kForest,
                bg: kSuccessBg,
              ),
              _StatCard(
                label: 'Pending Claims',
                value: '$_pendingClaims',
                icon: Icons.receipt_outlined,
                color: kWarn,
                bg: kWarnBg,
              ),
              _StatCard(
                label: 'Salary (Mar)',
                value: _salaryTotal,
                icon: Icons.payments_outlined,
                color: kDeepBlue,
                bg: kInfoBg,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent claims
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT CLAIMS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: kTealGray,
                  letterSpacing: 1.2,
                ),
              ),
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No pending claims',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: kTealGray,
                  ),
                ),
              ),
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
          const SizedBox(height: 20),

          // Team attendance
          Text(
            'TEAM ATTENDANCE TODAY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (_todayAttendance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No one checked in yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: kTealGray,
                  ),
                ),
              ),
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
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────
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

// ── Claim Tile ────────────────────────────────────────────
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

// ── Attendance Tile ───────────────────────────────────────
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
    Color sc = isPresent
        ? kForest
        : isLate
        ? kWarn
        : kDanger;
    Color sb = isPresent
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
