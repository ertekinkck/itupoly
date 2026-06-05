import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Uygulama teması — Manrope tipografisi, karanlık premium palet.
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      surface: AppColors.bg,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.positive,
      error: AppColors.negative,
    ),
    textTheme: textTheme,
    splashColor: AppColors.accent.withValues(alpha: 0.08),
    highlightColor: AppColors.accent.withValues(alpha: 0.04),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

/// Tabular rakamlı para metni stili.
TextStyle creditStyle(BuildContext context, {double? size, Color? color}) {
  return GoogleFonts.manrope(
    fontSize: size ?? 16,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
