import 'package:flutter/material.dart';

class DesignSystem {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Violet / Purple
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color error = Colors.redAccent;

  // Background Colors
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgLight = Color(0xFFF1F5F9);

  // Card Backgrounds
  static const Color cardDark = Color(0xFF1E2235);
  static const Color cardLight = Colors.white;

  // Field Backgrounds
  static const Color fieldDark = Color(0xFF2E334D);
  static const Color fieldLight = Color(0xFFE2E8F0);

  // Spacing Metrics
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // Radii Constants
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Reusable Shadows
  static List<BoxShadow>? getShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ];
    }
  }

  // Reusable Card Border
  static Border getBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      width: 1.0,
    );
  }

  // Reusable Theme Helpers
  static Color getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? cardDark.withValues(alpha: 0.8) : cardLight;
  }

  static Color getFieldColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? fieldDark.withValues(alpha: 0.4) : fieldLight;
  }

  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  static Color getSubtitleColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xFF475569);
  }

  static Color getMutedColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white38 : Colors.black38;
  }

  // Screen Breakpoints
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 600) return ScreenType.mobile;
    if (width <= 1050) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  // Responsive Spacing Tokens
  static double getPagePadding(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 12.0;
      case ScreenType.tablet: return 20.0;
      case ScreenType.desktop: return 24.0;
    }
  }

  static double getCardPadding(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 12.0;
      case ScreenType.tablet: return 16.0;
      case ScreenType.desktop: return 20.0;
    }
  }

  static double getGridGap(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 12.0;
      case ScreenType.tablet: return 16.0;
      case ScreenType.desktop: return 24.0;
    }
  }

  // Responsive Typography Tokens
  static double getTitleLargeSize(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 20.0;
      case ScreenType.tablet: return 24.0;
      case ScreenType.desktop: return 28.0;
    }
  }

  static double getTitleMediumSize(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 16.0;
      case ScreenType.tablet: return 18.0;
      case ScreenType.desktop: return 20.0;
    }
  }

  static double getBodyLargeSize(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 14.0;
      case ScreenType.tablet: return 15.0;
      case ScreenType.desktop: return 16.0;
    }
  }

  static double getBodyMediumSize(BuildContext context) {
    final type = getScreenType(context);
    switch (type) {
      case ScreenType.mobile: return 12.0;
      case ScreenType.tablet: return 13.0;
      case ScreenType.desktop: return 14.0;
    }
  }
}

enum ScreenType { mobile, tablet, desktop }
