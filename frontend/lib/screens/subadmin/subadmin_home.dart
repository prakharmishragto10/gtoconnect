import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../login_screen.dart';
import '../admin/claims_screen.dart';
import '../admin/salary_screen.dart';
import '../admin/attendance_screen.dart';

class SubAdminHome extends StatefulWidget {
  final UserModel user;
  const SubAdminHome({super.key, required this.user});

  @override
  State<SubAdminHome> createState() => _SubAdminHomeState();
}

class _SubAdminHomeState extends State<SubAdminHome> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SubAdminDashboard(user: widget.user),
      const ClaimsScreen(),
      const SalaryScreen(),
      const AttendanceScreen(),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
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
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────
class SubAdminDashboard extends StatefulWidget {
  final UserModel user;
  const SubAdminDashboard({super.key, required this.user});

  @override
  State<SubAdminDashboard> createState() => _SubAdminDashboardState();
}

class _SubAdminDashboardState extends State<SubAdminDashboard> {
  bool _loading = true;
  int _pendingClaims = 0;
  double _pendingTotal = 0;
  int _approvedClaims = 0;
  int _paidSalaries = 0;
  int _pendingSalaries = 0;
  String _netPayable = '—';
  List<dynamic> _recentClaims = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();

      final claims = await ReimbursementService.getAllClaims();
      final summary = await SalaryService.getSummary(now.month, now.year);

      final pending = claims.where((c) => c['status'] == 'pending').toList();
      final approved = claims.where((c) => c['status'] == 'approved').toList();
      final pTotal = pending.fold(
        0.0,
        (s, c) => s + (c['amount'] as num).toDouble(),
      );

      setState(() {
        _pendingClaims = pending.length;
        _pendingTotal = pTotal;
        _approvedClaims = approved.length;
        _paidSalaries = (summary['paid'] as num?)?.toInt() ?? 0;
        _pendingSalaries = (summary['pending'] as num?)?.toInt() ?? 0;
        _netPayable = summary['net'] != null
            ? '₹${((summary['net'] as num) / 1000).toStringAsFixed(0)}K'
            : '—';
        _recentClaims = claims.take(4).toList();
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
                    '${widget.user.designation ?? 'Finance'} · GTO Connect',
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

          // Claims overview
          Text(
            'CLAIMS OVERVIEW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _StatCard(
                label: 'Pending',
                value: '$_pendingClaims',
                sub: '₹${_pendingTotal.toStringAsFixed(0)}',
                icon: Icons.pending_outlined,
                color: kWarn,
                bg: kWarnBg,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Approved',
                value: '$_approvedClaims',
                sub: 'This month',
                icon: Icons.check_circle_outline,
                color: kForest,
                bg: kSuccessBg,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Salary overview
          Text(
            'SALARY OVERVIEW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _StatCard(
                label: 'Net Payable',
                value: _netPayable,
                sub: 'March 2026',
                icon: Icons.payments_outlined,
                color: kDeepBlue,
                bg: kInfoBg,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Pending Pay',
                value: '$_pendingSalaries',
                sub: '$_paidSalaries paid',
                icon: Icons.schedule,
                color: kWarn,
                bg: kWarnBg,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent claims
          Text(
            'RECENT CLAIMS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (_recentClaims.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No claims yet',
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
              final status = c['status'] as String;
              Color sc = status == 'pending'
                  ? kWarn
                  : status == 'approved'
                  ? kForest
                  : status == 'paid'
                  ? kDeepBlue
                  : kDanger;
              Color sb = status == 'pending'
                  ? kWarnBg
                  : status == 'approved'
                  ? kSuccessBg
                  : status == 'paid'
                  ? kInfoBg
                  : kDangerBg;

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
                            '${c['category']} · $date',
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
                          '₹${amount.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
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

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color, bg;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kDeepBlue,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kTealGray,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: kBlueGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
