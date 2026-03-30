import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/colors.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/employee/employee_home.dart';
import 'screens/subadmin/subadmin_home.dart';

void main() => runApp(const GTOPortalApp());

class GTOPortalApp extends StatelessWidget {
  const GTOPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTO Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kDeepBlue),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── PARTICLE ────────────────────────────────────────────────────────────────
class TrailParticle {
  Offset position;
  Offset velocity;
  double life; // 0→1, fades out
  double radius;

  TrailParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    this.life = 1.0,
  });
}

// ─── SPLASH PAINTER ──────────────────────────────────────────────────────────
class SplashPainter extends CustomPainter {
  final double progress; // 0→1, eased
  final double rawProgress; // 0→1, linear
  final List<TrailParticle> particles;
  final List<Offset> stars;
  final List<double> starBrightness;

  SplashPainter({
    required this.progress,
    required this.rawProgress,
    required this.particles,
    required this.stars,
    required this.starBrightness,
  });

  // Cubic bezier: start bottom-left → end top-right
  Offset _bezierPoint(double t, Size size) {
    final p0 = Offset(-0.05 * size.width, 0.88 * size.height);
    final p1 = Offset(0.25 * size.width, 0.65 * size.height);
    final p2 = Offset(0.65 * size.width, 0.25 * size.height);
    final p3 = Offset(1.08 * size.width, 0.08 * size.height);

    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx +
          3 * mt * mt * t * p1.dx +
          3 * mt * t * t * p2.dx +
          t * t * t * p3.dx,
      mt * mt * mt * p0.dy +
          3 * mt * mt * t * p1.dy +
          3 * mt * t * t * p2.dy +
          t * t * t * p3.dy,
    );
  }

  // Tangent for rotation angle
  Offset _bezierTangent(double t, Size size) {
    final p0 = Offset(-0.05 * size.width, 0.88 * size.height);
    final p1 = Offset(0.25 * size.width, 0.65 * size.height);
    final p2 = Offset(0.65 * size.width, 0.25 * size.height);
    final p3 = Offset(1.08 * size.width, 0.08 * size.height);

    final mt = 1 - t;
    return Offset(
      3 *
          (mt * mt * (p1.dx - p0.dx) +
              2 * mt * t * (p2.dx - p1.dx) +
              t * t * (p3.dx - p2.dx)),
      3 *
          (mt * mt * (p1.dy - p0.dy) +
              2 * mt * t * (p2.dy - p1.dy) +
              t * t * (p3.dy - p2.dy)),
    );
  }

  void _drawPlane(Canvas canvas, Offset center, double angle, double size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final bodyPaint = Paint()..color = Colors.white.withOpacity(0.95);
    final wingPaint = Paint()..color = Colors.white.withOpacity(0.85);
    final dimPaint = Paint()..color = Colors.white.withOpacity(0.60);
    final windowPaint = Paint()
      ..color = const Color(0xFF87C4FF).withOpacity(0.75);

    // Fuselage
    final fuselage = Path()
      ..moveTo(size, 0)
      ..cubicTo(
        size * 0.6,
        -size * 0.12,
        -size * 0.2,
        -size * 0.12,
        -size * 0.8,
        0,
      )
      ..cubicTo(-size * 0.2, size * 0.12, size * 0.6, size * 0.12, size, 0)
      ..close();
    canvas.drawPath(fuselage, bodyPaint);

    // Left wing (up)
    final leftWing = Path()
      ..moveTo(size * 0.05, 0)
      ..lineTo(-size * 0.25, -size * 0.70)
      ..lineTo(-size * 0.55, -size * 0.68)
      ..lineTo(-size * 0.35, 0)
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    // Right wing (down)
    final rightWing = Path()
      ..moveTo(size * 0.05, 0)
      ..lineTo(-size * 0.25, size * 0.70)
      ..lineTo(-size * 0.55, size * 0.68)
      ..lineTo(-size * 0.35, 0)
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Tail fin top
    final tailTop = Path()
      ..moveTo(-size * 0.65, 0)
      ..lineTo(-size * 0.90, -size * 0.35)
      ..lineTo(-size * 0.80, 0)
      ..close();
    canvas.drawPath(tailTop, bodyPaint);

    // Tail fin bottom
    final tailBot = Path()
      ..moveTo(-size * 0.65, 0)
      ..lineTo(-size * 0.90, size * 0.28)
      ..lineTo(-size * 0.80, 0)
      ..close();
    canvas.drawPath(tailBot, dimPaint);

    // Window strip
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.15, -size * 0.05, size * 0.35, size * 0.10),
      const Radius.circular(4),
    );
    canvas.drawRRect(windowRect, windowPaint);

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── Stars ────────────────────────────────────────────────────────────────
    final starPaint = Paint();
    for (int i = 0; i < stars.length; i++) {
      starPaint.color = Colors.white.withOpacity(starBrightness[i] * 0.5);
      canvas.drawCircle(
        Offset(stars[i].dx * size.width, stars[i].dy * size.height),
        starBrightness[i] * 1.2 + 0.3,
        starPaint,
      );
    }

    if (rawProgress >= 0.97) return; // plane has exited

    final planePos = _bezierPoint(progress, size);
    final tangent = _bezierTangent(progress, size);
    final angle = atan2(tangent.dy, tangent.dx);

    // ── Trail particles ───────────────────────────────────────────────────────
    for (final p in particles) {
      final particlePaint = Paint()
        ..color = const Color(0xFF78BEFF).withOpacity(p.life * 0.45);
      canvas.drawCircle(p.position, p.radius * p.life, particlePaint);
    }

    // ── Glow ─────────────────────────────────────────────────────────────────
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF64B4FF).withOpacity(0.20), Colors.transparent],
      ).createShader(Rect.fromCircle(center: planePos, radius: 55));
    canvas.drawCircle(planePos, 55, glow);

    // ── Plane ─────────────────────────────────────────────────────────────────
    _drawPlane(canvas, planePos, angle, 18);
  }

  @override
  bool shouldRepaint(SplashPainter old) => true;
}

