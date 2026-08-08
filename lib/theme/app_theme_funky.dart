import 'package:flutter/material.dart';
import 'theme_builder.dart';

/// Bold, star-inspired theme — magenta, cyan, gold (creative talent app vibe).
const _palette = AppPalette(
  primary: Color(0xFFD946EF),
  primaryDark: Color(0xFFA21CAF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF06B6D4),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFFFACC15),
  background: Color(0xFFFDF4FF),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1E1B4B),
  textSecondary: Color(0xFF6B7280),
  textMuted: Color(0xFF9CA3AF),
  error: Color(0xFFEF4444),
  success: Color(0xFF10B981),
  warning: Color(0xFFF59E0B),
  info: Color(0xFF3B82F6),
  divider: Color(0xFFF3E8FF),
  border: Color(0xFFE9D5FF),
  outline: Color(0xFFD8B4FE),
  primaryContainer: Color(0xFFFAE8FF),
  onPrimaryContainer: Color(0xFF86198F),
  secondaryContainer: Color(0xFFCFFAFE),
  onSecondaryContainer: Color(0xFF155E75),
  onTertiary: Color(0xFF713F12),
  radius: 20,
  buttonRadius: 16,
);

/// Static color accessors — must match [_palette] above.
abstract final class AppColors {
  static const primary = Color(0xFFD946EF);
  static const primaryDark = Color(0xFFA21CAF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF06B6D4);
  static const onSecondary = Color(0xFFFFFFFF);
  static const tertiary = Color(0xFFFACC15);

  static const background = Color(0xFFFDF4FF);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1E1B4B);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const divider = Color(0xFFF3E8FF);
  static const border = Color(0xFFE9D5FF);
  static const outline = Color(0xFFD8B4FE);
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
  static const salmon = Color(0xFFFAE8FF);
  static const peach = Color(0xFFCFFAFE);
  static const lavender = Color(0xFFFEF9C3);
  static const mint = Color(0xFFFCE7F3);
}

/// Login / splash gradients for the funky theme.
abstract final class AppGradients {
  static const login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA21CAF),
      Color(0xFFD946EF),
      Color(0xFF06B6D4),
    ],
  );

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD946EF), // also used in android/.../values/colors.xml splash_background
      Color(0xFFFACC15),
    ],
  );
}
