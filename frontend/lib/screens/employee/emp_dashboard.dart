import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/reimbursement_service.dart';
import '../../services/salary_service.dart';
import '../../services/location_service.dart';
import '../../services/travel_service.dart';
import '../../widgets/dashboard_widgets.dart';

class EmpDashboard extends StatefulWidget {
  final UserModel user;
  const EmpDashboard({super.key, required this.user});

  @override
  State<EmpDashboard> createState() => _EmpDashboardState();
}

class _EmpDashboardState extends State<EmpDashboard> {
  bool _isOnDuty = false;
  bool _alreadyDone = false;
  bool _dutyToggling = false;
  bool _locationSharing = false;
  bool _loading = true;
  String _checkInTime = '--:--';
  String _checkOutTime = '--:--';
  String _todayStatus = '';
  String? _liveLocationName;
  int _daysPresent = 0;
  String _netSalary = '—';
  int _claimsPending = 0;
  String _claimsPaid = '₹0';
  int _travelCount = 0;
  List<dynamic> _recentClaims = [];
  Timer? _autoCheckoutTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _autoCheckoutTimer?.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _hhmm(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // The server checks everyone out at 6:30 PM IST; reload just after so the
  // screen reflects it and location sharing stops.
  void _scheduleAutoCheckoutRefresh() {
    _autoCheckoutTimer?.cancel();
    final left = AttendanceService.untilAutoCheckout();
    if (!_isOnDuty || left == null) return;
    _autoCheckoutTimer = Timer(left + const Duration(seconds: 5), () {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final today = await AttendanceService.getToday();
      if (today != null) {
        final checkedIn = today['checked_in_at'] != null;
        final checkedOut = today['checked_out_at'] != null;
        if (checkedIn) _checkInTime = _hhmm(today['checked_in_at']);
        if (checkedOut) _checkOutTime = _hhmm(today['checked_out_at']);

        _todayStatus = today['status']?.toString() ?? '';
        _isOnDuty = checkedIn && !checkedOut;
        _alreadyDone = checkedIn && checkedOut;

        if (_isOnDuty) {
          if (!LocationService.isTracking) {
            try {
              await LocationService.startTracking();
            } catch (_) {}
          }
          _locationSharing = LocationService.isTracking;
          LocationService.getCurrentLocationName().then((name) {
            if (name != null && mounted) {
              setState(() => _liveLocationName = name);
            }
          });
        } else if (_alreadyDone) {
          LocationService.stopTracking();
          _locationSharing = false;
        }
      } else {
        _isOnDuty = false;
        _alreadyDone = false;
        _todayStatus = '';
        _checkInTime = '--:--';
        _checkOutTime = '--:--';
      }
      _scheduleAutoCheckoutRefresh();

      final now = DateTime.now();
      final history = await AttendanceService.getMyHistory(
        month: now.month,
        year: now.year,
      );
      final present = history
          .where((h) => h['status'] == 'present' || h['status'] == 'late')
          .length;
      final salary = await SalaryService.getMySalary(now.month, now.year);
      final claims = await ReimbursementService.getMyClaims();
      final pending = claims.where((c) => c['status'] == 'pending').toList();
      final paid = claims.where((c) => c['status'] == 'paid').toList();
      final paidTotal = paid.fold(
        0.0,
        (s, c) => s + (c['amount'] as num).toDouble(),
      );

      int travelCount = 0;
      try {
        final travel = await TravelService.getMyRequests();
        travelCount = travel.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _daysPresent = present;
          _netSalary = salary != null
              ? '₹${SalaryService.netOf(salary).toStringAsFixed(0)}'
              : '—';
          _claimsPending = pending.length;
          _claimsPaid = '₹${paidTotal.toStringAsFixed(0)}';
          _travelCount = travelCount;
          _recentClaims = claims.take(3).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleDuty() async {
    if (_dutyToggling || _alreadyDone) return;
    setState(() => _dutyToggling = true);
    try {
      if (_isOnDuty) {
        await AttendanceService.checkOut();
        LocationService.stopTracking();
        _snack('Checked out successfully', kForest);
      } else {
        // 1. Mandatory location check
        final pos = await LocationService.ensureLocationForCheckIn();

        // 2. Check in with coordinates. The place name is looked up afterwards
        // so a slow lookup cannot delay the check-in time.
        final att = await AttendanceService.checkIn(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );

        // 3. Start location tracking
        try {
          await LocationService.startTracking();
        } catch (_) {}

        final isLate = att['status']?.toString() == 'late';
        _snack(
          isLate
              ? 'Checked in (Late - after 10:45 AM)'
              : 'Checked in successfully',
          isLate ? kWarn : kForest,
        );
      }
      await _loadData();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kDanger);
      // The server may have auto checked out already; resync the screen
      await _loadData();
    }
    if (mounted) setState(() => _dutyToggling = false);
  }

  Future<void> _toggleLocation() async {
    if (_locationSharing) {
      LocationService.stopTracking();
      setState(() => _locationSharing = false);
      return;
    }
    try {
      await LocationService.startTracking();
      final place = await LocationService.getCurrentLocationName();
      if (!mounted) return;
      setState(() {
        _locationSharing = true;
        if (place != null) _liveLocationName = place;
      });
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    final isDesktop = Responsive.isDesktop(context);

    return RefreshIndicator(
      color: kDeepBlue,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: ContentCap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildDutyCard(),
              const SizedBox(height: 24),
              const DashSectionHeader('This month'),
              const SizedBox(height: 12),
              _buildStatsGrid(isDesktop),
              const SizedBox(height: 24),
              const DashSectionHeader('Recent claims'),
              const SizedBox(height: 12),
              _buildRecentClaims(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero: greeting + today's times ───────────────────────────────────────────
  Widget _buildHero() {
    final statusLabel = _alreadyDone
        ? 'Completed'
        : _isOnDuty
        ? (_todayStatus == 'late' ? 'On duty · Late' : 'On duty')
        : 'Off duty';
    final statusColor = _alreadyDone
        ? const Color(0xFF9CC9F0)
        : _isOnDuty
        ? const Color(0xFF68D391)
        : const Color(0xFFF6AD8F);

    return DashHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      widget.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              HeroChip(
                widget.user.designation ?? 'Employee',
                icon: Icons.badge_outlined,
              ),
              HeroChip(
                _liveLocationName ?? widget.user.location ?? '—',
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroTime(
                  label: 'Check in',
                  value: _checkInTime,
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroTime(
                  label: 'Check out',
                  value: _checkOutTime,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Attendance action + location sharing ─────────────────────────────────────
  Widget _buildDutyCard() {
    final String attSubtitle;
    if (_alreadyDone) {
      attSubtitle = 'Completed · out at $_checkOutTime';
    } else if (_isOnDuty) {
      attSubtitle = 'Checked in at $_checkInTime';
    } else {
      attSubtitle = 'Not checked in yet';
    }

    final Color btnColor = _alreadyDone
        ? kBlueGray
        : _isOnDuty
        ? kDanger
        : kForest;
    final String btnText = _alreadyDone
        ? 'Done'
        : _isOnDuty
        ? 'Check Out'
        : 'Check In';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dashCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _IconChip(
                icon: Icons.access_time_rounded,
                color: kDeepBlue,
                bg: kInfoBg,
              ),
              const SizedBox(width: 12),
              Expanded(child: _RowInfo('Attendance', attSubtitle)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_dutyToggling || _alreadyDone) ? null : _toggleDuty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD9E1E7),
                  disabledForegroundColor: kTealGray,
                  elevation: 0,
                  minimumSize: const Size(104, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _dutyToggling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        btnText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: kTealGray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Late after 10:45 AM · Auto check-out at 6:30 PM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kTealGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE6ECF1)),
          ),
          Row(
            children: [
              _IconChip(
                icon: Icons.my_location_rounded,
                color: kForest,
                bg: kSuccessBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RowInfo(
                  'Location Sharing',
                  _locationSharing
                      ? '${_liveLocationName ?? widget.user.location ?? "Live"} — active'
                      : 'Location off',
                ),
              ),
              const SizedBox(width: 8),
              _Toggle(value: _locationSharing, onTap: _toggleLocation),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDesktop) {
    final cards = [
      DashStatCard(
        label: 'Days Present',
        value: '$_daysPresent',
        icon: Icons.check_circle_outline,
        color: kForest,
        bg: kSuccessBg,
      ),
      DashStatCard(
        label: 'Claims Pending',
        value: '$_claimsPending',
        icon: Icons.receipt_long_outlined,
        color: kWarn,
        bg: kWarnBg,
      ),
      DashStatCard(
        label: 'Claims Paid',
        value: _claimsPaid,
        icon: Icons.done_all,
        color: kForest,
        bg: kSuccessBg,
      ),
      DashStatCard(
        label: 'Salary',
        value: _netSalary,
        icon: Icons.payments_outlined,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
      DashStatCard(
        label: 'Travel Requests',
        value: '$_travelCount',
        icon: Icons.flight_outlined,
        color: kDeepBlue,
        bg: kInfoBg,
      ),
    ];

    return DashStatGrid(maxColumns: 5, children: cards);
  }

  Widget _buildRecentClaims() {
    if (_recentClaims.isEmpty) {
      return const DashEmptyState(
        'No claims yet',
        icon: Icons.receipt_long_outlined,
      );
    }
    return Column(
      children: _recentClaims.map((c) {
        final desc = (c['description'] ?? '').toString();
        final created = (c['created_at'] ?? '').toString();
        final date = created.length >= 10 ? created.substring(0, 10) : created;
        return DashListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kInfoBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: kDeepBlue,
            ),
          ),
          title: (c['category'] ?? '').toString(),
          subtitle: Text(
            desc.isEmpty ? date : '$desc · $date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTealGray),
          ),
          trailingText: '₹${(c['amount'] as num).toStringAsFixed(0)}',
          status: (c['status'] ?? '').toString(),
        );
      }).toList(),
    );
  }
}

class _HeroTime extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _HeroTime({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  const _IconChip({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: 20, color: color),
  );
}

class _RowInfo extends StatelessWidget {
  final String title, sub;
  const _RowInfo(this.title, this.sub);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: kDeepBlue,
        ),
      ),
      Text(
        sub,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTealGray),
      ),
    ],
  );
}

class _Toggle extends StatelessWidget {
  final bool value;
  final VoidCallback? onTap;
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
