import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double padding;
  final double borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 48.0,
    this.padding = 18.0,
    this.borderRadius = 24.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: DesignSystem.primary,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: DesignSystem.primary.withValues(alpha: 0.4),
                  blurRadius: size / 2,
                  offset: Offset(0, size / 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: size,
      ),
    );
  }
}
