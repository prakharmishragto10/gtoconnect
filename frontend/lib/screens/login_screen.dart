import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive.dart';
import '../services/auth_service.dart';
import 'admin/admin_home.dart';
import 'employee/employee_home.dart';
import 'subadmin/subadmin_home.dart';

// ─── COLORS ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0C2640);
const _blue = Color(0xFF185FA5);
const _muted = Color(0xFF6B7E8F);
const _iconGray = Color(0xFF8FA8BB);
const _bg = Color(0xFFF0F4F8);
const _card = Color(0xFFFFFFFF);
const _border = Color(0xFFD6E0E8);

const _headerGradient = LinearGradient(
  colors: [
    Color.fromARGB(255, 8, 27, 66),
    Color.fromARGB(255, 190, 205, 228),
    Color.fromARGB(255, 8, 27, 66),
  ],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── STAR PAINTER (repaints via animation, no setState) ──────────────────────
class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final List<double> phases;
  final Animation<double> animation;

  _StarPainter({
    required this.stars,
    required this.phases,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final t = animation.value * pi * 2;
    for (int i = 0; i < stars.length; i++) {
      final b = (sin(phases[i] + t) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: (b * 0.75).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(stars[i].dx * size.width, stars[i].dy * size.height),
        b * 1.5 + 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
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
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final List<Offset> _stars = [];
  final List<double> _starPhase = [];
  final Random _rng = Random();
  late final AnimationController _starController;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 60; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
      _starPhase.add(_rng.nextDouble() * pi * 2);
    }
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _starController.dispose();
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
    final isDesktop = Responsive.isDesktop(context);

    // Clamp Dynamic Type so large accessibility fonts don't break fixed heights
    final mq = MediaQuery.of(context);
    final scaler = mq.textScaler.clamp(maxScaleFactor: 1.3);

    return MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light, // header is dark → white status icons
        child: Scaffold(
          backgroundColor: _bg,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ── Mobile layout: whole page scrolls, header shrinks with keyboard ──────
  Widget _buildMobileLayout() {
    final pad = MediaQuery.paddingOf(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          _buildHeader(compact: keyboardOpen),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20 + pad.left,
              24,
              20 + pad.right,
              32 + pad.bottom,
            ),
            child: ContentCap(maxWidth: 480, child: _buildFormContent()),
          ),
        ],
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: RepaintBoundary(
              child: CustomPaint(painter: _stars_painter()),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ContentCap(
              maxWidth: 480,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/gto.png', width: 120, height: 120),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: _buildFormContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  CustomPainter _stars_painter() => _StarPainter(
    stars: _stars,
    phases: _starPhase,
    animation: _starController,
  );

  // ── Shared form content ───────────────────────────────────────────────────
  Widget _buildFormContent() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(),
          const SizedBox(height: 20),
          _buildForm(),
          if (_error != null) ...[const SizedBox(height: 12), _buildError()],
          const SizedBox(height: 20),
          _buildSignInButton(),
        ],
      ),
    );
  }

  // ── Header (mobile only) ──────────────────────────────────────────────────
  Widget _buildHeader({required bool compact}) {
    final topPad = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.sizeOf(context).height;
    final logo = compact ? 88.0 : min(200.0, screenH * 0.22);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _headerGradient),
      padding: EdgeInsets.only(
        top: topPad + (compact ? 8 : 28),
        bottom: compact ? 12 : 32,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _stars_painter()),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: logo,
            height: logo,
            child: Image.asset('assets/gto.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  // ── Heading ───────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Enter your credentials to continue',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _muted),
        ),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      children: [
        _GTOField(
          label: 'EMAIL',
          controller: _emailCtrl,
          focusNode: _emailFocus,
          hint: 'you@gto.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passFocus.requestFocus(),
          autocorrect: false,
        ),
        const SizedBox(height: 14),
        _GTOField(
          label: 'PASSWORD',
          controller: _passCtrl,
          focusNode: _passFocus,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          autocorrect: false,
          suffix: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _obscure = !_obscure),
            child: SizedBox(
              width: 44,
              height: 48,
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _iconGray,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: navigate to forgot-password flow
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: _blue,
            ),
            child: Text(
              'Forgot password?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF09595)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: Color(0xFFA32D2D)),
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
    );
  }

  // ── Sign-in button ────────────────────────────────────────────────────────
  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          disabledBackgroundColor: _navy.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          'Sign In',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── FIELD WIDGET ─────────────────────────────────────────────────────────────
class _GTOField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;
  final Widget? suffix;

  const _GTOField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.autocorrect = false,
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D5A6E),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6E0E8), width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 18, color: const Color(0xFF8FA8BB)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  autofillHints: autofillHints,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  autocorrect: autocorrect,
                  enableSuggestions: !obscure,
                  textCapitalization: TextCapitalization.none,
                  textAlignVertical: TextAlignVertical.center,
                  // 16px prevents iOS Safari auto-zoom on focus
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF0C2640),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: const Color(0xFFA8BFCC),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              suffix ?? const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}