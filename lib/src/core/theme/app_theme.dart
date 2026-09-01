import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema global.
abstract final class AppTheme {
  /// Radio de esquinas de botones y campos.
  static const double radius = 10;

  /// Alto estándar de los controles táctiles.
  static const double controlHeight = 52;

  /// Margen horizontal de las pantallas.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);

  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary30,
      onPrimary: AppColors.buttonTextLight,
      secondary: AppColors.accentSecondaryGreen,
      onSecondary: AppColors.white,
      tertiary: AppColors.accentSecondaryBlue,
      surface: AppColors.surface,
      onSurface: AppColors.primaryText,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.primaryText,
        displayColor: AppColors.primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: AppColors.buttonTextLight,
          disabledBackgroundColor: AppColors.primaryButton,
          disabledForegroundColor: AppColors.buttonTextLight,
          minimumSize: const Size.fromHeight(controlHeight),
          elevation: 0,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          backgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(controlHeight),
          side: const BorderSide(color: AppColors.buttonBorder, width: 1.5),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          textStyle: AppTextStyles.link,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        hintStyle: AppTextStyles.hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _fieldBorder(AppColors.outline),
        enabledBorder: _fieldBorder(AppColors.outline),
        focusedBorder: _fieldBorder(AppColors.primary60, width: 1.5),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error, width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary60,
        contentTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
