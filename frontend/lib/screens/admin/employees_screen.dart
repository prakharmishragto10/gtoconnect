import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';
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
                          fillColor: kOffWhite.withOpacity(0.5),
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
                              color: kOffWhite.withOpacity(0.5),
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
        fillColor: kOffWhite.withOpacity(0.5),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
              InkWell(
                onTap: _showAddEmployeeSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: kDeepBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Add Employee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
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
          const SizedBox(height: 8),
          Text(
            '${_employees.length} team members',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
          const SizedBox(height: 16),

          if (_employees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No employees found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            )
          else
            ..._employees.map(
              (e) => _EmployeeCard(
                emp: e,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailScreen(
                        emp: e as Map<String, dynamic>,
                        onDeleted: _loadEmployees,
                        onUpdated: _loadEmployees,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> emp;
  final VoidCallback onTap;
  const _EmployeeCard({required this.emp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = emp['name'] ?? '—';
    final role = emp['designation'] ?? '—';
    final loc = emp['location'] ?? '—';
    final salary = emp['base_salary'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kInfoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  (name as String).isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kDeepBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                    role.isNotEmpty ? role : '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: kTealGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: kBlueGray,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        loc.isNotEmpty ? loc : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: kBlueGray,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 11,
                        color: kBlueGray,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        salary != null ? '₹${salary.toString()}' : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kDeepBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kSuccessBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kForest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
