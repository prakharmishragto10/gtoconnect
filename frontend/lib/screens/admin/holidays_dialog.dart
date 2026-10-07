import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';
import '../../services/holiday_service.dart';
import '../../widgets/app_shell.dart';

/// Shows the holidays of one month. The admin can add and remove them;
/// everyone else sees the list read-only. Returns true if anything changed,
/// so the caller can recalculate salaries.
Future<bool> showHolidaysDialog(
  BuildContext context, {
  required int month,
  required int year,
}) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => _HolidaysDialog(month: month, year: year),
  );
  return changed ?? false;
}

class _HolidaysDialog extends StatefulWidget {
  final int month, year;
  const _HolidaysDialog({required this.month, required this.year});

  @override
  State<_HolidaysDialog> createState() => _HolidaysDialogState();
}

class _HolidaysDialogState extends State<_HolidaysDialog> {
  final _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _holidays = [];
  DateTime? _pickedDate;
  bool _loading = true;
  bool _saving = false;
  bool _isAdmin = false;
  bool _changed = false;
  String? _error;

  late final DateTime _firstDay = DateTime(widget.year, widget.month, 1);
  late final DateTime _lastDay = DateTime(widget.year, widget.month + 1, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  Future<void> _load() async {
    try {
      final user = await AuthService.getCurrentUser();
      final holidays = await HolidayService.getHolidays(
        widget.month,
        widget.year,
      );
      if (!mounted) return;
      setState(() {
        _isAdmin = user?.isAdmin ?? false;
        _holidays = holidays;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _clean(e);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? _firstDay,
      firstDate: _firstDay,
      lastDate: _lastDay,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kShellBlue,
            onPrimary: Colors.white,
            onSurface: kShellBlueDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _pickedDate = picked);
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (_pickedDate == null || name.isEmpty) {
      setState(() => _error = 'Choose a date and enter the holiday name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await HolidayService.addHoliday(
        DateFormat('yyyy-MM-dd').format(_pickedDate!),
        name,
      );
      _changed = true;
      _nameCtrl.clear();
      _pickedDate = null;
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _remove(Map<String, dynamic> holiday) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await HolidayService.deleteHoliday(holiday['id'].toString());
      _changed = true;
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_firstDay);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Always hand the "changed" flag back, even on a back gesture
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                color: kShellBlue,
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Holidays',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            monthLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ── List ────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A holiday is a paid day off. Nobody is marked absent '
                        'on it and no salary is deducted.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: kTealGray,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: kShellBlue),
                          ),
                        )
                      else if (_holidays.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'No holidays marked for $monthLabel',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: kTealGray,
                            ),
                          ),
                        )
                      else
                        for (final h in _holidays) _buildHolidayRow(h),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: kDanger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Add (admin only) ────────────────────────────────────────
              if (_isAdmin) _buildAddBar(),
              if (!_loading && !_isAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  child: Text(
                    'Only the admin can add or remove holidays.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kBlueGray,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolidayRow(Map<String, dynamic> h) {
    final date = DateTime.tryParse((h['date'] ?? '').toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kInfoBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  date == null ? '—' : '${date.day}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kShellBlueDark,
                  ),
                ),
                Text(
                  date == null ? '' : DateFormat('EEE').format(date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: kTealGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (h['name'] ?? '').toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kShellBlueDark,
              ),
            ),
          ),
          if (_isAdmin)
            IconButton(
              onPressed: _saving ? null : () => _remove(h),
              tooltip: 'Remove holiday',
              icon: const Icon(Icons.delete_outline, size: 20, color: kDanger),
            ),
        ],
      ),
    );
  }

  Widget _buildAddBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE6ECF1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADD A HOLIDAY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: kTealGray,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _pickedDate == null
                      ? 'Date'
                      : DateFormat('d MMM').format(_pickedDate!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kShellBlueDark,
                  side: const BorderSide(color: Color(0xFFCFDAE3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _add(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kShellBlueDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Holiday name, e.g. Diwali',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: kBlueGray,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1E9EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1E9EF)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: kShellBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Add holiday',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
