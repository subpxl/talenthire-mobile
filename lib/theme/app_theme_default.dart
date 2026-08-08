import 'package:flutter/material.dart';
import 'theme_builder.dart';

/// Clean, professional theme (indigo + teal).
const _palette = AppPalette(
  primary: Color(0xFF6366F1),
  primaryDark: Color(0xFF4338CA),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF14B8A6),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFFF59E0B),
  background: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF0F172A),
  textSecondary: Color(0xFF64748B),
  textMuted: Color(0xFF94A3B8),
  error: Color(0xFFEF4444),
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  info: Color(0xFF3B82F6),
  divider: Color(0xFFE2E8F0),
  border: Color(0xFFE2E8F0),
  outline: Color(0xFFCBD5E1),
  primaryContainer: Color(0xFFE0E7FF),
  onPrimaryContainer: Color(0xFF312E81),
  secondaryContainer: Color(0xFFCCFBF1),
  onSecondaryContainer: Color(0xFF134E4A),
  onTertiary: Color(0xFF78350F),
);

/// Static color accessors — screens import these directly.
abstract final class AppColors {
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4338CA);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF14B8A6);
  static const onSecondary = Color(0xFFFFFFFF);
  static const tertiary = Color(0xFFF59E0B);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const divider = Color(0xFFE2E8F0);
  static const border = Color(0xFFE2E8F0);
  static const outline = Color(0xFFCBD5E1);
}

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

/// Pastel card fills for dashboard grid cards.
abstract final class AppCardColors {
  static const salmon = Color(0xFFE0E7FF);
  static const peach = Color(0xFFCCFBF1);
  static const lavender = Color(0xFFFEF3C7);
  static const mint = Color(0xFFDBEAFE);
}

/// Login / splash gradients for the default theme.
abstract final class AppGradients {
  static const login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4338CA),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
    ],
  );

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
    ],
  );
}
