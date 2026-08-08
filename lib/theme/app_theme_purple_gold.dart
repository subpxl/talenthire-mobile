import 'package:flutter/material.dart';
import 'theme_builder.dart';

/// Royal amethyst + gold — deep purple gradients with golden yellow accents.
/// Funky, premium talent-app vibe (inspired by luxury + creative UI palettes).
const _palette = AppPalette(
  primary: Color(0xFF7C3AED),
  primaryDark: Color(0xFF4C1D95),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFEC4899),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFFFBBF24),
  background: Color(0xFFFAF5FF),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF2E1065),
  textSecondary: Color(0xFF6B7280),
  textMuted: Color(0xFFA78BFA),
  error: Color(0xFFEF4444),
  success: Color(0xFF10B981),
  warning: Color(0xFFF59E0B),
  info: Color(0xFF8B5CF6),
  divider: Color(0xFFEDE9FE),
  border: Color(0xFFDDD6FE),
  outline: Color(0xFFC4B5FD),
  primaryContainer: Color(0xFFEDE9FE),
  onPrimaryContainer: Color(0xFF5B21B6),
  secondaryContainer: Color(0xFFFCE7F3),
  onSecondaryContainer: Color(0xFF9D174D),
  onTertiary: Color(0xFF78350F),
  radius: 20,
  buttonRadius: 16,
);

/// Static color accessors — must match [_palette] above.
abstract final class AppColors {
  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF4C1D95);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFEC4899);
  static const onSecondary = Color(0xFFFFFFFF);
  static const tertiary = Color(0xFFFBBF24);

  static const background = Color(0xFFFAF5FF);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF2E1065);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFFA78BFA);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF8B5CF6);

  static const divider = Color(0xFFEDE9FE);
  static const border = Color(0xFFDDD6FE);
  static const outline = Color(0xFFC4B5FD);
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
  static const salmon = Color(0xFFFCE7F3);
  static const peach = Color(0xFFFEF3C7);
  static const lavender = Color(0xFFEDE9FE);
  static const mint = Color(0xFFFAE8FF);
}

/// Login / splash gradients for the purple-gold theme.
abstract final class AppGradients {
  static const login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C1D95),
      Color(0xFF7C3AED),
      Color(0xFFFBBF24),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B21B6), // also used in android/.../values/colors.xml splash_background
      Color(0xFFFBBF24),
    ],
  );
}
