import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/dashboard_widgets.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _loading = true;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await AuthService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showAddEmployeeSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final upiCtrl = TextEditingController();

    bool obscurePassword = true;
    bool submitting = false;
    DateTime? joiningDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add New Employee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kDeepBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: nameCtrl,
                        label: 'Full Name *',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: emailCtrl,
                        label: 'Email Address *',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: kDeepBlue,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (v.trim().length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: kTealGray,
                          ),
                          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: kTealGray),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: kTealGray,
                            ),
                            onPressed: () {
                              setSheetState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: kOffWhite.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kDeepBlue, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: desigCtrl,
                        label: 'Designation / Role',
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: locCtrl,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: salaryCtrl,
                        label: 'Base Salary (₹)',
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (double.tryParse(v.trim()) == null) {
                              return 'Enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: upiCtrl,
                        label: 'UPI ID',
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 12),
                      // ── Joining Date picker ─────────────────────────────────
                      StatefulBuilder(
                        builder: (_, setDateState) => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: joiningDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: kDeepBlue,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setDateState(() => joiningDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: kOffWhite.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: kTealGray,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Joining Date',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: kTealGray,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        joiningDate != null
                                            ? '${joiningDate!.day.toString().padLeft(2, '0')}/${joiningDate!.month.toString().padLeft(2, '0')}/${joiningDate!.year}'
                                            : 'Tap to select date',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: joiningDate != null
                                              ? kDeepBlue
                                              : kTealGray,
                                          fontWeight: joiningDate != null
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: kTealGray,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => submitting = true);
                                  final messenger = ScaffoldMessenger.of(context);

                                  try {
                                    final salaryVal = salaryCtrl.text.trim().isNotEmpty
                                        ? num.tryParse(salaryCtrl.text.trim())
                                        : null;

                                    await AuthService.createEmployee(
                                      name: nameCtrl.text.trim(),
                                      email: emailCtrl.text.trim(),
                                      password: passwordCtrl.text.trim(),
                                      designation: desigCtrl.text.trim(),
                                      location: locCtrl.text.trim(),
                                      baseSalary: salaryVal,
                                      upiId: upiCtrl.text.trim(),
                                      joiningDate: joiningDate,
                                    );

                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      _loadEmployees();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Employee created successfully',
                                            style: GoogleFonts.plusJakartaSans(),
                                          ),
                                          backgroundColor: kForest,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => submitting = false);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll('Exception: ', ''),
                                          style: GoogleFonts.plusJakartaSans(),
                                        ),
                                        backgroundColor: kDanger,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDeepBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Create Employee',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: kDeepBlue,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
        prefixIcon: Icon(icon, size: 18, color: kTealGray),
        filled: true,
        fillColor: kOffWhite.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDeepBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    final isDesktop = Responsive.isDesktop(context);

    return ValueListenableBuilder<String>(
      valueListenable: shellSearch,
      builder: (context, query, _) {
        final rows = _visibleEmployees(query);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Toolbar: Sort · Filter · Add ─────────────────────────────
              Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Sort',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (v) => setState(() => _sortBy = v),
                    itemBuilder: (_) => [
                      for (final o in _sortOptions.entries)
                        CheckedPopupMenuItem<String>(
                          value: o.key,
                          checked: _sortBy == o.key,
                          child: Text(
                            o.value,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                    ],
                    child: const ShellPill(icon: Icons.swap_vert, label: 'Sort'),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Filter by location',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (v) => setState(
                      () => _locationFilter = v == _allLocations ? null : v,
                    ),
                    itemBuilder: (_) => [
                      for (final loc in [_allLocations, ..._locations])
                        CheckedPopupMenuItem<String>(
                          value: loc,
                          checked: (_locationFilter ?? _allLocations) == loc,
                          child: Text(
                            loc,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                    ],
                    child: ShellPill(
                      icon: Icons.filter_alt_outlined,
                      label: _locationFilter ?? 'Filter',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showAddEmployeeSheet,
                    borderRadius: BorderRadius.circular(22),
                    child: ShellPill(
                      icon: Icons.person_add_alt_1_outlined,
                      label: isDesktop ? 'Add Employee' : 'Add',
                    ),
                  ),
                ],
              ),
              if (!isDesktop) ...[
                const SizedBox(height: 12),
                const ShellSearchField(fill: Color(0xFFF4F8FA)),
              ],
              const SizedBox(height: 16),

              // ── Table ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _TeamHeaderRow(isDesktop: isDesktop),
                    const Divider(height: 1, color: Color(0xFFDCE7EE)),
                    const SizedBox(height: 6),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _employees.isEmpty
                              ? 'No employees yet'
                              : 'No employees match your search',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: kTealGray,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < rows.length; i++)
                        _TeamRow(
                          emp: rows[i],
                          striped: i.isOdd,
                          isDesktop: isDesktop,
                          onTap: () => _openEmployee(rows[i]),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${rows.length} of ${_employees.length} team members',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: kTealGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sort / filter / search ─────────────────────────────────────────────────
  static const _allLocations = 'All locations';
  static const _sortOptions = {
    'name': 'Name (A–Z)',
    'designation': 'Designation',
    'joining_date': 'Start date (newest)',
    'base_salary': 'Salary (highest)',
  };

  String _sortBy = 'name';
  String? _locationFilter;

  List<String> get _locations {
    final set = <String>{};
    for (final e in _employees) {
      final loc = (e['location'] ?? '').toString().trim();
      if (loc.isNotEmpty) set.add(loc);
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> _visibleEmployees(String query) {
    final q = query.trim().toLowerCase();
    String text(Map e, String key) => (e[key] ?? '').toString();

    final rows = _employees
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) {
          if (_locationFilter != null &&
              text(e, 'location').trim() != _locationFilter) {
            return false;
          }
          if (q.isEmpty) return true;
          return ['name', 'email', 'designation', 'location'].any(
            (k) => text(e, k).toLowerCase().contains(q),
          );
        })
        .toList();

    rows.sort((a, b) {
      switch (_sortBy) {
        case 'base_salary':
          final sa = (a['base_salary'] as num?) ?? -1;
          final sb = (b['base_salary'] as num?) ?? -1;
          return sb.compareTo(sa);
        case 'joining_date':
          return text(b, 'joining_date').compareTo(text(a, 'joining_date'));
        default:
          return text(a, _sortBy).toLowerCase().compareTo(
            text(b, _sortBy).toLowerCase(),
          );
      }
    });
    return rows;
  }

  Future<void> _openEmployee(Map<String, dynamic> emp) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(
          emp: emp,
          onDeleted: _loadEmployees,
          onUpdated: _loadEmployees,
        ),
      ),
    );
  }
}

