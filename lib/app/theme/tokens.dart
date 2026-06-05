import 'package:flutter/material.dart';

/// İTÜpoly tasarım jetonları — sade, karanlık, premium.
abstract final class AppColors {
  /// Gece laciverti arka plan.
  static const bg = Color(0xFF0B1220);
  static const bgElevated = Color(0xFF111A2E);

  /// Cam yüzey dolgusu ve kenarı.
  static const glassFill = Color(0x0DFFFFFF); // %5 beyaz
  static const glassBorder = Color(0x14FFFFFF); // %8 beyaz
  static const glassStrong = Color(0x1AFFFFFF);

  /// Arı altını — vurgu.
  static const accent = Color(0xFFE8B53A);
  static const accentDim = Color(0xFF8A6B23);

  /// Para renkleri.
  static const positive = Color(0xFF2DD4A7); // zümrüt
  static const negative = Color(0xFFF0556B);

  static const textPrimary = Color(0xFFF3F5FA);
  static const textSecondary = Color(0xFFA7B0C0);
  static const textFaint = Color(0xFF6B7689);
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
const String kCredit = '₭';
