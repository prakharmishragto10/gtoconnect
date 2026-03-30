import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650;
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
