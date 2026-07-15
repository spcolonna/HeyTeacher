import 'package:flutter/material.dart';

/// Available palettes. Switch the app's entire look by changing
/// [kActivePalette] in `palette_config.dart`.
enum AppPaletteId { classic, scholar, horizon }

/// A complete brand palette: seeds Material 3 color schemes (light + dark)
/// and defines the brand gradient and semantic colors with dark variants.
class AppPalette {
  final Color seed;
  final Color primary;
  final Color secondary;

  final Color gradientStart;
  final Color gradientEnd;
  final Color gradientStartDark;
  final Color gradientEndDark;

  final Color success;
  final Color successDark;
  final Color warning;
  final Color warningDark;
  final Color info;
  final Color infoDark;

  const AppPalette({
    required this.seed,
    required this.primary,
    required this.secondary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.gradientStartDark,
    required this.gradientEndDark,
    this.success = const Color(0xFF16A34A),
    this.successDark = const Color(0xFF4ADE80),
    this.warning = const Color(0xFFD97706),
    this.warningDark = const Color(0xFFFBBF24),
    this.info = const Color(0xFF0284C7),
    this.infoDark = const Color(0xFF38BDF8),
  });
}

/// 1. Derived from the current HeyTeacher logo: blue → violet.
///    Canonicalizes the blue/purple gradient the app already used.
const AppPalette _classic = AppPalette(
  seed: Color(0xFF3D6BF5),
  primary: Color(0xFF3D6BF5),
  secondary: Color(0xFF8B5CF6),
  gradientStart: Color(0xFF4E7CF6),
  gradientEnd: Color(0xFF9B59F5),
  gradientStartDark: Color(0xFF3A5BC0),
  gradientEndDark: Color(0xFF7245B8),
);

/// 2. Modern proposal: deep indigo + warm amber. Trustworthy and
///    professional with warmth — a classic "education meets jobs" pairing.
const AppPalette _scholar = AppPalette(
  seed: Color(0xFF4F46E5),
  primary: Color(0xFF4F46E5),
  secondary: Color(0xFFF59E0B),
  gradientStart: Color(0xFF4F46E5),
  gradientEnd: Color(0xFF7C3AED),
  gradientStartDark: Color(0xFF4038B8),
  gradientEndDark: Color(0xFF6530BE),
);

/// 3. Modern proposal: deep teal + coral. Fresh and differentiated from
///    every other blue jobs app.
const AppPalette _horizon = AppPalette(
  seed: Color(0xFF0F766E),
  primary: Color(0xFF0F766E),
  secondary: Color(0xFFF97362),
  gradientStart: Color(0xFF0F766E),
  gradientEnd: Color(0xFF0891B2),
  gradientStartDark: Color(0xFF0C5D57),
  gradientEndDark: Color(0xFF06718D),
);

AppPalette paletteFor(AppPaletteId id) => switch (id) {
      AppPaletteId.classic => _classic,
      AppPaletteId.scholar => _scholar,
      AppPaletteId.horizon => _horizon,
    };
