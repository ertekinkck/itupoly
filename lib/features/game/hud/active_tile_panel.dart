import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

class ActiveTilePanel extends ConsumerWidget {
  const ActiveTilePanel({required this.state, super.key});

  final GameState state;

  static const Set<TurnPhase> _managePhases = {
    TurnPhase.awaitRoll,
    TurnPhase.endTurn,
    TurnPhase.inDisiplin,
    TurnPhase.mustLiquidate,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPlayerId = state.currentPlayer.id;
    final ownedIndices = state.propertiesOf(myPlayerId);
    final controller = ref.read(gameControllerProvider.notifier);
    final manageEnabled = _managePhases.contains(state.phase) && !state.currentPlayer.isBot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- MY PORTFOLIO (QUICK ACTIONS) ---
        const Text(
          'MÜLK PORTFÖYÜM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textFaint,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        ownedIndices.isEmpty
            ? GlassCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_work_outlined, size: 28, color: AppColors.textFaint.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpace.xs),
                        const Text(
                          'Henüz mülk sahibi değilsin.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < ownedIndices.length; i++) ...[
                      if (i > 0) const Divider(color: AppColors.glassBorder, height: 1),
                      _PortfolioTileItem(
                        tile: boardTr[ownedIndices[i]],
                        ts: state.tileStateAt(ownedIndices[i]),
                        tileIndex: ownedIndices[i],
                        state: state,
                        controller: controller,
                        enabled: manageEnabled,
                      ),
                    ],
                  ],
                ),
              ),
      ],
    );
  }
}

class _PortfolioTileItem extends StatelessWidget {
  const _PortfolioTileItem({
    required this.tile,
    required this.ts,
    required this.tileIndex,
    required this.state,
    required this.controller,
    required this.enabled,
  });

  final Tile tile;
  final TileState ts;
  final int tileIndex;
  final GameState state;
  final GameController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Color col = AppColors.accent;
    String extra = '';
    
    if (tile is PropertyTile) {
      col = groupColor((tile as PropertyTile).group);
      if (ts.houses == 5) {
        extra = '🏛️ Amfi';
      } else if (ts.houses > 0) {
        extra = '🏡 × ${ts.houses}';
      }
    } else if (tile is RingTile) {
      col = const Color(0xFF8390A0);
      extra = '🚌 Ring';
    } else if (tile is UtilityTile) {
      col = const Color(0xFFC9A23A);
      extra = '⚡ Tesis';
    }

    final isProp = tile is PropertyTile;
    final isMortgaged = ts.mortgaged;
    final pid = state.currentPlayer.id;
    final liquidating = state.phase == TurnPhase.mustLiquidate;
    
    final canBuild = isProp && enabled && !liquidating && canBuildHouse(state, tileIndex, pid);
    final canSell = isProp && enabled && canSellHouse(state, tileIndex, pid);
    final canMortgageProp = enabled && canMortgage(state, tileIndex, pid);
    final canUnmortgageProp = enabled && !liquidating && canUnmortgage(state, tileIndex, pid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 24,
            decoration: BoxDecoration(
              color: col,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tile.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMortgaged ? AppColors.textFaint : AppColors.textPrimary,
                    decoration: isMortgaged ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (extra.isNotEmpty)
                  Text(
                    extra,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          
          if (isProp && !isMortgaged) ...[
            if (canBuild)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent, size: 20),
                tooltip: 'Derslik İnşa Et',
                onPressed: () => controller.dispatch(BuildHouse(tileIndex)),
              ),
            if (canSell)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.negative, size: 20),
                tooltip: 'Derslik Sat',
                onPressed: () => controller.dispatch(SellHouse(tileIndex)),
              ),
          ],
          
          if (canMortgageProp)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('İPOTEK (+${mortgageValue(tileIndex)}$kCredit)', style: const TextStyle(color: AppColors.negative, fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () => controller.dispatch(MortgageTile(tileIndex)),
            ),

          if (canUnmortgageProp)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('GERİ AL (${unmortgageCost(tileIndex)}$kCredit)', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () => controller.dispatch(UnmortgageTile(tileIndex)),
            ),
        ],
      ),
    );
  }
}
