import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/dashboard_widgets.dart';
import 'employee_history_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> emp;
  final VoidCallback onDeleted;
  final VoidCallback? onUpdated;

  const EmployeeDetailScreen({
    super.key,
    required this.emp,
    required this.onDeleted,
    this.onUpdated,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late Map<String, dynamic> _emp;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _emp = Map<String, dynamic>.from(widget.emp);
  }

  String _text(String key) => (_emp[key] ?? '').toString().trim();
  String _orDash(String key) => _text(key).isEmpty ? '—' : _text(key);

  DateTime? get _joiningDate => DateTime.tryParse(_text('joining_date'));

  String get _salaryText {
    final s = _emp['base_salary'];
    if (s is! num) return '—';
    return '₹${NumberFormat.decimalPattern('en_IN').format(s)}';
  }

  // "2y 3m" style time with the company, or null without a joining date
  String? get _tenure {
    final joined = _joiningDate;
    if (joined == null) return null;
    final now = DateTime.now();
    if (joined.isAfter(now)) return 'Starts soon';
    var months = (now.year - joined.year) * 12 + now.month - joined.month;
    if (now.day < joined.day) months--;
    if (months < 1) return 'Under a month';
    final y = months ~/ 12;
    final m = months % 12;
    return [if (y > 0) '${y}y', if (m > 0) '${m}m'].join(' ');
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

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _snack('$label copied', kShellBlue);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete employee?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: kShellBlueDark,
          ),
        ),
        content: Text(
          '"${_orDash('name')}" will be removed permanently. This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTealGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: kTealGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await AuthService.deleteEmployee(_emp['id'].toString());
      if (!mounted) return;
      widget.onDeleted();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Employee deleted successfully',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: kForest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _snack(e.toString().replaceAll('Exception: ', ''), kDanger);
    }
  }

  // Bottom sheet on phones, centred dialog on wide screens
  Future<void> _openEdit() async {
    final isDesktop = Responsive.isDesktop(context);
    final Map<String, dynamic>? updated;

    if (isDesktop) {
      updated = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _EditProfileForm(emp: _emp, twoColumns: true),
          ),
        ),
      );
    } else {
      updated = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _EditProfileForm(emp: _emp, twoColumns: false),
        ),
      );
    }

    if (updated == null || !mounted) return;
    setState(() => _emp = updated!);
    widget.onUpdated?.call();
    _snack('Profile updated', kForest);
  }

  void _openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeHistoryScreen(
          employeeId: _emp['id'].toString(),
          employeeName: _orDash('name'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final joined = _joiningDate;
    final joinedText = joined == null
        ? '—'
        : DateFormat('dd MMM yyyy').format(joined);

    return Scaffold(
      backgroundColor: kShellBg,
      appBar: AppBar(
        backgroundColor: kShellBlue,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Employee Profile',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: ContentCap(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDesktop),
              const SizedBox(height: 16),

              // ── Quick facts ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _FactTile(
                      icon: Icons.payments_outlined,
                      label: 'Base salary',
                      value: _salaryText,
                      color: kShellBlue,
                      bg: kInfoBg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FactTile(
                      icon: Icons.workspace_premium_outlined,
                      label: 'With the team',
                      value: _tenure ?? '—',
                      color: kForest,
                      bg: kSuccessBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Information ─────────────────────────────────────────────
              const DashSectionHeader('Information'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: dashCardDecoration(),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _orDash('email'),
                      onCopy: _text('email').isEmpty
                          ? null
                          : () => _copy('Email', _text('email')),
                    ),
                    _InfoRow(
                      icon: Icons.work_outline,
                      label: 'Designation',
                      value: _orDash('designation'),
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: _orDash('location'),
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joining date',
                      value: joinedText,
                    ),
                    _InfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'UPI ID',
                      value: _orDash('upi_id'),
                      onCopy: _text('upi_id').isEmpty
                          ? null
                          : () => _copy('UPI ID', _text('upi_id')),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Attendance shortcut ─────────────────────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAttendance,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: dashCardDecoration(),
                    child: Row(
                      children: [
                        const _IconChip(
                          icon: Icons.access_time_rounded,
                          color: kShellBlue,
                          bg: kInfoBg,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance history',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kShellBlueDark,
                                ),
                              ),
                              Text(
                                'Check-ins, late days and check-out times',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: kTealGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: kTealGray),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Remove employee ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kDangerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDanger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remove employee',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kDanger,
                            ),
                          ),
                          Text(
                            'Deletes this account permanently.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: kDanger.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kDanger,
                              ),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        _deleting ? 'Deleting…' : 'Delete',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDanger,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kDanger),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient header: avatar, name, chips, edit button ──────────────────────
  Widget _buildHeader(bool isDesktop) {
    final avatar = Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(
        initialsOf(_text('name')),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    final role = _text('role').isEmpty ? 'employee' : _text('role');
    final align = isDesktop
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    final details = Column(
      crossAxisAlignment: align,
      children: [
        Text(
          _orDash('name'),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _text('designation').isEmpty
              ? 'No designation set'
              : _text('designation'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            HeroChip(
              '${role[0].toUpperCase()}${role.substring(1)}',
              icon: Icons.verified_user_outlined,
            ),
            if (_text('location').isNotEmpty)
              HeroChip(_text('location'), icon: Icons.location_on_outlined),
          ],
        ),
      ],
    );

    final editButton = ElevatedButton.icon(
      onPressed: _openEdit,
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: Text(
        'Edit profile',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: kShellBlueDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );

    return DashHero(
      child: isDesktop
          ? Row(
              children: [
                avatar,
                const SizedBox(width: 20),
                Expanded(child: details),
                const SizedBox(width: 12),
                editButton,
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  avatar,
                  const SizedBox(height: 14),
                  details,
                  const SizedBox(height: 16),
                  editButton,
                ],
              ),
            ),
    );
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────────
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

class _FactTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bg;

  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: dashCardDecoration(),
    child: Row(
      children: [
        _IconChip(icon: icon, color: color, bg: bg),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kShellBlueDark,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: kTealGray,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onCopy;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: kShellBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kTealGray,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kShellBlueDark,
                    ),
                  ),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                onPressed: onCopy,
                tooltip: 'Copy $label',
                icon: const Icon(Icons.copy_rounded, size: 17, color: kTealGray),
              ),
          ],
        ),
      ),
      if (!isLast) const Divider(height: 1, color: Color(0xFFE6ECF1)),
    ],
  );
}

