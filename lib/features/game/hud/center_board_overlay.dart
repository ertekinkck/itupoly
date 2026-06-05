import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly/widgets/credit_text.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly/widgets/monopoly_property_card.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// 3B Tahtanın tam ortasında süzülen aktif oyun kartı ve karar butonları.
class CenterBoardOverlay extends ConsumerWidget {
  const CenterBoardOverlay({
    required this.state,
    required this.visible,
    super.key,
  });

  final GameState state;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPos = state.currentPlayer.position;
    final tile = boardTr[currentPos];
    final ts = state.tileStateAt(currentPos);
    final controller = ref.read(gameControllerProvider.notifier);

    final show = visible && state.phase != TurnPhase.gameOver;

    return AnimatedScale(
      scale: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !show,
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonopolyPropertyCard(
                  tile: tile,
                  ts: ts,
                  state: state,
                  compact: MediaQuery.of(context).size.height < 580,
                ),
                const SizedBox(height: AppSpace.sm),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  child: _TurnActionsBox(state: state, controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnActionsBox extends StatelessWidget {
  const _TurnActionsBox({
    required this.state,
    required this.controller,
  });

  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final p = state.currentPlayer;
    final isBot = p.isBot;

    if (isBot) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: AppSpace.sm),
            Text(
              'Bot oynuyor...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final p = state.currentPlayer;
    switch (state.phase) {
      case TurnPhase.awaitRoll:
        return _PulsingButton(
          label: 'Zar At',
          icon: Icons.casino_rounded,
          onPressed: () => controller.dispatch(const RollDice()),
        );
      case TurnPhase.inDisiplin:
        return Column(
          children: [
            _PulsingButton(
              label: 'Zar At',
              icon: Icons.casino_rounded,
              onPressed: () => controller.dispatch(const RollDice()),
            ),
            if (p.cash >= disiplinFine) ...[
              const SizedBox(height: AppSpace.xs),
              SecondaryButton(
                label: 'Ceza Öde (50$kCredit)',
                onPressed: () => controller.dispatch(const PayDisiplinFine()),
              ),
            ],
            if (p.hasAfKarti) ...[
              const SizedBox(height: AppSpace.xs),
              SecondaryButton(
                label: 'Af Kartı Kullan',
                tone: AppColors.positive,
                onPressed: () => controller.dispatch(const UseAfKarti()),
              ),
            ],
          ],
        );
      case TurnPhase.awaitBuyDecision:
        final tile = boardTr[p.position];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Satın almak istiyor musunuz?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                if (p.cash >= tile.purchasePrice)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Al (${tile.purchasePrice}₭)',
                      onPressed: () => controller.dispatch(const BuyProperty()),
                    ),
                  )
                else
                  const Expanded(
                    child: PrimaryButton(
                      label: 'Bakiye Az',
                      onPressed: null,
                    ),
                  ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: SecondaryButton(
                    label: 'Pas',
                    onPressed: () => controller.dispatch(const DeclineBuy()),
                  ),
                ),
              ],
            ),
          ],
        );
      case TurnPhase.mustLiquidate:
        final debt = state.pendingDebt?.amount ?? 0;
        return Column(
          children: [
            Text(
              'Borç: $debt$kCredit! Mülkleri sat/ipotek et.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.negative, fontWeight: FontWeight.bold),
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
        return PrimaryButton(
          label: 'Turu Bitir',
          expand: true,
          icon: Icons.check_circle_outline_rounded,
          onPressed: () => controller.dispatch(const EndTurn()),
        );
      case TurnPhase.gameOver:
        return const SizedBox.shrink();
    }
  }
}

/// "Zar At" butonunu nefes alır gibi pulse eden wrapper.
class _PulsingButton extends StatefulWidget {
  const _PulsingButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: PrimaryButton(
        label: widget.label,
        expand: true,
        icon: widget.icon,
        onPressed: widget.onPressed,
      ),
    );
  }
}
