import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/credit_text.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Oyuncu şeridi — tüm oyuncular, sıradaki vurgulu.
class PlayerStrip extends StatelessWidget {
  const PlayerStrip({
    required this.state,
    this.vertical = false,
    super.key,
  });

  final GameState state;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final p in state.players)
        _PlayerChip(
          player: p,
          isCurrent: p.id == state.currentPlayer.id && !state.isGameOver,
          properties: state.propertiesOf(p.id).length,
        ),
    ];

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: c,
            ),
        ],
      );
    }
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.player,
    required this.isCurrent,
    required this.properties,
  });

  final Player player;
  final bool isCurrent;
  final int properties;

  @override
  Widget build(BuildContext context) {
    final dim = player.bankrupt;
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        border: isCurrent ? AppColors.accent : AppColors.glassBorder,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PawnIcon(player.pawn, size: 32, selected: isCurrent),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (player.inJail)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.gavel_rounded,
                          size: 13,
                          color: AppColors.negative,
                        ),
                      ),
                  ],
                ),
                if (dim)
                  const Text(
                    'iflas',
                    style: TextStyle(color: AppColors.negative, fontSize: 11),
                  )
                else
                  Row(
                    children: [
                      RollingCredit(player.cash, size: 13),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.home_work_rounded,
                        size: 11,
                        color: AppColors.textFaint,
                      ),
                      Text(
                        ' $properties',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
