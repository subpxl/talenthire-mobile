import 'package:flutter/material.dart';
import 'theme_builder.dart';

/// Soft pastel theme — navy, salmon, peach, lavender, mint (reference UI palette).
const _palette = AppPalette(
  primary: Color(0xFF2B3352),
  primaryDark: Color(0xFF1E2640),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFF0786A),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFFF0B070),
  background: Color(0xFFFFF3EE),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1E2640),
  textSecondary: Color(0xFF6E7894),
  textMuted: Color(0xFFA8B0C4),
  error: Color(0xFFEF4444),
  success: Color(0xFF6BCFB0),
  warning: Color(0xFFF0B070),
  info: Color(0xFF9BA3E8),
  divider: Color(0xFFF5E8E2),
  border: Color(0xFFF0E4DC),
  outline: Color(0xFFE8DCD4),
  primaryContainer: Color(0xFFEEF0FA),
  onPrimaryContainer: Color(0xFF2B3352),
  secondaryContainer: Color(0xFFFDEAE6),
  onSecondaryContainer: Color(0xFF9E3D32),
  onTertiary: Color(0xFF5C3D1E),
  radius: 24,
  buttonRadius: 20,
  cardElevation: 3,
  cardShowBorder: false,
);

/// Static color accessors — must match [_palette] above.
abstract final class AppColors {
  static const primary = Color(0xFF2B3352);
  static const primaryDark = Color(0xFF1E2640);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFF0786A);
  static const onSecondary = Color(0xFFFFFFFF);
  static const tertiary = Color(0xFFF0B070);

  static const background = Color(0xFFFFF3EE);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1E2640);
  static const textSecondary = Color(0xFF6E7894);
  static const textMuted = Color(0xFFA8B0C4);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF6BCFB0);
  static const warning = Color(0xFFF0B070);
  static const info = Color(0xFF9BA3E8);

  static const divider = Color(0xFFF5E8E2);
  static const border = Color(0xFFF0E4DC);
  static const outline = Color(0xFFE8DCD4);
}

/// Pastel card fills from the reference palette (dashboard grid, highlights).
abstract final class AppCardColors {
  static const salmon = Color(0xFFF8B4A6);
  static const peach = Color(0xFFF5C49A);
  static const lavender = Color(0xFFC8CCF5);
  static const mint = Color(0xFFB5E8D5);
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

/// Login / splash gradients for the soft pastel theme.
abstract final class AppGradients {
  static const login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E2640),
      Color(0xFF2B3352),
      Color(0xFFF0786A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B3352), // also used in android/.../values/colors.xml splash_background
      Color(0xFFF0786A),
    ],
  );
}
