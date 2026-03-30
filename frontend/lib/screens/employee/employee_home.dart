import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../../services/location_service.dart';
import '../login_screen.dart';
import 'emp_attendance.dart';
import 'emp_reimbursement.dart';
import 'emp_salary.dart';

class EmployeeHome extends StatefulWidget {
  final UserModel user;
  const EmployeeHome({super.key, required this.user});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  int _currentIndex = 0;

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Screens — built lazily so they don't rebuild on nav switch
  late final _screens = [
    EmpDashboard(user: widget.user),
    EmpAttendance(user: widget.user),
    EmpReimbursement(user: widget.user),
    EmpSalary(user: widget.user),
  ];

  static const _navItems = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.access_time_outlined, Icons.access_time, 'Attendance'),
    (Icons.receipt_outlined, Icons.receipt, 'Claims'),
    (Icons.payments_outlined, Icons.payments, 'Salary'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      // ── Top app bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2640),
        elevation: 0,
        toolbarHeight: 52,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'GTO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kBlueGray,
                ),
              ),
              TextSpan(
                text: 'Connect',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // On desktop: show user name + avatar in appbar
          if (isDesktop) ...[
            _AppBarAvatar(name: widget.user.name),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 15, color: kBlueGray),
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

      // ── Body: sidebar on desktop, stack on mobile ────────────────────────
      body: isDesktop
          ? _DesktopLayout(
              currentIndex: _currentIndex,
              onNav: (i) => setState(() => _currentIndex = i),
              child: _screens[_currentIndex],
            )
          : _screens[_currentIndex],

      // ── Bottom nav: mobile only ──────────────────────────────────────────
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF0C2640),
              unselectedItemColor: kBlueGray,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
              items: _navItems
                  .map(
                    (n) => BottomNavigationBarItem(
                      icon: Icon(n.$1),
                      activeIcon: Icon(n.$2),
                      label: n.$3,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ── Desktop: sidebar + content ───────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNav;
  final Widget child;

  static const _navItems = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.access_time_outlined, Icons.access_time, 'Attendance'),
    (Icons.receipt_outlined, Icons.receipt, 'Claims'),
    (Icons.payments_outlined, Icons.payments, 'Salary'),
  ];

  const _DesktopLayout({
    required this.currentIndex,
    required this.onNav,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 200,
          color: const Color(0xFF0C2640),
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
                        color: active
                            ? const Color(0xFF4DA8DA)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        active ? item.$2 : item.$1,
                        size: 18,
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.$3,
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

        // Content area — capped width, centered
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

// ── Employee Dashboard ────────────────────────────────────────────────────────
class EmpDashboard extends StatefulWidget {
  final UserModel user;
  const EmpDashboard({super.key, required this.user});

  @override
  State<EmpDashboard> createState() => _EmpDashboardState();
}

class _EmpDashboardState extends State<EmpDashboard> {
  bool _isOnDuty = false;
  bool _locationSharing = false;
  bool _loading = true;
  String _checkInTime = '--:--';
  int _daysPresent = 0;
  String _netSalary = '—';
  int _claimsPending = 0;
  String _claimsPaid = '₹0';
  List<dynamic> _recentClaims = [];

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
        if (checkedIn && !checkedOut) {
          final dt = DateTime.parse(today['checked_in_at']).toLocal();
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          _isOnDuty = true;
        }
      }
      final history = await AttendanceService.getMyHistory();
      final present = history
          .where((h) => h['status'] == 'present' || h['status'] == 'late')
          .length;
      final now = DateTime.now();
      final salary = await SalaryService.getMySalary(now.month, now.year);
      final claims = await ReimbursementService.getMyClaims();
      final pending = claims.where((c) => c['status'] == 'pending').toList();
      final paid = claims.where((c) => c['status'] == 'paid').toList();
      final paidTotal = paid.fold(
        0.0,
        (s, c) => s + (c['amount'] as num).toDouble(),
      );

      setState(() {
        _daysPresent = present;
        _netSalary = salary != null
            ? '₹${(salary['net_salary'] as num).toStringAsFixed(0)}'
            : '—';
        _claimsPending = pending.length;
        _claimsPaid = '₹${paidTotal.toStringAsFixed(0)}';
        _recentClaims = claims.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleDuty() async {
    try {
      if (_isOnDuty) {
        await AttendanceService.checkOut();
        setState(() {
          _isOnDuty = false;
          _checkInTime = '--:--';
        });
      } else {
        final att = await AttendanceService.checkIn();
        final dt = DateTime.parse(att['checked_in_at']).toLocal();
        setState(() {
          _isOnDuty = true;
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: ContentCap(
        // ← caps width on desktop
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(isDesktop),
            const SizedBox(height: 16),
            _buildToggles(),
            const SizedBox(height: 20),
            _SectionLabel('THIS MONTH'),
            const SizedBox(height: 10),
            _buildStatsGrid(isDesktop),
            const SizedBox(height: 20),
            _SectionLabel('RECENT CLAIMS'),
            const SizedBox(height: 10),
            _buildRecentClaims(),
          ],
        ),
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────────
  Widget _buildGreeting(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2640),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isDesktop
          // Desktop: name left, duty toggle right
          ? Row(
              children: [
                Expanded(child: _greetingText()),
                _dutyToggleWidget(),
              ],
            )
          // Mobile: stacked
          : _greetingText(),
    );
  }

  Widget _greetingText() => Column(
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
      const SizedBox(height: 6),
      Row(
        children: [
          _Badge(widget.user.designation ?? 'Employee'),
          const SizedBox(width: 8),
          _Badge(widget.user.location ?? '—', icon: Icons.location_on_outlined),
        ],
      ),
    ],
  );

  Widget _dutyToggleWidget() => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _isOnDuty ? kSuccessBg : kDangerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _isOnDuty ? 'On Duty' : 'Off Duty',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _isOnDuty ? kForest : kDanger,
          ),
        ),
      ),
      const SizedBox(width: 10),
      _Toggle(value: _isOnDuty, onTap: _toggleDuty),
    ],
  );

  // ── Toggles card ────────────────────────────────────────────────────────────
  Widget _buildToggles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToggleInfo(
                'Attendance',
                _isOnDuty ? 'Checked in at $_checkInTime' : 'Not checked in',
              ),
              _dutyToggleWidget(),
            ],
          ),
          const Divider(height: 24, color: kBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToggleInfo(
                'Location Sharing',
                _locationSharing
                    ? '${widget.user.location ?? "Sharing"} — live'
                    : 'Location off',
              ),
              _Toggle(
                value: _locationSharing,
                onTap: () async {
                  if (_locationSharing) {
                    LocationService.stopTracking();
                    setState(() => _locationSharing = false);
                  } else {
                    try {
                      await LocationService.startTracking();
                      setState(() => _locationSharing = true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: kDanger,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats grid — 2 cols on mobile, 4 cols on desktop ────────────────────────
  Widget _buildStatsGrid(bool isDesktop) {
    final cards = [
      _StatData(
        'Days Present',
        '$_daysPresent',
        Icons.check_circle_outline,
        kForest,
        kSuccessBg,
      ),
      _StatData(
        'Net Salary',
        _netSalary,
        Icons.payments_outlined,
        kDeepBlue,
        kInfoBg,
      ),
      _StatData(
        'Claims Pending',
        '$_claimsPending',
        Icons.receipt_outlined,
        kWarn,
        kWarnBg,
      ),
      _StatData(
        'Claims Paid',
        _claimsPaid,
        Icons.done_all,
        kForest,
        kSuccessBg,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2, // ← key fix
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isDesktop ? 1.5 : 1.7,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _EmpStatCard(data: cards[i]),
    );
  }

  // ── Recent claims ────────────────────────────────────────────────────────────
  Widget _buildRecentClaims() {
    if (_recentClaims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No claims yet',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
        ),
      );
    }
    return Column(
      children: _recentClaims
          .map(
            (c) => _RecentClaimTile(
              category: c['category'] ?? '',
              desc: c['description'] ?? '',
              amount: '₹${(c['amount'] as num).toStringAsFixed(0)}',
              status: c['status'] ?? '',
              date: (c['created_at'] as String).substring(0, 10),
            ),
          )
          .toList(),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────
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

class _ToggleInfo extends StatelessWidget {
  final String title, sub;
  const _ToggleInfo(this.title, this.sub);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kDeepBlue,
        ),
      ),
      Text(
        sub,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTealGray),
      ),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Badge(this.text, {this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: kBlueGray),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kBlueGray),
        ),
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _Toggle({required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 26,
      decoration: BoxDecoration(
        color: value ? kForest : const Color(0xFFCDD5D5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
  );
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatData(this.label, this.value, this.icon, this.color, this.bg);
}

class _EmpStatCard extends StatelessWidget {
  final _StatData data;
  const _EmpStatCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(
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
            color: data.bg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(data.icon, size: 16, color: data.color),
        ),
        const Spacer(),
        Text(
          data.value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDeepBlue,
          ),
        ),
        Text(
          data.label,
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

class _RecentClaimTile extends StatelessWidget {
  final String category, desc, amount, status, date;
  const _RecentClaimTile({
    required this.category,
    required this.desc,
    required this.amount,
    required this.status,
    required this.date,
  });
  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final isPaid = status == 'paid';
    final sc = isPending
        ? kWarn
        : isPaid
        ? kForest
        : kDanger;
    final sb = isPending
        ? kWarnBg
        : isPaid
        ? kSuccessBg
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
            child: const Icon(
              Icons.receipt_outlined,
              size: 16,
              color: kDeepBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  '$desc · $date',
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
  }
}
