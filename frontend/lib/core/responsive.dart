import 'package:flutter/material.dart';

class Responsive {
  // Below this the sidebar + top bar leave too little room for content, so
  // tablets in portrait get the phone layout.
  static const double desktopBreakpoint = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < desktopBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
}

// Constrain any content to a max width, centered
class ContentCap extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentCap({super.key, required this.child, this.maxWidth = 820});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
