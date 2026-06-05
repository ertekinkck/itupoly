import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Oyun Sonu — kazanan, net değer sıralaması, tekrar oyna.
class EndScreen extends ConsumerWidget {
  const EndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) {
      return _Empty(onHome: () => context.go('/'));
    }
    final s = session.state;
    final ranked = [...s.players]
      ..sort((a, b) => netWorth(s, b.id).compareTo(netWorth(s, a.id)));
    final winner = s.winnerId != null
        ? s.playerById(s.winnerId!)
        : ranked.first;
    final maxWorth = netWorth(s, ranked.first.id).clamp(1, 1 << 30);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpace.lg),
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.accent,
                      size: 64,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      '${winner.name} mezun oldu!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    const Text(
                      'En yüksek net değerle kazandı',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    GlassCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < ranked.length; i++)
                            _RankRow(
                              rank: i + 1,
                              player: ranked[i],
                              worth: netWorth(s, ranked[i].id),
                              maxWorth: maxWorth,
                              isWinner: ranked[i].id == winner.id,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    PrimaryButton(
                      label: 'Tekrar Oyna',
                      icon: Icons.replay_rounded,
                      expand: true,
                      onPressed: () => context.go('/kurulum'),
                    ),
                    const SizedBox(height: AppSpace.md),
                    SecondaryButton(
                      label: 'Ana Menü',
                      icon: Icons.home_rounded,
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.player,
    required this.worth,
    required this.maxWorth,
    required this.isWinner,
  });

  final int rank;
  final Player player;
  final int worth;
  final int maxWorth;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final frac = (worth / maxWorth).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isWinner ? AppColors.accent : AppColors.textFaint,
              ),
            ),
          ),
          PawnIcon(player.pawn, size: 32, selected: isWinner),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (player.bankrupt)
                      const Text(
                        'iflas',
                        style: TextStyle(
                          color: AppColors.negative,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        '$worth$kCredit',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 6,
                    backgroundColor: AppColors.glassStrong,
                    valueColor: AlwaysStoppedAnimation(
                      isWinner ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: PrimaryButton(label: 'Ana Menü', onPressed: onHome),
        ),
      ),
    );
  }
}
