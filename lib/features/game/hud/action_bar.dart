import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly/app/theme/theme.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/credit_text.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Faza duyarlı aksiyon barı — sıradaki oyuncunun ana etkileşimi.
class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const SizedBox.shrink();
    final controller = ref.read(gameControllerProvider.notifier);
    final s = session.state;
    final player = s.currentPlayer;

    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              PawnIcon(player.pawn, size: 40, selected: true),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    RollingCredit(player.cash, color: AppColors.accent),
                  ],
                ),
              ),
              _DiceChip(d1: s.lastDie1, d2: s.lastDie2),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (player.isBot)
            const _BotThinking()
          else
            _Actions(state: s, controller: controller),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final p = state.currentPlayer;
    switch (state.phase) {
      case TurnPhase.awaitRoll:
        return _row([
          PrimaryButton(
            label: 'Zar At',
            icon: Icons.casino_rounded,
            onPressed: () => controller.dispatch(const RollDice()),
          ),
        ]);
      case TurnPhase.inDisiplin:
        return _row([
          PrimaryButton(
            label: 'Zar At',
            icon: Icons.casino_rounded,
            onPressed: () => controller.dispatch(const RollDice()),
          ),
          if (p.cash >= disiplinFine)
            SecondaryButton(
              label: 'Ceza Öde (50$kCredit)',
              onPressed: () => controller.dispatch(const PayDisiplinFine()),
            ),
          if (p.hasAfKarti)
            SecondaryButton(
              label: 'Af Kartı',
              tone: AppColors.positive,
              onPressed: () => controller.dispatch(const UseAfKarti()),
            ),
        ]);
      case TurnPhase.awaitBuyDecision:
        final tile = boardTr[p.position];
        return _row([
          if (p.cash >= tile.purchasePrice)
            PrimaryButton(
              label: 'Satın Al (${tile.purchasePrice}$kCredit)',
              icon: Icons.shopping_cart_rounded,
              onPressed: () => controller.dispatch(const BuyProperty()),
            ),
          SecondaryButton(
            label: 'Pas',
            onPressed: () => controller.dispatch(const DeclineBuy()),
          ),
        ]);
      case TurnPhase.mustLiquidate:
        final debt = state.pendingDebt?.amount ?? 0;
        return Column(
          children: [
            Text(
              'Borç: $debt$kCredit — kareye dokunup ipotek et / derslik sat.',
              textAlign: TextAlign.center,
              style: creditStyle(context, size: 14, color: AppColors.negative),
            ),
            const SizedBox(height: AppSpace.sm),
            SecondaryButton(
              label: 'İflas Et',
              tone: AppColors.negative,
              onPressed: () => controller.dispatch(const DeclareBankruptcy()),
            ),
          ],
        );
      case TurnPhase.endTurn:
        return _row([
          PrimaryButton(
            label: 'Turu Bitir',
            icon: Icons.check_rounded,
            onPressed: () => controller.dispatch(const EndTurn()),
          ),
        ]);
      case TurnPhase.gameOver:
        return const SizedBox.shrink();
    }
  }

  Widget _row(List<Widget> children) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    alignment: WrapAlignment.center,
    children: children,
  );
}

class _BotThinking extends StatelessWidget {
  const _BotThinking();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        SizedBox(width: AppSpace.md),
        Text(
          'Bot oynuyor…',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DiceChip extends StatelessWidget {
  const _DiceChip({required this.d1, required this.d2});
  final int d1;
  final int d2;

  @override
  Widget build(BuildContext context) {
    if (d1 == 0) return const SizedBox.shrink();
    return Row(
      children: [
        _Die(d1),
        const SizedBox(width: 4),
        _Die(d2),
      ],
    );
  }
}

class _Die extends StatelessWidget {
  const _Die(this.value);
  final int value;

  static const List<IconData> _icons = [
    Icons.casino_rounded,
    Icons.looks_one_rounded,
    Icons.looks_two_rounded,
    Icons.looks_3_rounded,
    Icons.looks_4_rounded,
    Icons.looks_5_rounded,
    Icons.looks_6_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.glassStrong,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(_icons[value], color: AppColors.accent, size: 22),
    );
  }
}
