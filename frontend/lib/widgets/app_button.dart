import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? side;
  final EdgeInsetsGeometry padding;
  final double? width;

  const AppButton._({
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    this.side,
    required this.padding,
    this.width,
  });

  factory AppButton.primary({
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? width,
  }) {
    return AppButton._(
      onPressed: onPressed,
      backgroundColor: DesignSystem.primary,
      foregroundColor: Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: width,
      child: child,
    );
  }

  factory AppButton.secondary({
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? width,
  }) {
    return AppButton._(
      onPressed: onPressed,
      backgroundColor: DesignSystem.secondary,
      foregroundColor: Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: width,
      child: child,
    );
  }

  factory AppButton.outlined({
    required VoidCallback? onPressed,
    required Widget child,
    Color color = DesignSystem.primary,
    EdgeInsetsGeometry? padding,
    double? width,
  }) {
    return AppButton._(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: color,
      side: BorderSide(color: color),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: width,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: side,
        elevation: backgroundColor == Colors.transparent ? 0 : 4,
        shadowColor: backgroundColor == Colors.transparent
            ? null
            : backgroundColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
        ),
        padding: padding,
      ),
      onPressed: onPressed,
      child: child,
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
