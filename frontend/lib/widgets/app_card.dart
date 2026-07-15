import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadowOverride;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.shadowOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(DesignSystem.getCardPadding(context)),
      decoration: BoxDecoration(
        color: DesignSystem.getCardColor(context),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
        border: DesignSystem.getBorder(context),
        boxShadow: shadowOverride ?? DesignSystem.getShadow(context),
      ),
      child: child,
    );
  }
}
