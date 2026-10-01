import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';

/// Used for both Add and Edit.
/// Pass [emp] to pre-fill fields (edit mode). Leave null for add mode.
class EmployeeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? emp;
  final VoidCallback onSaved;

  const EmployeeFormScreen({super.key, this.emp, required this.onSaved});

  bool get isEdit => emp != null;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _designation;
  late final TextEditingController _location;
  late final TextEditingController _upiId;
  late final TextEditingController _salary;

  @override
  void initState() {
    super.initState();
    final e = widget.emp;
    _name        = TextEditingController(text: e?['name']?.toString() ?? '');
    _email       = TextEditingController(text: e?['email']?.toString() ?? '');
    _password    = TextEditingController();
    _designation = TextEditingController(text: e?['designation']?.toString() ?? '');
    _location    = TextEditingController(text: e?['location']?.toString() ?? '');
    _upiId       = TextEditingController(text: e?['upi_id']?.toString() ?? '');
    _salary      = TextEditingController(
      text: e?['base_salary'] != null ? e!['base_salary'].toString() : '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _designation.dispose();
    _location.dispose();
    _upiId.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.isEdit) {
        // Build only changed fields
        final fields = <String, dynamic>{};
        if (_name.text.trim().isNotEmpty) fields['name'] = _name.text.trim();
        if (_designation.text.trim().isNotEmpty) fields['designation'] = _designation.text.trim();
        if (_location.text.trim().isNotEmpty) fields['location'] = _location.text.trim();
        if (_upiId.text.trim().isNotEmpty) fields['upi_id'] = _upiId.text.trim();
        if (_salary.text.trim().isNotEmpty) {
          fields['base_salary'] = num.tryParse(_salary.text.trim());
        }
        await AuthService.updateEmployee(widget.emp!['id'].toString(), fields);
      } else {
        // Create new employee
        await AuthService.createEmployee(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          designation: _designation.text.trim(),
          location: _location.text.trim(),
          upiId: _upiId.text.trim(),
          baseSalary: _salary.text.trim().isNotEmpty
              ? num.tryParse(_salary.text.trim())
              : null,
        );
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Employee updated successfully'
                  : 'Employee added successfully',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: kForest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.isEdit ? 'Edit Employee' : 'Add Employee',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Basic Info'),
              const SizedBox(height: 12),
              _Field(
                controller: _name,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              _Field(
                controller: _email,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: widget.isEdit, // can't change email
                validator: (v) {
                  if (widget.isEdit) return null;
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              if (!widget.isEdit)
                _Field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.trim().length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),
              _SectionHeader(title: 'Work Info'),
              const SizedBox(height: 12),
              _Field(
                controller: _designation,
                label: 'Designation',
                icon: Icons.work_outline,
              ),
              _Field(
                controller: _location,
                label: 'Location / Branch',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 16),
              _SectionHeader(title: 'Payroll'),
              const SizedBox(height: 12),
              _Field(
                controller: _salary,
                label: 'Base Salary (₹)',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _Field(
                controller: _upiId,
                label: 'UPI ID',
                icon: Icons.payments_outlined,
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeepBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kDeepBlue.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isEdit ? 'Save Changes' : 'Add Employee',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: kTealGray,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Text field ─────────────────────────────────────────────────────────────────
class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscure && _obscured,
        readOnly: widget.readOnly,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: widget.readOnly ? kTealGray : kDeepBlue,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: kTealGray,
          ),
          prefixIcon: Icon(widget.icon, size: 18, color: kBlueGray),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: kBlueGray,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
          filled: true,
          fillColor: widget.readOnly ? kOffWhite : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kDanger),
          ),
        ),
      ),
    );
  }
}
