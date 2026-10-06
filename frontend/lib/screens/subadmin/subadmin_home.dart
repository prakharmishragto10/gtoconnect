import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/dashboard_widgets.dart';
import '../admin/claims_screen.dart';
import '../admin/salary_screen.dart';
import '../admin/attendance_screen.dart';

const List<ShellNavItem> _navItems = [
  (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
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
  late final List<Widget> _screens = [
    SubAdminDashboard(user: widget.user),
    const ClaimsScreen(),
    const SalaryScreen(),
    const AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(user: widget.user, items: _navItems, screens: _screens);
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String _monthYear(DateTime dt) => '${_months[dt.month - 1]} ${dt.year}';

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

      if (!mounted) return;
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
      if (mounted) setState(() => _loading = false);
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
            const DashSectionHeader('Claims overview'),
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
            '${widget.user.designation ?? 'Finance'} · GTO Connect',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kBlueGray),
          ),
        ),
      ],
    );

    final quickStats = isDesktop
        ? Row(
            children: [
              HeroStat(label: 'Pending Claims', value: '$_pendingClaims'),
              const SizedBox(width: 10),
              HeroStat(label: 'Approved', value: '$_approvedClaims'),
              const SizedBox(width: 10),
              HeroStat(label: 'Net Payable', value: _netPayable),
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
        sub: 'Awaiting payment',
        icon: Icons.check_circle_outline,
        color: kForest,
        bg: kSuccessBg,
      ),
      (
        label: 'Net Payable',
        value: _netPayable,
        sub: _monthYear(DateTime.now()),
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

    return DashStatGrid(
      maxColumns: 4,
      withSub: true,
      children: [for (final c in cards) DashStatCard(
          label: c.label,
          value: c.value,
          sub: c.sub,
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
        const DashSectionHeader('Recent claims'),
        const SizedBox(height: 10),
        if (_recentClaims.isEmpty)
          const DashEmptyState(
            'No claims yet',
            icon: Icons.receipt_long_outlined,
          )
        else
          ..._recentClaims.map((c) {
            final submitter = c['submitter'] as Map<String, dynamic>?;
            final name = submitter?['name'] ?? 'Unknown';
            final amount = (c['amount'] as num).toDouble();
            final date = (c['created_at'] as String).substring(0, 10);
            final status = c['status'] as String;

            return DashListTile(
              leading: InitialAvatar(name.toString()),
              title: name.toString(),
              subtitle: Text(
                '${c['category']} · $date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: kTealGray,
                ),
              ),
              trailingText: '₹${amount.toStringAsFixed(0)}',
              status: status,
            );
          }),
      ],
    );
  }
}

// ── ContentCap — caps max width on wide screens ───────────────────────────────
