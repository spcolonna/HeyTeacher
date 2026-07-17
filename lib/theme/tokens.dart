import 'package:flutter/animation.dart';

/// Builds subtle fills from a semantic color (success/warning/primary…).
///
/// Never tint from a fixed light shade like `Colors.green.shade50`: that stays
/// light in dark mode and the theme's light text becomes unreadable on it.
/// Deriving the fill from a brightness-aware color keeps contrast in both
/// themes — pair [softFill] with the base color itself as the text color.
extension SoftTint on Color {
  /// Background fill for callouts, badges and status banners.
  Color get softFill => withValues(alpha: 0.12);

  /// Border companion for [softFill].
  Color get softBorder => withValues(alpha: 0.40);
}

/// Spacing scale — use instead of magic EdgeInsets/SizedBox numbers.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radius scale.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Motion tokens — nothing in the app should animate longer than [slow].
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve curve = Curves.easeOutCubic;
}
