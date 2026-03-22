import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';

class EmpAttendance extends StatefulWidget {
  final UserModel user;
  const EmpAttendance({super.key, required this.user});

  @override
  State<EmpAttendance> createState() => _EmpAttendanceState();
}

class _EmpAttendanceState extends State<EmpAttendance> {
  bool _loading = true;
  bool _isOnDuty = false;
  bool _alreadyDone = false;
  bool _locationOn = false;
  bool _toggling = false;
  String _checkInTime = '--:--';
  String _checkOutTime = '--:--';
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = await AttendanceService.getToday();
      final history = await AttendanceService.getMyHistory();

      if (today != null) {
        final checkedIn = today['checked_in_at'] != null;
        final checkedOut = today['checked_out_at'] != null;

        if (checkedIn) {
          final dt = DateTime.parse(today['checked_in_at']).toLocal();
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
        if (checkedOut) {
          final dt = DateTime.parse(today['checked_out_at']).toLocal();
          _checkOutTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }

        _isOnDuty = checkedIn && !checkedOut;
        _alreadyDone = checkedIn && checkedOut;
      }

      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAttendance() async {
    if (_toggling || _alreadyDone) return;
    setState(() => _toggling = true);

    try {
      if (_isOnDuty) {
        await AttendanceService.checkOut();
        final now = DateTime.now();
        setState(() {
          _isOnDuty = false;
          _alreadyDone = true;
          _checkOutTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        });
        _showSnack('Checked out successfully', kForest);
      } else {
        final att = await AttendanceService.checkIn();
        final dt = DateTime.parse(att['checked_in_at']).toLocal();
        setState(() {
          _isOnDuty = true;
          _alreadyDone = false;
          _checkInTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          _checkOutTime = '--:--';
        });
        _showSnack('Checked in successfully', kForest);
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }

    setState(() => _toggling = false);
  }

  Future<void> _toggleLocation() async {
    if (_locationOn) {
      LocationService.stopTracking();
      setState(() => _locationOn = false);
      _showSnack('Location sharing stopped', kTealGray);
    } else {
      try {
        await LocationService.startTracking();
        setState(() => _locationOn = true);
        _showSnack('Location sharing started', kForest);
      } catch (e) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), kDanger);
      }
    }
  }
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    final present = _history
        .where((h) => h['status'] == 'present' || h['status'] == 'late')
        .length;
    final absent = _history.where((h) => h['status'] == 'absent').length;
    final late = _history.where((h) => h['status'] == 'late').length;

    Color btnColor = _alreadyDone
        ? kTealGray
        : _isOnDuty
        ? const Color(0xFF8B2E2E)
        : kForest;

    String btnText = _alreadyDone
        ? 'Done for today'
        : _isOnDuty
        ? 'Check Out'
        : 'Check In';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          Text(
            'March 2026',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
          const SizedBox(height: 16),

          // Today card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kDeepBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: kBlueGray,
                          ),
                        ),
                        Text(
                          '${DateTime.now().day} Mar ${DateTime.now().year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _alreadyDone
                            ? kTealGray
                            : _isOnDuty
                            ? kForest
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _alreadyDone
                            ? 'Completed'
                            : _isOnDuty
                            ? 'On Duty'
                            : 'Off Duty',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeBox(label: 'Check In', time: _checkInTime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeBox(label: 'Check Out', time: _checkOutTime),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_toggling || _alreadyDone)
                        ? null
                        : _toggleAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kTealGray,
                      disabledForegroundColor: Colors.white70,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: _toggling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            btnText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Location toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: kBlueGray,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Sharing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _locationOn
                                ? '${widget.user.location ?? "—"} — live'
                                : 'Location off',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: kBlueGray,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleLocation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _locationOn
                                ? kForest
                                : const Color(0xFFCDD5D5),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _locationOn
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  label: 'Present',
                  value: '$present',
                  color: kForest,
                  bg: kSuccessBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryBox(
                  label: 'Absent',
                  value: '$absent',
                  color: kDanger,
                  bg: kDangerBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryBox(
                  label: 'Late',
                  value: '$late',
                  color: kWarn,
                  bg: kWarnBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryBox(
                  label: 'Total',
                  value: '${_history.length}',
                  color: kDeepBlue,
                  bg: kInfoBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Log
          Text(
            'ATTENDANCE LOG',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No attendance records yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            )
          else
            ..._history.map((h) => _HistoryRow(record: h)),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String label, time;
  const _TimeBox({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kBlueGray),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String;
    Color sc = status == 'present'
        ? kForest
        : status == 'late'
        ? kWarn
        : kDanger;
    Color sb = status == 'present'
        ? kSuccessBg
        : status == 'late'
        ? kWarnBg
        : kDangerBg;

    String formatTime(String? t) {
      if (t == null) return '--:--';
      final dt = DateTime.parse(t).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final checkIn = formatTime(record['checked_in_at']);
    final checkOut = formatTime(record['checked_out_at']);
    final date = record['date'] as String;

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sb,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              status == 'present'
                  ? Icons.check_circle_outline
                  : status == 'late'
                  ? Icons.watch_later_outlined
                  : Icons.cancel_outlined,
              size: 18,
              color: sc,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  'In: $checkIn  ·  Out: $checkOut',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: kTealGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}
