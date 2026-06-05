import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly/widgets/monopoly_property_card.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Kareye dokununca açılan tapu kartı görünümü.
Future<void> showPropertySheet(BuildContext context, int tileIndex) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PropertySheet(tileIndex: tileIndex),
  );
}

class PropertySheet extends ConsumerWidget {
  const PropertySheet({required this.tileIndex, super.key});

  final int tileIndex;

  static const Set<TurnPhase> _managePhases = {
    TurnPhase.awaitRoll,
    TurnPhase.endTurn,
    TurnPhase.inDisiplin,
    TurnPhase.mustLiquidate,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const SizedBox.shrink();
    final s = session.state;
    final controller = ref.read(gameControllerProvider.notifier);
    final tile = boardTr[tileIndex];
    final ts = s.tileStateAt(tileIndex);
    final current = s.currentPlayer;
    final isMine = ts.ownerId == current.id && !current.isBot;

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ColoredBox(
          color: AppColors.bgElevated,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              MonopolyPropertyCard(tile: tile, ts: ts, state: s),
              const SizedBox(height: AppSpace.lg),
              if (isMine)
                _ManageActions(
                  state: s,
                  controller: controller,
                  tileIndex: tileIndex,
                  enabled: _managePhases.contains(s.phase),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



class _ManageActions extends StatelessWidget {
  const _ManageActions({
    required this.state,
    required this.controller,
    required this.tileIndex,
    required this.enabled,
  });

  final GameState state;
  final GameController controller;
  final int tileIndex;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final pid = state.currentPlayer.id;
    final liquidating = state.phase == TurnPhase.mustLiquidate;
    final canBuild =
        enabled && !liquidating && canBuildHouse(state, tileIndex, pid);
    final canSell = enabled && canSellHouse(state, tileIndex, pid);
    final canMort = enabled && canMortgage(state, tileIndex, pid);
    final canUnmort =
        enabled && !liquidating && canUnmortgage(state, tileIndex, pid);
    final tile = boardTr[tileIndex];
    final houseCost = tile is PropertyTile ? tile.houseCost : 0;

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        if (tile is PropertyTile)
          PrimaryButton(
            label: 'Derslik ($houseCost$kCredit)',
            icon: Icons.add_home_rounded,
            onPressed: canBuild
                ? () => controller.dispatch(BuildHouse(tileIndex))
                : null,
          ),
        if (tile is PropertyTile)
          SecondaryButton(
            label: 'Derslik Sat',
            icon: Icons.remove_rounded,
            onPressed: canSell
                ? () => controller.dispatch(SellHouse(tileIndex))
                : null,
          ),
        SecondaryButton(
          label: 'İpotek (+${mortgageValue(tileIndex)}$kCredit)',
          icon: Icons.lock_outline_rounded,
          tone: AppColors.negative,
          onPressed: canMort
              ? () => controller.dispatch(MortgageTile(tileIndex))
              : null,
        ),
        SecondaryButton(
          label: 'İpotek Kaldır (${unmortgageCost(tileIndex)}$kCredit)',
          icon: Icons.lock_open_rounded,
          tone: AppColors.positive,
          onPressed: canUnmort
              ? () => controller.dispatch(UnmortgageTile(tileIndex))
              : null,
        ),
      ],
    );
  }
}
