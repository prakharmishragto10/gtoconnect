import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../login_screen.dart';
import 'emp_attendance.dart';
import 'emp_reimbursement.dart';
import 'emp_salary.dart';
import '../../services/location_service.dart';

class EmployeeHome extends StatefulWidget {
  final UserModel user;
  const EmployeeHome({super.key, required this.user});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      EmpDashboard(user: widget.user),
      EmpAttendance(user: widget.user),
      EmpReimbursement(user: widget.user),
      EmpSalary(user: widget.user),
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
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time),
            label: 'Attendance',
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
        ],
      ),
    );
  }
}

// ── Employee Dashboard ────────────────────────────────────
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
      // Today's attendance
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

      // History for present count
      final history = await AttendanceService.getMyHistory();
      final present = history
          .where((h) => h['status'] == 'present' || h['status'] == 'late')
          .length;

      // Salary
      final now = DateTime.now();
      final salary = await SalaryService.getMySalary(now.month, now.year);

      // Claims
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
    } catch (e) {
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(widget.user.designation ?? 'Employee'),
                    const SizedBox(width: 8),
                    _Badge(
                      widget.user.location ?? '—',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                // Attendance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kDeepBlue,
                          ),
                        ),
                        Text(
                          _isOnDuty
                              ? 'Checked in at $_checkInTime'
                              : 'Not checked in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: kTealGray,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isOnDuty ? kSuccessBg : kDangerBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isOnDuty ? 'On Duty' : 'Off Duty',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _isOnDuty ? kForest : kDanger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Toggle(value: _isOnDuty, onTap: _toggleDuty),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: kBorder),
                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Sharing',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kDeepBlue,
                          ),
                        ),
                        Text(
                          _locationSharing
                              ? '${widget.user.location ?? "Sharing"} — live'
                              : 'Location off',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: kTealGray,
                          ),
                        ),
                      ],
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
          ),
          const SizedBox(height: 16),

          // Stats
          Text(
            'THIS MONTH',
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
              _EmpStatCard(
                label: 'Days Present',
                value: '$_daysPresent',
                icon: Icons.check_circle_outline,
                color: kForest,
                bg: kSuccessBg,
              ),
              _EmpStatCard(
                label: 'Net Salary',
                value: _netSalary,
                icon: Icons.payments_outlined,
                color: kDeepBlue,
                bg: kInfoBg,
              ),
              _EmpStatCard(
                label: 'Claims Pending',
                value: '$_claimsPending',
                icon: Icons.receipt_outlined,
                color: kWarn,
                bg: kWarnBg,
              ),
              _EmpStatCard(
                label: 'Claims Paid',
                value: _claimsPaid,
                icon: Icons.done_all,
                color: kForest,
                bg: kSuccessBg,
              ),
            ],
          ),
          const SizedBox(height: 16),

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
            ..._recentClaims.map(
              (c) => _RecentClaimTile(
                category: c['category'] ?? '',
                desc: c['description'] ?? '',
                amount: '₹${(c['amount'] as num).toStringAsFixed(0)}',
                status: c['status'] ?? '',
                date: (c['created_at'] as String).substring(0, 10),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Badge(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
}

class _Toggle extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _Toggle({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

class _EmpStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _EmpStatCard({
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
              fontSize: 18,
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
    Color sc = isPending
        ? kWarn
        : isPaid
        ? kForest
        : kDanger;
    Color sb = isPending
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
