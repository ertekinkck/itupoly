import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/board/board_geometry.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Tek bir tahta karesi: tür rengi/ikonu, sahip, inşaat, ipotek.
class BoardTile extends StatelessWidget {
  const BoardTile({
    required this.tile,
    required this.ts,
    required this.size,
    this.ownerColor,
    this.highlighted = false,
    this.onTap,
    super.key,
  });

  final Tile tile;
  final TileState ts;
  final double size;
  final Color? ownerColor;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(tile);
    final showText = size >= 46;
    final border = highlighted
        ? AppColors.accent
        : (ownerColor ?? AppColors.glassBorder);

    return Semantics(
      button: true,
      label: _semanticLabel(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.all(size * 0.03),
          decoration: BoxDecoration(
            color: visual.fill,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(
              color: border,
              width: highlighted ? 2 : (ownerColor != null ? 1.6 : 0.8),
            ),
            boxShadow: [
              // Kabartılmış (raised) his — masada yükselen kare.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: size * 0.07,
                offset: Offset(0, size * 0.05),
              ),
              if (highlighted)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.55),
                  blurRadius: 10,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Üst grup şeridi (arsa).
              if (visual.stripColor != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: visual.stripColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.tile),
                      ),
                    ),
                  ),
                ),
              // Orta ikon + (alan varsa) fiyat.
              Padding(
                padding: EdgeInsets.only(
                  top: visual.stripColor != null ? size * 0.22 : 0,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        visual.icon,
                        size: size * 0.34,
                        color: visual.iconColor,
                      ),
                      if (showText && tile.purchasePrice > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${tile.purchasePrice}$kCredit',
                            style: TextStyle(
                              fontSize: size * 0.16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // İnşaat göstergesi (üst şeride yerleşir).
              if (tile is PropertyTile && ts.houses > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: size * 0.02),
                    child: _Buildings(houses: ts.houses, size: size),
                  ),
                ),
              // İpotek perdesi.
              if (ts.mortgaged)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: size * 0.3,
                      color: AppColors.negative,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    final price = tile.purchasePrice > 0 ? ', ${tile.purchasePrice} kredi' : '';
    final owned = ts.isOwned ? ', sahipli' : '';
    final mort = ts.mortgaged ? ', ipotekli' : '';
    return '${tile.name}$price$owned$mort. Detay için dokun.';
  }
}

/// Minyatür derslik/amfi ikonları — rozet sayaç değil, premium his.
class _Buildings extends StatelessWidget {
  const _Buildings({required this.houses, required this.size});
  final int houses;
  final double size;

  @override
  Widget build(BuildContext context) {
    const depth = [
      Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 2)),
    ];
    final Widget content;
    if (houses == 5) {
      content = Icon(
        Icons.apartment_rounded,
        size: size * 0.42,
        color: AppColors.accent,
        shadows: depth,
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < houses; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Icon(
                Icons.home_rounded,
                size: size * 0.24,
                color: AppColors.positive,
                shadows: depth,
              ),
            ),
        ],
      );
    }
    // Ters-döndürerek dik ayakta (eğik düzlemde 3B bina gibi).
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()..rotateX(-boardTilt),
      child: content,
    );
  }
}

typedef _TileVisual = ({
  IconData icon,
  Color iconColor,
  Color fill,
  Color? stripColor,
});

_TileVisual _visualFor(Tile tile) {
  switch (tile) {
    case PropertyTile(:final group):
      final c = groupColor(group);
      return (
        icon: groupIcon(group),
        iconColor: c,
        fill: c.withValues(alpha: 0.10),
        stripColor: c,
      );
    case RingTile():
      return (
        icon: Icons.directions_bus_rounded,
        iconColor: const Color(0xFFB0BEC5),
        fill: const Color(0x14B0BEC5),
        stripColor: null,
      );
    case UtilityTile():
      return (
        icon: Icons.bolt_rounded,
        iconColor: const Color(0xFFFFD54F),
        fill: const Color(0x14FFD54F),
        stripColor: null,
      );
    case TaxTile():
      return (
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.negative,
        fill: AppColors.negative.withValues(alpha: 0.10),
        stripColor: null,
      );
    case CardTile(:final deck):
      final isSans = deck == DeckType.sans;
      final c = isSans ? AppColors.accent : AppColors.positive;
      return (
        icon: isSans ? Icons.help_rounded : Icons.inventory_2_rounded,
        iconColor: c,
        fill: c.withValues(alpha: 0.08),
        stripColor: null,
      );
    case CornerTile(:final type):
      final icon = switch (type) {
        CornerType.basla => Icons.flag_rounded,
        CornerType.disiplinZiyaret => Icons.gavel_rounded,
        CornerType.cimAmfi => Icons.park_rounded,
        CornerType.disiplineSevk => Icons.report_rounded,
      };
      return (
        icon: icon,
        iconColor: AppColors.accent,
        fill: AppColors.glassStrong,
        stripColor: null,
      );
  }
}
