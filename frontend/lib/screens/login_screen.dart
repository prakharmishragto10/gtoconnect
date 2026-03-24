import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'admin/admin_home.dart';
import 'employee/employee_home.dart';
import 'subadmin/subadmin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.login(_emailCtrl.text, _passCtrl.text);

      setState(() => _loading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (user.isAdmin) return AdminHome(user: user);
            if (user.isSubAdmin) return SubAdminHome(user: user);
            return EmployeeHome(user: user);
          },
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _fillDemo(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = 'password123';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ changed
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Image.asset('assets/gto.png', height: 150),
                const SizedBox(height: 6),
                Text(
                  'WORKFORCE MANAGEMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    color: kBlueGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: kDeepBlue, // ✅ card color
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // ✅ changed
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your credentials to continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: kBlueGray, // ✅ changed
                        ),
                      ),
                      const SizedBox(height: 24),

                      _Label('Email'),
                      const SizedBox(height: 6),
                      _Input(
                        controller: _emailCtrl,
                        hint: 'you@gto.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      _Label('Password'),
                      const SizedBox(height: 6),
                      _Input(
                        controller: _passCtrl,
                        hint: '••••••••',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: kBlueGray,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kDangerBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kDanger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 14,
                                color: kDanger,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _error!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: kDanger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kDeepBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kDeepBlue, // ✅ changed
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kOffWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEMO ACCOUNTS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: kTealGray,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _demoTile('barun@gto.com', 'Barun Gulati', 'Admin'),
                            _demoTile(
                              'suhanigulati@gto.com',
                              'Suhani Gulati',
                              'Finance',
                            ),
                            _demoTile(
                              'prakhar@gto.com',
                              'Prakhar Mishra',
                              'Backend Dev',
                            ),
                            _demoTile(
                              'nida@gto.com',
                              'Chandanmuri Nida',
                              'Web Dev',
                            ),
                            _demoTile(
                              'aditya@gto.com',
                              'Aditya Sharma',
                              'Mktg Mgr',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoTile(String email, String name, String role) {
    return GestureDetector(
      onTap: () => _fillDemo(email),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kInfoBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kDeepBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: kTealGray,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kInfoBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kDeepBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.white70, // ✅ changed
      letterSpacing: 0.4,
    ),
  );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Input({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kDeepBlue),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: kTealGray,
      ), // ✅ changed
      suffixIcon: suffix,
      filled: true,
      fillColor: kOffWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kTealGray, width: 1.5),
      ),
    ),
  );
}
