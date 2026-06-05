import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Piyon türünün ikon + renk eşlemesi (özgün ikon seti).
abstract final class PawnVisuals {
  static const _data = <PawnType, ({IconData icon, Color color, String label})>{
    PawnType.ari: (
      icon: Icons.hive_rounded,
      color: Color(0xFFE8B53A),
      label: 'Arı',
    ),
    PawnType.pergel: (
      icon: Icons.architecture_rounded,
      color: Color(0xFF4FC3F7),
      label: 'Pergel',
    ),
    PawnType.baret: (
      icon: Icons.engineering_rounded,
      color: Color(0xFFFFB74D),
      label: 'Baret',
    ),
    PawnType.kahve: (
      icon: Icons.coffee_rounded,
      color: Color(0xFFA1887F),
      label: 'Kahve',
    ),
    PawnType.hesapMakinesi: (
      icon: Icons.calculate_rounded,
      color: Color(0xFF2DD4A7),
      label: 'Hesap Makinesi',
    ),
    PawnType.devreKarti: (
      icon: Icons.memory_rounded,
      color: Color(0xFFBA68C8),
      label: 'Devre Kartı',
    ),
  };

  static IconData iconOf(PawnType p) => _data[p]!.icon;
  static Color colorOf(PawnType p) => _data[p]!.color;
  static String labelOf(PawnType p) => _data[p]!.label;
}

/// Bir piyonu yuvarlak rozet içinde gösterir.
class PawnIcon extends StatelessWidget {
  const PawnIcon(
    this.pawn, {
    this.size = 28,
    this.selected = false,
    super.key,
  });

  final PawnType pawn;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = PawnVisuals.colorOf(pawn);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(
          color: selected ? AppColors.accent : color.withValues(alpha: 0.6),
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Icon(
        PawnVisuals.iconOf(pawn),
        size: size * 0.58,
        color: color,
      ),
    );
  }
}
