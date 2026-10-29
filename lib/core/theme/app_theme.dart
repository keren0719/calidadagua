import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto reutilizables del diseño.
class AppText {
  AppText._();

  static const kicker = TextStyle(
    color: AppColors.green,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );

  static const screenTitle = TextStyle(
    color: AppColors.title,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.26,
    height: 1.15,
  );

  static const screenSubtitle = TextStyle(color: AppColors.muted, fontSize: 13, height: 1.55);

  static const cardTitle = TextStyle(
    color: AppColors.text,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  static const cardBody = TextStyle(color: Color(0xFF6F837C), fontSize: 11, height: 1.55);

  static const label = TextStyle(
    color: AppColors.textSoft,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Manrope';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.forest,
        secondary: AppColors.green,
        surface: AppColors.background,
        error: AppColors.errorStrong,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderInput),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.title),
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.mutedLight, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        errorStyle: const TextStyle(color: AppColors.errorText, fontSize: 11),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.errorBorder),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.errorStrong, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.greenStrong,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.green : const Color(0xFFCFDDD7),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.green,
        inactiveTrackColor: Color(0xFFDCEBE5),
        thumbColor: AppColors.forest,
        overlayColor: Color(0x22249B70),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.green),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.forest,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.title,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.muted,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
    );
  }
}
