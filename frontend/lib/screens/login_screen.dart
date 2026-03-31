import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';
import 'admin/admin_home.dart';
import 'employee/employee_home.dart';
import 'subadmin/subadmin_home.dart';

// ─── COLORS ──────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0C2640);
const _blue = Color(0xFF185FA5);
const _slate = Color(0xFF3D5A6E);
const _muted = Color(0xFF6B7E8F);
const _iconGray = Color(0xFF8FA8BB);
const _bg = Color(0xFFF0F4F8);
const _card = Color(0xFFFFFFFF);
const _border = Color(0xFFD6E0E8);
const _rowBg = Color(0xFFEBF3FA);

// ─── STAR PAINTER ────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final List<double> brightness;

  _StarPainter({required this.stars, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < stars.length; i++) {
      final opacity = (brightness[i] * 0.75).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(stars[i].dx * size.width, stars[i].dy * size.height),
        brightness[i] * 1.5 + 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => true;
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // ── Star field state ────────────────────────────────────────────────────────
  final List<Offset> _stars = [];
  final List<double> _starBrightness = [];
  final List<double> _starPhase = [];
  final Random _rng = Random();
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();

    // Generate 60 random stars
    for (int i = 0; i < 60; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
      _starBrightness.add(_rng.nextDouble());
      _starPhase.add(_rng.nextDouble() * pi * 2);
    }

    // Repeating controller drives the twinkle
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _starController.addListener(() {
      for (int i = 0; i < _stars.length; i++) {
        _starPhase[i] += 0.020;
        _starBrightness[i] = (sin(_starPhase[i]) + 1) / 2;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.login(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      setState(() => _loading = false);
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

  void _fillDemo(String email) => setState(() {
    _emailCtrl.text = email;
    _passCtrl.text = 'password123';
    _error = null;
  });

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeading(),
                  const SizedBox(height: 20),
                  _buildForm(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildError(),
                  ],
                  const SizedBox(height: 20),
                  _buildSignInButton(),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildDemoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header with gradient + stars ────────────────────────────────────────────
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 8, 27, 66),
            Color.fromARGB(255, 190, 205, 228),
            Color.fromARGB(255, 8, 27, 66),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(top: topPad + 28, bottom: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Twinkling star layer ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _StarPainter(stars: _stars, brightness: _starBrightness),
            ),
          ),

          // ── Logo card ────────────────────────────────────────────────────
          Image.asset('assets/gto.png', width: 200, height: 200),
        ],
      ),
    );
  }

  // ── Heading ─────────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Enter your credentials to continue',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted),
        ),
      ],
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      children: [
        _GTOField(
          label: 'EMAIL',
          controller: _emailCtrl,
          hint: 'you@gto.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _GTOField(
          label: 'PASSWORD',
          controller: _passCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: _iconGray,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _blue,
            ),
          ),
        ),
      ],
    );
  }

  // ── Error banner ─────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF09595)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFA32D2D)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFFA32D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign-in button ───────────────────────────────────────────────────────────
  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'DEMO ACCOUNTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _iconGray,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _border, thickness: 1)),
      ],
    );
  }

  // ── Demo card ────────────────────────────────────────────────────────────────
  Widget _buildDemoCard() {
    final demos = [
      (
        'B',
        'Barun Gulati',
        'barun@gto.com',
        'Admin',
        const Color(0xFFD6EAF8),
        const Color(0xFF0C447C),
      ),
      (
        'S',
        'Suhani Gulati',
        'suhanigulati@gto.com',
        'Finance',
        const Color(0xFFD1F5EA),
        const Color(0xFF085041),
      ),
      (
        'P',
        'Prakhar Mishra',
        'prakhar@gto.com',
        'Dev',
        const Color(0xFFFEF3D6),
        const Color(0xFF633806),
      ),
      (
        'N',
        'Nida',
        'nida@gto.com',
        'Web Dev',
        const Color(0xFFD1F5EA),
        const Color(0xFF085041),
      ),
      (
        'A',
        'Aditya Sharma',
        'aditya@gto.com',
        'Mktg',
        const Color(0xFFFEF3D6),
        const Color(0xFF633806),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _rowBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'QUICK LOGIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _slate,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ...demos.map(
            (d) => _DemoRow(
              initial: d.$1,
              name: d.$2,
              email: d.$3,
              role: d.$4,
              avatarBg: d.$5,
              avatarFg: d.$6,
              onTap: () => _fillDemo(d.$3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FIELD WIDGET ─────────────────────────────────────────────────────────────
class _GTOField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _GTOField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D5A6E),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6E0E8), width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 16, color: const Color(0xFF8FA8BB)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF0C2640),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFFA8BFCC),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffix != null) ...[suffix!, const SizedBox(width: 8)],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── DEMO ROW ─────────────────────────────────────────────────────────────────
class _DemoRow extends StatelessWidget {
  final String initial, name, email, role;
  final Color avatarBg, avatarFg;
  final VoidCallback onTap;

  const _DemoRow({
    required this.initial,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarBg,
    required this.avatarFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEF4F8))),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avatarFg,
                  ),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0C2640),
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF8FA8BB),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: avatarFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