// ── Edit profile form (shown in a sheet or dialog) ───────────────────────────
// Pops with the updated employee map on success.
class _EditProfileForm extends StatefulWidget {
  final Map<String, dynamic> emp;
  final bool twoColumns;
  const _EditProfileForm({required this.emp, required this.twoColumns});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _initial('name'));
  late final _designation = TextEditingController(text: _initial('designation'));
  late final _location = TextEditingController(text: _initial('location'));
  late final _salary = TextEditingController(text: _initial('base_salary'));
  late final _upi = TextEditingController(text: _initial('upi_id'));
  late DateTime? _joiningDate = DateTime.tryParse(_initial('joining_date'));
  bool _saving = false;
  String? _error;

  String _initial(String key) => (widget.emp[key] ?? '').toString();

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _location.dispose();
    _salary.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (picked != null && mounted) setState(() => _joiningDate = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final salary = num.tryParse(_salary.text.trim());
    final joining = _joiningDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(_joiningDate!);

    try {
      final res = await AuthService.updateEmployee(
        widget.emp['id'].toString(),
        {
          'name': _name.text.trim(),
          'designation': _designation.text.trim(),
          'location': _location.text.trim(),
          // An empty salary box keeps the current salary instead of wiping it
          'base_salary': ?salary,
          'upi_id': _upi.text.trim(),
          'joining_date': ?joining,
        },
      );
      if (!mounted) return;

      final updated = res['user'] != null
          ? Map<String, dynamic>.from(res['user'])
          : <String, dynamic>{
              ...widget.emp,
              'name': _name.text.trim(),
              'designation': _designation.text.trim(),
              'location': _location.text.trim(),
              'base_salary': ?salary,
              'upi_id': _upi.text.trim(),
              'joining_date': ?joining,
            };
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final designation = _field(
      controller: _designation,
      label: 'Designation',
      hint: 'e.g. Sales Executive',
      icon: Icons.work_outline,
    );
    final location = _field(
      controller: _location,
      label: 'Location',
      hint: 'e.g. Delhi',
      icon: Icons.location_on_outlined,
    );
    final salary = _field(
      controller: _salary,
      label: 'Base salary',
      hint: '15000',
      icon: Icons.currency_rupee,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        final n = num.tryParse(t);
        if (n == null || n < 0) return 'Enter a valid amount';
        return null;
      },
    );
    final upi = _field(
      controller: _upi,
      label: 'UPI ID',
      hint: 'name@bank',
      icon: Icons.account_balance_wallet_outlined,
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        return RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(t)
            ? null
            : 'Looks like name@bank';
      },
    );

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            decoration: const BoxDecoration(gradient: kHeroGradient),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    initialsOf(_initial('name')),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _initial('email'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // ── Fields ────────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GroupLabel('Personal'),
                    _field(
                      controller: _name,
                      label: 'Full name',
                      hint: 'Employee name',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    const _GroupLabel('Work'),
                    if (widget.twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: designation),
                          const SizedBox(width: 12),
                          Expanded(child: location),
                        ],
                      )
                    else ...[
                      designation,
                      const SizedBox(height: 14),
                      location,
                    ],
                    const SizedBox(height: 14),
                    _buildDateField(),
                    const SizedBox(height: 20),
                    const _GroupLabel('Payroll'),
                    if (widget.twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: salary),
                          const SizedBox(width: 12),
                          Expanded(child: upi),
                        ],
                      )
                    else ...[
                      salary,
                      const SizedBox(height: 14),
                      upi,
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kDanger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: kDanger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: kDanger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kShellBlueDark,
                      side: const BorderSide(color: Color(0xFFCFDAE3)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kShellBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kShellBlue.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save changes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: kBlueGray),
      prefixIcon: Icon(icon, size: 19, color: kShellBlue),
      filled: true,
      fillColor: const Color(0xFFF5F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(const Color(0xFFE1E9EF)),
      enabledBorder: border(const Color(0xFFE1E9EF)),
      focusedBorder: border(kShellBlue, 1.6),
      errorBorder: border(kDanger),
      focusedErrorBorder: border(kDanger, 1.6),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kShellBlueDark,
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kShellBlueDark,
          ),
          decoration: _decoration(hint, icon),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final hasDate = _joiningDate != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Joining date'),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _decoration('', Icons.calendar_today_outlined).copyWith(
              suffixIcon: const Icon(
                Icons.expand_more,
                size: 20,
                color: kTealGray,
              ),
            ),
            child: Text(
              hasDate
                  ? DateFormat('dd MMM yyyy').format(_joiningDate!)
                  : 'Select date',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                color: hasDate ? kShellBlueDark : kBlueGray,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: kTealGray,
      ),
    ),
  );
}
