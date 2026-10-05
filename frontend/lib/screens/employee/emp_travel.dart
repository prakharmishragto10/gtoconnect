import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../models/user.dart';
import '../../services/travel_service.dart';

class EmpTravel extends StatefulWidget {
  final UserModel user;
  const EmpTravel({super.key, required this.user});

  @override
  State<EmpTravel> createState() => _EmpTravelState();
}

class _EmpTravelState extends State<EmpTravel> {
  bool _loading = true;
  bool _showForm = false;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> _requests = [];

  // Form controllers
  final _placeCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _workCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await TravelService.getMyRequests();
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }


  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kDeepBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: kDeepBlue,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatYMD(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_placeCtrl.text.trim().isEmpty ||
        _workCtrl.text.trim().isEmpty ||
        _reasonCtrl.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: kDanger),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await TravelService.submit(
        place: _placeCtrl.text.trim(),
        startDate: _formatYMD(_startDate!),
        endDate: _formatYMD(_endDate!),
        work: _workCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
      );
      _placeCtrl.clear();
      _workCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _showForm = false;
        _submitting = false;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Travel request submitted'),
            backgroundColor: kForest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kDanger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                  Text(
                    'Submit & track travel requests',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTealGray,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showForm ? kTealGray : kDeepBlue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showForm ? Icons.close : Icons.add,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showForm ? 'Cancel' : 'New Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inline form
          if (_showForm) ...[
            _buildForm(),
            const SizedBox(height: 20),
          ],

          // History label
          Text(
            'MY REQUESTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: kDeepBlue),
              ),
            )
          else if (_error != null)
            _errorState()
          else if (_requests.isEmpty)
            _emptyState()
          else
            ..._requests.map(_buildCard),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Travel Request',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          const SizedBox(height: 16),

          _label('Destination / Place'),
          const SizedBox(height: 6),
          _textField(_placeCtrl, 'e.g. Mumbai, Delhi', Icons.place_outlined),
          const SizedBox(height: 14),

          _label('Travel Period'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _datePicker(
                  'Start Date',
                  _startDate,
                  () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _datePicker(
                  'End Date',
                  _endDate,
                  () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _label('Work / Purpose'),
          const SizedBox(height: 6),
          _textField(
            _workCtrl,
            'Describe the work to be done',
            Icons.work_outline,
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          _label('Reason for Travel'),
          const SizedBox(height: 6),
          _textField(
            _reasonCtrl,
            'Why is this travel necessary?',
            Icons.info_outline,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDeepBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Request',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kDeepBlue,
        ),
      );

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kDeepBlue),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kBlueGray),
          prefixIcon: maxLines == 1
              ? Icon(icon, size: 18, color: kBlueGray)
              : null,
          filled: true,
          fillColor: kOffWhite,
          contentPadding: EdgeInsets.symmetric(
            horizontal: maxLines > 1 ? 14 : 0,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kDeepBlue, width: 1.5),
          ),
        ),
      );

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: kOffWhite,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: kBlueGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value != null
                      ? DateFormat('dd MMM yyyy').format(value)
                      : label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: value != null ? kDeepBlue : kBlueGray,
                    fontWeight:
                        value != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'pending';
    final place = req['place'] as String? ?? '—';
    final work = req['work'] as String? ?? '—';
    final reason = req['reason'] as String? ?? '—';
    final start = req['start_date'] as String? ?? '';
    final end = req['end_date'] as String? ?? '';
    final created = req['created_at'] as String? ?? '';

    // Calculate number of travel days
    String durationLabel = '';
    if (start.isNotEmpty && end.isNotEmpty) {
      final s = DateTime.tryParse(start);
      final e = DateTime.tryParse(end);
      if (s != null && e != null) {
        final days = e.difference(s).inDays + 1;
        durationLabel = '$days day${days == 1 ? '' : 's'}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kInfoBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kDeepBlue,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kDeepBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (durationLabel.isNotEmpty)
                        Text(
                          durationLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: kTealGray,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TravelStatusBadge(status),
              ],
            ),
          ),

          // ── Details ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date of travel (start)
                _detailTile(
                  Icons.event_outlined,
                  'Travel Date',
                  start.isNotEmpty ? _fmtDate(start) : '—',
                ),
                const SizedBox(height: 10),

                // Start → End date period
                _detailTile(
                  Icons.date_range_outlined,
                  'Period',
                  (start.isNotEmpty && end.isNotEmpty)
                      ? '${_fmtDate(start)}  →  ${_fmtDate(end)}'
                      : '—',
                ),
                const SizedBox(height: 10),

                // Place (again as a labeled row for clarity)
                _detailTile(
                  Icons.place_outlined,
                  'Place',
                  place,
                ),
                const SizedBox(height: 10),

                // Work
                _detailTile(
                  Icons.work_outline,
                  'Work / Purpose',
                  work,
                ),
                const SizedBox(height: 10),

                // Reason
                _detailTile(
                  Icons.info_outline,
                  'Reason',
                  reason,
                ),

                if (created.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailTile(
                    Icons.schedule_outlined,
                    'Submitted On',
                    _fmtDate(
                      created.length > 10 ? created.substring(0, 10) : created,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A cleaner labeled detail tile used inside the card body.
  Widget _detailTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: kOffWhite,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: kTealGray),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kBlueGray,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kDeepBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 44, color: kDanger),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: kDanger,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDeepBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.flight_outlined, size: 48, color: kBorder),
              const SizedBox(height: 12),
              Text(
                'No travel requests yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: kBlueGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "New Request" to submit one',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: kBlueGray,
                ),
              ),
            ],
          ),
        ),
      );
}
