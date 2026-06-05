import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
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
              _Header(tile: tile),
              const SizedBox(height: AppSpace.md),
              _OwnerLine(state: s, ts: ts),
              const SizedBox(height: AppSpace.md),
              if (tile is PropertyTile)
                _RentLadder(tile: tile, state: s, ts: ts),
              if (tile is RingTile) _RingInfo(state: s, ts: ts),
              if (tile is UtilityTile) _UtilityInfo(),
              if (tile is TaxTile) _TaxInfo(tile: tile),
              if (tile is CardTile) _CardInfo(tile: tile),
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

class _Header extends StatelessWidget {
  const _Header({required this.tile});
  final Tile tile;

  @override
  Widget build(BuildContext context) {
    var color = AppColors.accent;
    var icon = Icons.place_rounded;
    var sub = '';
    switch (tile) {
      case PropertyTile(:final group, :final price):
        color = groupColor(group);
        icon = groupIcon(group);
        sub = '${group.label} • $price$kCredit';
      case RingTile(:final price):
        icon = Icons.directions_bus_rounded;
        sub = 'Ring durağı • $price$kCredit';
      case UtilityTile(:final price):
        icon = Icons.bolt_rounded;
        sub = 'Şirket • $price$kCredit';
      case TaxTile(:final amount):
        icon = Icons.receipt_long_rounded;
        color = AppColors.negative;
        sub = 'Vergi • $amount$kCredit';
      case CardTile(:final deck):
        icon = deck == DeckType.sans
            ? Icons.help_rounded
            : Icons.inventory_2_rounded;
        sub = deck == DeckType.sans ? 'Şans kartı' : 'Kampüs Kartı';
      case CornerTile():
        icon = Icons.flag_rounded;
        sub = 'Köşe';
    }
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(sub, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerLine extends StatelessWidget {
  const _OwnerLine({required this.state, required this.ts});
  final GameState state;
  final TileState ts;

  @override
  Widget build(BuildContext context) {
    final String label;
    var color = AppColors.textSecondary;
    if (!ts.isOwned) {
      label = 'Sahipsiz (bankada)';
    } else {
      final owner = state.playerById(ts.ownerId!);
      label = owner.id == state.currentPlayer.id ? 'Senin' : owner.name;
      color = AppColors.accent;
    }
    return Row(
      children: [
        const Icon(Icons.person_rounded, size: 16, color: AppColors.textFaint),
        const SizedBox(width: AppSpace.sm),
        const Text('Sahip: ', style: TextStyle(color: AppColors.textFaint)),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        if (ts.mortgaged) ...[
          const SizedBox(width: AppSpace.md),
          const Icon(Icons.lock_rounded, size: 16, color: AppColors.negative),
          const Text(' İpotekli', style: TextStyle(color: AppColors.negative)),
        ],
      ],
    );
  }
}

class _RentLadder extends StatelessWidget {
  const _RentLadder({
    required this.tile,
    required this.state,
    required this.ts,
  });
  final PropertyTile tile;
  final GameState state;
  final TileState ts;

  @override
  Widget build(BuildContext context) {
    final monopoly =
        ts.isOwned && ownsFullGroup(state, tile.group, ts.ownerId!);
    final rows = <(String, int, bool)>[
      ('Temel kira', tile.rents[0], ts.houses == 0 && !monopoly),
      ('Tekel (×2)', tile.rents[0] * 2, ts.houses == 0 && monopoly),
      ('1 derslik', tile.rents[1], ts.houses == 1),
      ('2 derslik', tile.rents[2], ts.houses == 2),
      ('3 derslik', tile.rents[3], ts.houses == 3),
      ('4 derslik', tile.rents[4], ts.houses == 4),
      ('Amfi', tile.rents[5], ts.houses == 5),
    ];
    return GlassCard(
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (r.$3)
                    const Icon(
                      Icons.arrow_right_rounded,
                      color: AppColors.accent,
                      size: 18,
                    )
                  else
                    const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      r.$1,
                      style: TextStyle(
                        color: r.$3
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: r.$3 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    '${r.$2}$kCredit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: r.$3 ? AppColors.accent : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: AppColors.glassBorder, height: AppSpace.lg),
          Text(
            'Derslik maliyeti: ${tile.houseCost}$kCredit',
            style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RingInfo extends StatelessWidget {
  const _RingInfo({required this.state, required this.ts});
  final GameState state;
  final TileState ts;

  @override
  Widget build(BuildContext context) {
    const rents = [25, 50, 100, 200];
    final owned = ts.isOwned ? ringsOwnedUnmortgaged(state, ts.ownerId!) : 0;
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text('${i + 1} ring sahibi')),
                  Text(
                    '${rents[i]}$kCredit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: owned == i + 1
                          ? AppColors.accent
                          : AppColors.textSecondary,
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

class _UtilityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('1 şirket'),
            trailing: Text('zar × 4'),
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('2 şirket'),
            trailing: Text('zar × 10'),
          ),
        ],
      ),
    );
  }
}

class _TaxInfo extends StatelessWidget {
  const _TaxInfo({required this.tile});
  final TaxTile tile;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Text('Buraya gelen ${tile.amount}$kCredit vergi öder.'),
  );
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.tile});
  final CardTile tile;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Text(
      tile.deck == DeckType.sans
          ? 'Şans destesinden bir kart çekilir.'
          : 'Kampüs Kartı destesinden bir kart çekilir.',
    ),
  );
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
