import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';

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

  String get _initials {
    final name = (_emp['name'] ?? '').toString().trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Employee',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: kDeepBlue,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${_emp['name']}"? This action cannot be undone.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await AuthService.deleteEmployee(_emp['id'].toString());
      if (mounted) {
        widget.onDeleted();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Employee deleted successfully',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: kForest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: kDanger,
          ),
        );
      }
    }
  }

  void _showEditSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _emp['name']?.toString() ?? '');
    final desigCtrl = TextEditingController(text: _emp['designation']?.toString() ?? '');
    final locCtrl = TextEditingController(text: _emp['location']?.toString() ?? '');
    final salaryCtrl = TextEditingController(text: _emp['base_salary']?.toString() ?? '');
    final upiCtrl = TextEditingController(text: _emp['upi_id']?.toString() ?? '');
    DateTime? sheetJoiningDate = _emp['joining_date'] != null
        ? DateTime.tryParse(_emp['joining_date'].toString())
        : null;
    bool saving = false;

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
                        'Edit Employee Details',
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
                      // ── Joining Date picker ──────────────────────────────────
                      StatefulBuilder(
                        builder: (_, setDateState) => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: sheetJoiningDate ?? DateTime.now(),
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
                              setDateState(() => sheetJoiningDate = picked);
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
                                        sheetJoiningDate != null
                                            ? '${sheetJoiningDate!.day.toString().padLeft(2, '0')}/${sheetJoiningDate!.month.toString().padLeft(2, '0')}/${sheetJoiningDate!.year}'
                                            : 'Tap to select date',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: sheetJoiningDate != null
                                              ? kDeepBlue
                                              : kTealGray,
                                          fontWeight: sheetJoiningDate != null
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
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => saving = true);
                                  final messenger = ScaffoldMessenger.of(context);

                                  try {
                                    final salaryVal = salaryCtrl.text.trim().isNotEmpty
                                        ? num.tryParse(salaryCtrl.text.trim())
                                        : null;

                                    final res = await AuthService.updateEmployee(
                                      _emp['id'].toString(),
                                      {
                                        'name': nameCtrl.text.trim(),
                                        'designation': desigCtrl.text.trim(),
                                        'location': locCtrl.text.trim(),
                                        'base_salary': salaryVal,
                                        'upi_id': upiCtrl.text.trim(),
                                        if (sheetJoiningDate != null)
                                          'joining_date': sheetJoiningDate!.toIso8601String().split('T')[0],
                                      },
                                    );

                                    if (mounted) {
                                      setState(() {
                                        if (res['user'] != null) {
                                          _emp = Map<String, dynamic>.from(res['user']);
                                        } else {
                                          _emp['name'] = nameCtrl.text.trim();
                                          _emp['designation'] = desigCtrl.text.trim();
                                          _emp['location'] = locCtrl.text.trim();
                                          _emp['base_salary'] = salaryVal;
                                          _emp['upi_id'] = upiCtrl.text.trim();
                                          if (sheetJoiningDate != null) {
                                            _emp['joining_date'] = sheetJoiningDate!.toIso8601String().split('T')[0];
                                          }
                                        }
                                      });
                                      widget.onUpdated?.call();
                                      Navigator.pop(ctx);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Employee details updated successfully',
                                            style: GoogleFonts.plusJakartaSans(),
                                          ),
                                          backgroundColor: kForest,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => saving = false);
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
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
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
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kBorder),
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
    final name = _emp['name']?.toString() ?? '—';
    final email = _emp['email']?.toString() ?? '—';
    final designation = _emp['designation']?.toString() ?? '—';
    final location = _emp['location']?.toString() ?? '—';
    final salary = _emp['base_salary'];
    final upiId = _emp['upi_id']?.toString() ?? '—';
    final role = _emp['role']?.toString() ?? 'employee';
    final joiningDateRaw = _emp['joining_date'];
    final joiningDate = joiningDateRaw != null
        ? DateTime.tryParse(joiningDateRaw.toString())
        : null;
    final joiningDateStr = joiningDate != null
        ? '${joiningDate.day.toString().padLeft(2, '0')}/${joiningDate.month.toString().padLeft(2, '0')}/${joiningDate.year}'
        : '—';

    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Employee Profile',
          style: GoogleFonts.plusJakartaSans(
            color: kDeepBlue,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: kDeepBlue),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
        actions: [
          IconButton(
            onPressed: _showEditSheet,
            icon: const Icon(Icons.edit_outlined, color: kDeepBlue),
            tooltip: 'Edit Details',
          ),
          if (_deleting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kDanger,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: kDanger),
              tooltip: 'Delete Employee',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + Name ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kInfoBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: kDeepBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designation.isNotEmpty ? designation : '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTealGray,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccessBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kForest,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Details ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INFORMATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kTealGray,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: _showEditSheet,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: kDeepBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kDeepBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: location.isNotEmpty ? location : '—',
                  ),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Base Salary',
                    value: salary != null ? '₹${salary.toString()}' : '—',
                  ),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'UPI ID',
                    value: upiId.isNotEmpty ? upiId : '—',
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joining Date',
                    value: joiningDateStr,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Delete button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleting ? null : _confirmDelete,
                icon: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  _deleting ? 'Deleting…' : 'Delete Employee',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDanger,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kDanger.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail row widget ──────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: kBlueGray),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: kTealGray,
                    ),
                  ),
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
            ],
          ),
        ),
        if (!isLast)
          Divider(color: kBorder, height: 1, thickness: 1),
      ],
    );
  }
}
