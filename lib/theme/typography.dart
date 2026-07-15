import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sora for display/headlines/titles (geometric, friendly, modern);
/// Inter for body/labels (highly legible at small sizes).
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);

    TextStyle? sora(TextStyle? style, FontWeight weight) => style == null
        ? null
        : GoogleFonts.sora(textStyle: style.copyWith(fontWeight: weight));

    return inter.copyWith(
      displayLarge: sora(base.displayLarge, FontWeight.w700),
      displayMedium: sora(base.displayMedium, FontWeight.w700),
      displaySmall: sora(base.displaySmall, FontWeight.w700),
      headlineLarge: sora(base.headlineLarge, FontWeight.w700),
      headlineMedium: sora(base.headlineMedium, FontWeight.w600),
      headlineSmall: sora(base.headlineSmall, FontWeight.w600),
      titleLarge: sora(base.titleLarge, FontWeight.w600),
      titleMedium: sora(base.titleMedium, FontWeight.w600),
      titleSmall: sora(base.titleSmall, FontWeight.w600),
    );
  }

  /// Button/label style (Sora, semibold).
  static TextStyle button = GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
