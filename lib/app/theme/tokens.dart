import 'package:flutter/material.dart';

/// İTÜpoly tasarım jetonları — sade, karanlık, premium.
abstract final class AppColors {
  /// Premium açık gri arka plan.
  static const bg = Color(0xFFF4F6F9);
  static const bgElevated = Color(0xFFFFFFFF);

  /// Cam yüzey dolgusu ve kenarı (açık tema için koyu gölge).
  static const glassFill = Color(0x0D000000); // %5 siyah
  static const glassBorder = Color(0x1F000000); // %12 siyah
  static const glassStrong = Color(0x29000000); // %16 siyah

  /// Altın sarısı — vurgu.
  static const accent = Color(0xFFD49E00);
  static const accentDim = Color(0xFFB8860B);

  /// Para renkleri.
  static const positive = Color(0xFF28A745);
  static const negative = Color(0xFFDC3545);

  static const textPrimary = Color(0xFF0B1220);
  static const textSecondary = Color(0xFF4A5568);
  static const textFaint = Color(0xFF8A99AD);
}

abstract final class AppRadius {
  static const card = 20.0;
  static const button = 12.0;
  static const chip = 999.0;
  static const tile = 8.0;
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 160);
  static const med = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 500);

  /// Piyon karesi başına hop süresi.
  static const hopPerTile = Duration(milliseconds: 140);
}

abstract final class AppBreakpoints {
  static const phone = 600.0;
  static const tablet = 1024.0;
}

/// Para birimi simgesi (Kredi).
const String kCredit = '₺';
