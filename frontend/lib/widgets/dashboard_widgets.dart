import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';

// Shared building blocks for the employee, admin and sub-admin dashboards.

const kHeroGradient = LinearGradient(
  colors: [Color(0xFF071A33), Color(0xFF0B2545), Color(0xFF1B4F8A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Up to two initials. Safe for empty names and repeated spaces.
String initialsOf(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w.substring(0, 1).toUpperCase())
      .join();
  return parts.isEmpty ? '?' : parts;
}

BoxDecoration dashCardDecoration({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xFFE6ECF1)),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF0C2640).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

// ── Gradient hero card with soft decorative circles ──────────────────────────
class DashHero extends StatelessWidget {
  final Widget child;
  const DashHero({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2640).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: _Bubble(size: 160, alpha: 0.07),
          ),
          Positioned(
            right: 60,
            bottom: -60,
            child: _Bubble(size: 120, alpha: 0.05),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size, alpha;
  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

/// Translucent pill used on top of the hero gradient.
class HeroChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const HeroChip(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Big number + caption shown on the right of the hero on wide screens.
class HeroStat extends StatelessWidget {
  final String label, value;
  const HeroStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}

// ── Section header with accent bar ───────────────────────────────────────────
class DashSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const DashSectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 16,
        decoration: BoxDecoration(
          gradient: kHeroGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kDeepBlue,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

// ── Stat grid ────────────────────────────────────────────────────────────────
/// Lays out [DashStatCard]s. Column count follows the space actually
/// available and rows have a fixed height, so cards never overflow on narrow
/// content areas.
class DashStatGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;

  /// True when the cards show a third "sub" line and need taller rows.
  final bool withSub;

  const DashStatGrid({
    super.key,
    required this.children,
    this.maxColumns = 5,
    this.withSub = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowHeight = MediaQuery.textScalerOf(
      context,
    ).scale(withSub ? 136 : 122);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 150).floor().clamp(
          2,
          maxColumns,
        );
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: rowHeight,
          ),
          children: children,
        );
      },
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────
class DashStatCard extends StatelessWidget {
  final String label, value;
  final String? sub;
  final IconData icon;
  final Color color, bg;

  const DashStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: dashCardDecoration(),
      child: Stack(
        children: [
          // Soft tinted corner so each card carries its own colour
          Positioned(
            right: -22,
            top: -22,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: kDeepBlue,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTealGray,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: kBlueGray,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status pill ──────────────────────────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill(this.status, {super.key});

  static (Color, Color) colorsFor(String status) => switch (status) {
    'pending' || 'late' => (kWarn, kWarnBg),
    'approved' || 'present' => (kForest, kSuccessBg),
    'paid' => (kDeepBlue, kInfoBg),
    'rejected' || 'absent' => (kDanger, kDangerBg),
    _ => (kTealGray, kOffWhite),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = colorsFor(status);
    final label = status.isEmpty
        ? '—'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar with initials ─────────────────────────────────────────────────────
class InitialAvatar extends StatelessWidget {
  final String? name;
  final double size;
  const InitialAvatar(this.name, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEAF1F6), Color(0xFFD6E6F2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Text(
      initialsOf(name),
      style: GoogleFonts.plusJakartaSans(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
        color: kDeepBlue,
      ),
    ),
  );
}

/// List row used for claims and attendance entries on the dashboards.
class DashListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget subtitle;
  final String? trailingText;
  final String status;

  const DashListTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.status,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: dashCardDecoration(radius: 14),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
              const SizedBox(height: 2),
              subtitle,
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: kDeepBlue,
                ),
              ),
              const SizedBox(height: 4),
            ],
            StatusPill(status),
          ],
        ),
      ],
    ),
  );
}

class DashEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const DashEmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    decoration: dashCardDecoration(radius: 14),
    child: Column(
      children: [
        Icon(icon, size: 28, color: kBlueGray),
        const SizedBox(height: 8),
        Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
        ),
      ],
    ),
  );
}
