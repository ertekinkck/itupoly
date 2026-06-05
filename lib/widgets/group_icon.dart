import 'package:flutter/material.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Motorun grup için verdiği ikon adını Material ikona çevirir.
/// (Renk körlüğü desteği: her grupta renk + ikon birlikte.)
IconData groupIcon(TileGroup group) {
  return switch (group.iconName) {
    'school' => Icons.school_rounded,
    'menu_book' => Icons.menu_book_rounded,
    'architecture' => Icons.architecture_rounded,
    'apartment' => Icons.apartment_rounded,
    'science' => Icons.science_rounded,
    'flight' => Icons.flight_rounded,
    'local_library' => Icons.local_library_rounded,
    'account_balance' => Icons.account_balance_rounded,
    'directions_bus' => Icons.directions_bus_rounded,
    'bolt' => Icons.bolt_rounded,
    _ => Icons.place_rounded,
  };
}

/// Grup rengi.
Color groupColor(TileGroup group) => Color(group.colorValue);
