import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../login_screen.dart';
import '../admin/claims_screen.dart';
import '../admin/salary_screen.dart';
import '../admin/attendance_screen.dart';

// ── Nav item definition ───────────────────────────────────────────────────────
typedef _NavItem = ({IconData icon, IconData activeIcon, String label});

const List<_NavItem> _navItems = [
  (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  (icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Claims'),
  (icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Salary'),
  (
    icon: Icons.access_time_outlined,
    activeIcon: Icons.access_time,
    label: 'Attendance',
  ),
];

// ── SubAdminHome ──────────────────────────────────────────────────────────────
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
          ? _SubAdminDesktopLayout(
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
class _SubAdminDesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNav;
  final Widget child;

  const _SubAdminDesktopLayout({
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

// ── Dashboard ─────────────────────────────────────────────────────────────────
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

    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: ContentCap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(isDesktop),
            const SizedBox(height: 20),
            _SectionLabel('CLAIMS OVERVIEW'),
            const SizedBox(height: 10),
            _buildStatsGrid(isDesktop),
            const SizedBox(height: 24),
            _buildRecentClaimsSection(),
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
            '${widget.user.designation ?? 'Finance'} · GTO Connect',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kBlueGray),
          ),
        ),
      ],
    );

    final quickStats = isDesktop
        ? Row(
            children: [
              _GreetingStat(label: 'Pending Claims', value: '$_pendingClaims'),
              const SizedBox(width: 24),
              _GreetingStat(label: 'Approved', value: '$_approvedClaims'),
              const SizedBox(width: 24),
              _GreetingStat(label: 'Net Payable', value: _netPayable),
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
        label: 'Pending Claims',
        value: '$_pendingClaims',
        sub: '₹${_pendingTotal.toStringAsFixed(0)}',
        icon: Icons.pending_outlined,
        color: kWarn,
        bg: kWarnBg,
      ),
      (
        label: 'Approved',
        value: '$_approvedClaims',
        sub: 'This month',
        icon: Icons.check_circle_outline,
        color: kForest,
        bg: kSuccessBg,
      ),
      (
        label: 'Net Payable',
        value: _netPayable,
        sub: 'March 2026',
        icon: Icons.payments_outlined,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
      (
        label: 'Pending Pay',
        value: '$_pendingSalaries',
        sub: '$_paidSalaries paid',
        icon: Icons.schedule,
        color: kWarn,
        bg: kWarnBg,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.6 : 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return _StatCard(
          label: c.label,
          value: c.value,
          sub: c.sub,
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
          _EmptyState('No claims yet')
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
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kBlueGray),
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
