import 'package:flutter/material.dart';

import 'theme_builder.dart';

/// Bombay Casting Company
/// Premium cinema / casting theme.
/// Charcoal + champagne gold + ivory.

const _palette = AppPalette(
  // Brand
  primary: Color(0xFFD6B98C),      // Soft Luxury Gold
  primaryDark: Color(0xFF8A6F4D),  // Warm Highlight / Deep Gold
  onPrimary: Color(0xFF1A1A1A),    // Very Deep Charcoal

  // Supporting brand color
  secondary: Color(0xFF2B2B2B),    // Deep Charcoal
  onSecondary: Color(0xFFFFF8ED),  // Ivory

  // Accent
  tertiary: Color(0xFFF7E7CE),     // Champagne

  // Application surfaces
  background: Color(0xFFFFF8ED),   // Ivory
  surface: Color(0xFFFFFFFF),      // Pure White
  card: Color(0xFFFFFFFF),         // Pure White

  // Typography
  textPrimary: Color(0xFF2B2B2B),  // Deep Charcoal Text
  textSecondary: Color(0xFF6E6A63),// Warm Grey Text
  textMuted: Color(0xFFAFAAA0),    // Muted Warm Grey

  // Semantic
  error: Color(0xFFD64545),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFD89B27),
  info: Color(0xFF4A78A8),

  // Borders
  divider: Color(0xFFE8DFD1),
  border: Color(0xFFDCD1BF),
  outline: Color(0xFFC7BCA8),

  // Containers
  primaryContainer: Color(0xFFF7E7CE), // Champagne
  onPrimaryContainer: Color(0xFF4A3C29),

  secondaryContainer: Color(0xFFE5E0D8),
  onSecondaryContainer: Color(0xFF2B2B2B),

  onTertiary: Color(0xFF4A3C29),
);

/// Static color accessors — screens import these directly.
abstract final class AppColors {
  static const primary = Color(0xFFD6B98C);
  static const primaryDark = Color(0xFF8A6F4D);
  static const onPrimary = Color(0xFF1A1A1A);

  static const secondary = Color(0xFF2B2B2B);
  static const onSecondary = Color(0xFFFFF8ED);

  static const tertiary = Color(0xFFF7E7CE);

  static const background = Color(0xFFFFF8ED);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF2B2B2B);
  static const textSecondary = Color(0xFF6E6A63);
  static const textMuted = Color(0xFFAFAAA0);

  static const error = Color(0xFFD64545);
  static const success = Color(0xFF2E8B57);
  static const warning = Color(0xFFD89B27);
  static const info = Color(0xFF4A78A8);

  static const divider = Color(0xFFE8DFD1);
  static const border = Color(0xFFDCD1BF);
  static const outline = Color(0xFFC7BCA8);

  static const primaryContainer = Color(0xFFF7E7CE);
  static const onPrimaryContainer = Color(0xFF4A3C29);

  static const secondaryContainer = Color(0xFFE5E0D8);
  static const onSecondaryContainer = Color(0xFF2B2B2B);
}

/// Application theme.
abstract final class AppTheme {
  static ThemeData get light => buildLightTheme(_palette);
}

/// Convenience accessors for common theme values.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  double get cardRadius {
    final shape = Theme.of(this).cardTheme.shape;

    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
    }

    return 16;
  }
}

/// Soft brand-tinted dashboard cards.
///
/// These should be used as subtle backgrounds,
/// not as the main application colors.
abstract final class AppCardColors {
  static const lavender = Color(0xFFF7E7CE); // Champagne
  static const mint = Color(0xFFFFF8ED);     // Ivory
  static const salmon = Color(0xFFF3E5C5);   // Lighter Gold
  static const peach = Color(0xFFE5E0D8);    // Warm Grey Surface
}

/// Brand gradients.
///
/// Keep gradients primarily for hero areas,
/// login screens and promotional sections.
abstract final class AppGradients {
  static const login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF2B2B2B),
      Color(0xFF8A6F4D),
    ],
  );

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFFD6B98C),
    ],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A6F4D),
      Color(0xFFD6B98C),
      Color(0xFFF7E7CE),
    ],
  );
}