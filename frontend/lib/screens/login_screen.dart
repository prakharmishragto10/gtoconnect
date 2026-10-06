import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'admin/admin_home.dart';
import 'employee/employee_home.dart';
import 'subadmin/subadmin_home.dart';

// ─── COLORS ───────────────────────────────────────────────────────────────────
const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF5F6B76);
const _hint = Color(0xFF8C97A1);
const _fieldBorder = Color(0xFF4A545C);

// ─── SKY BACKGROUND ──────────────────────────────────────────────────────────
// Painted rather than loaded from an image so the login screen works offline
// and adds nothing to the app size.
class _SkyPainter extends CustomPainter {
  // (x, y, radius) as fractions of the canvas width/height/width
  final List<(double, double, double)> _puffs = [];
  final List<(double, double, double)> _wisps = [];

  _SkyPainter() {
    final rng = Random(11); // fixed seed: same sky on every launch
    // Cumulus bank filling the lower half, denser towards the bottom
    for (int i = 0; i < 90; i++) {
      final y = 0.50 + pow(rng.nextDouble(), 0.8) * 0.55;
      _puffs.add((
        rng.nextDouble() * 1.2 - 0.1,
        y,
        0.035 + rng.nextDouble() * 0.06 + (y - 0.5) * 0.06,
      ));
    }
    _puffs.sort((a, b) => a.$2.compareTo(b.$2));
    // Thin high cloud streaks
    for (int i = 0; i < 7; i++) {
      _wisps.add((
        rng.nextDouble(),
        0.08 + rng.nextDouble() * 0.30,
        0.10 + rng.nextDouble() * 0.16,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    // Size clouds from the longer side so phones don't get tiny puffs
    final unit = max(w, h * 0.9);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5E9FDD),
            Color(0xFF8DBCE8),
            Color(0xFFC9DDF0),
            Color(0xFFE9EEF3),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ).createShader(rect),
    );

    // High streaks
    final wisp = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.02);
    for (final (x, y, r) in _wisps) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x * w, y * h),
          width: r * unit * 2.6,
          height: r * unit * 0.16,
        ),
        wisp,
      );
    }

    // Faint concentric arcs rising from below the screen
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.30);
    final arcCenter = Offset(w / 2, h * 1.15);
    for (final k in [0.62, 0.78, 0.94]) {
      canvas.drawCircle(arcCenter, max(w, h) * k, arc);
    }

    // Cumulus: a blue-grey underside first, then the lit white top
    final shade = Paint()
      ..color = const Color(0xFF9FB6CC).withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.022);
    final lit = Paint()..color = Colors.white.withValues(alpha: 0.86);
    final warm = Paint()..color = const Color(0xFFFBF3E8).withValues(alpha: 0.5);

    for (final (x, y, r) in _puffs) {
      final c = Offset(x * w, y * h);
      final radius = r * unit;
      final blur = MaskFilter.blur(BlurStyle.normal, radius * 0.32);
      canvas.drawCircle(c + Offset(0, radius * 0.45), radius, shade);
      canvas.drawCircle(c, radius, lit..maskFilter = blur);
      canvas.drawCircle(
        c + Offset(radius * 0.2, radius * 0.25),
        radius * 0.7,
        warm..maskFilter = blur,
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _sky = _SkyPainter();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email and password');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.login(email, pass);
      if (!mounted) return;
      TextInput.finishAutofillContext(); // lets iOS offer "Save Password"
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Clamp Dynamic Type so large accessibility fonts don't break the card
    final mq = MediaQuery.of(context);
    final scaler = mq.textScaler.clamp(maxScaleFactor: 1.3);

    return MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(child: CustomPaint(painter: _sky)),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildGlassCard(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Frosted card ──────────────────────────────────────────────────────────
  Widget _buildGlassCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A5C).withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.40),
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white, width: 6),
            ),
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 44),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3EA),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/gto.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please enter your details to sign in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _GlassField(
                    label: 'E-Mail Address',
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    hint: 'Enter your email...',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passFocus.requestFocus(),
                  ),
                  const SizedBox(height: 22),
                  _GlassField(
                    label: 'Password',
                    controller: _passCtrl,
                    focusNode: _passFocus,
                    hint: 'Enter your password',
                    obscure: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: _fieldBorder,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _buildError(),
                  ],
                  const SizedBox(height: 26),
                  _buildSignInButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF09595)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline,
                size: 16,
                color: Color(0xFFA32D2D),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFA32D2D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign in button ────────────────────────────────────────────────────────
  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _ink.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Sign in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ─── FIELD ────────────────────────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _GlassField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: !obscure,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _ink,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: _hint),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.25),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            border: _border(_fieldBorder, 1.2),
            enabledBorder: _border(_fieldBorder, 1.2),
            focusedBorder: _border(_ink, 1.8),
          ),
        ),
      ],
    );
  }
}