// Column widths shared by the header and the rows
const _colName = 5;
const _colDesignation = 4;
const _colLocation = 4;
const _colStart = 3;
const _colSalary = 3;

class _TeamHeaderRow extends StatelessWidget {
  final bool isDesktop;
  const _TeamHeaderRow({required this.isDesktop});

  Widget _cell(String label, int flex, {bool end = false}) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: kShellBlue,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      children: [
        _cell('FULL NAME', isDesktop ? _colName : 6),
        if (isDesktop) ...[
          _cell('DESIGNATION', _colDesignation),
          _cell('LOCATION', _colLocation),
          _cell('START DATE', _colStart),
        ],
        _cell('SALARY', _colSalary, end: !isDesktop),
      ],
    ),
  );
}

class _TeamRow extends StatelessWidget {
  final Map<String, dynamic> emp;
  final bool striped, isDesktop;
  final VoidCallback onTap;

  const _TeamRow({
    required this.emp,
    required this.striped,
    required this.isDesktop,
    required this.onTap,
  });

  String _orDash(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String get _startDate {
    final dt = DateTime.tryParse((emp['joining_date'] ?? '').toString());
    return dt == null ? '—' : DateFormat('dd.MM.yyyy').format(dt);
  }

  String get _salary {
    final s = emp['base_salary'];
    if (s is! num) return '—';
    return '₹${NumberFormat.decimalPattern('en_IN').format(s)}';
  }

  Widget _cell(String text, int flex, {bool end = false}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kShellBlueDark,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final name = _orDash(emp['name']);

    return Material(
      color: striped ? const Color(0xFFD9E9F2) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: isDesktop ? _colName : 6,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: kShellBlue,
                      child: Text(
                        initialsOf(name),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kShellBlueDark,
                            ),
                          ),
                          // Phones have no designation column, so show it here
                          if (!isDesktop)
                            Text(
                              _orDash(emp['designation']),
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
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              if (isDesktop) ...[
                _cell(_orDash(emp['designation']), _colDesignation),
                _cell(_orDash(emp['location']), _colLocation),
                _cell(_startDate, _colStart),
              ],
              _cell(_salary, _colSalary, end: !isDesktop),
            ],
          ),
        ),
      ),
    );
  }
}
