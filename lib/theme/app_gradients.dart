import 'package:flutter/material.dart';
import 'palettes.dart';

/// Brand decoration tokens exposed through the theme so screens never
/// hardcode gradients or semantic colors. Access with:
///
///   final decor = Theme.of(context).extension<AppDecor>()!;
///   decoration: BoxDecoration(gradient: decor.primaryGradient)
class AppDecor extends ThemeExtension<AppDecor> {
  /// Brand gradient (headers, splash, hero CTAs). Brightness-aware.
  final Gradient primaryGradient;

  /// Text/icon color that is legible on [primaryGradient] in BOTH modes.
  final Color onGradient;

  final Color success;
  final Color warning;
  final Color info;

  const AppDecor({
    required this.primaryGradient,
    required this.onGradient,
    required this.success,
    required this.warning,
    required this.info,
  });

  factory AppDecor.fromPalette(AppPalette p, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return AppDecor(
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [p.gradientStartDark, p.gradientEndDark]
            : [p.gradientStart, p.gradientEnd],
      ),
      onGradient: Colors.white,
      success: dark ? p.successDark : p.success,
      warning: dark ? p.warningDark : p.warning,
      info: dark ? p.infoDark : p.info,
    );
  }

  @override
  AppDecor copyWith({
    Gradient? primaryGradient,
    Color? onGradient,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppDecor(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      onGradient: onGradient ?? this.onGradient,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppDecor lerp(ThemeExtension<AppDecor>? other, double t) {
    if (other is! AppDecor) return this;
    return AppDecor(
      primaryGradient:
          Gradient.lerp(primaryGradient, other.primaryGradient, t) ??
              primaryGradient,
      onGradient: Color.lerp(onGradient, other.onGradient, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
