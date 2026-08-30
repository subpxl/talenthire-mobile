import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central design tokens for a cohesive app look.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFDC1C38);
  static const primaryDark = Color(0xFFB0152D);
  static const primaryLight = Color(0xFFFFF1F3);
  static const primaryTint = Color(0xFFFDF2F2);
  static const accentGreen = Color(0xFF2E7D32);
  static const chatGreen = Color(0xFF43A047);
  static const bannerStart = Color(0xFFFFF176);
  static const bannerEnd = Color(0xFFFFD54F);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAFAFA);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF616161);
  static const textHint = Color(0xFF9E9E9E);
  static const border = Color(0xFFE8E8E8);
  static const divider = Color(0xFFF0F0F0);
  static const hintBar = Color(0xFFFBF6F0);
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const screenH = 16.0;
  static const screenV = 8.0;
  static const scrollBottom = 40.0;
}

class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const pill = 24.0;
}

/// Shared tokens for every labeled form field (text, readonly, dropdown).
class AppFormStyle {
  AppFormStyle._();

  static const labelSize = 13.5;
  static const valueSize = 13.0;
  static const fieldRadius = 10.0;
  static const labelGap = 6.0;
  static const fieldGap = 14.0;
  static const fieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const fill = Color(0xFFFAFAFA);
  static const border = Color(0xFFEEEEEE);
  static const valueColor = Color(0xFF424242);
  static const hintColor = Color(0xFFBDBDBD);

  static const labelStyle = TextStyle(
    fontSize: labelSize,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const valueStyle = TextStyle(
    fontSize: valueSize,
    color: valueColor,
  );

  static const hintStyle = TextStyle(
    fontSize: valueSize,
    color: hintColor,
  );

  static BoxDecoration get fieldBox => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(color: border),
      );

  static OutlineInputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: border),
      );

  static InputDecoration inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: fieldPadding,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      disabledBorder: _inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class AppDurations {
  AppDurations._();

  static const tabSwitch = Duration(milliseconds: 320);
  static const pageRoute = Duration(milliseconds: 340);
  static const innerTab = Duration(milliseconds: 260);
}

ThemeData buildAppTheme() {
  const primary = AppColors.primary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.screenH,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.xs,
      ),
      iconColor: AppColors.textPrimary,
      textColor: AppColors.textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
  );
}

extension AppText on BuildContext {
  TextStyle get sectionTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  TextStyle get caption => const TextStyle(
        fontSize: 13,
        color: AppColors.textHint,
      );
}