// ─── SPLASH SCREEN ───────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _eased;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  final List<TrailParticle> _particles = [];
  final List<Offset> _stars = [];
  final List<double> _starBrightness = [];
  final Random _rng = Random();

  // Star twinkle animation
  late List<double> _starPhase;

  @override
  void initState() {
    super.initState();

    // Generate stars
    for (int i = 0; i < 65; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
      _starBrightness.add(_rng.nextDouble());
    }
    _starPhase = List.generate(65, (_) => _rng.nextDouble() * pi * 2);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _eased = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.80, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _controller.addListener(_onTick);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 4500), _checkAuth);
  }

  void _onTick() {
    final t = _controller.value;
    if (t >= 0.97) {
      setState(() {});
      return;
    }

    // Bezier position for particle emission
    final size = context.size ?? const Size(400, 800);
    final eT = _eased.value;

    final p0 = Offset(-0.05 * size.width, 0.88 * size.height);
    final p1 = Offset(0.25 * size.width, 0.65 * size.height);
    final p2 = Offset(0.65 * size.width, 0.25 * size.height);
    final p3 = Offset(1.08 * size.width, 0.08 * size.height);

    final mt = 1 - eT;
    final planePos = Offset(
      mt * mt * mt * p0.dx +
          3 * mt * mt * eT * p1.dx +
          3 * mt * eT * eT * p2.dx +
          eT * eT * eT * p3.dx,
      mt * mt * mt * p0.dy +
          3 * mt * mt * eT * p1.dy +
          3 * mt * eT * eT * p2.dy +
          eT * eT * eT * p3.dy,
    );

    // Tangent for backwards-spray direction
    final tang = Offset(
      3 *
          (mt * mt * (p1.dx - p0.dx) +
              2 * mt * eT * (p2.dx - p1.dx) +
              eT * eT * (p3.dx - p2.dx)),
      3 *
          (mt * mt * (p1.dy - p0.dy) +
              2 * mt * eT * (p2.dy - p1.dy) +
              eT * eT * (p3.dy - p2.dy)),
    );
    final norm = tang.distance > 0 ? tang / tang.distance : Offset.zero;

    // Emit 3 particles per frame
    for (int i = 0; i < 3; i++) {
      _particles.add(
        TrailParticle(
          position:
              planePos +
              Offset(
                (_rng.nextDouble() - 0.5) * 5,
                (_rng.nextDouble() - 0.5) * 5,
              ),
          velocity: Offset(
            -norm.dx * (_rng.nextDouble() * 1.8 + 0.5),
            -norm.dy * (_rng.nextDouble() * 1.8 + 0.5),
          ),
          radius: _rng.nextDouble() * 3 + 1,
        ),
      );
    }

    // Age & remove dead particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].position += _particles[i].velocity;
      _particles[i].life -= 0.018;
      if (_particles[i].life <= 0) _particles.removeAt(i);
    }

    // Twinkle stars
    for (int i = 0; i < _stars.length; i++) {
      _starPhase[i] += 0.025;
      _starBrightness[i] = (sin(_starPhase[i]) + 1) / 2;
    }

    setState(() {});
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;
      if (user != null) {
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
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF081A24), Color(0xFF0D2E44), Color(0xFF1D4360)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Plane + Stars layer ──────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: SplashPainter(
                  progress: _eased.value,
                  rawProgress: _controller.value,
                  particles: _particles,
                  stars: _stars,
                  starBrightness: _starBrightness,
                ),
              ),
            ),

            // ── Logo ────────────────────────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/gto.png', width: 160),
                      const SizedBox(height: 16),
                      Text(
                        'GTO CONNECT',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
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
