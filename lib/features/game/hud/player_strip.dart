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
    final isShort = MediaQuery.of(context).size.height < 550;
    final chips = [
      for (final p in state.players)
        _PlayerChip(
          player: p,
          isCurrent: p.id == state.currentPlayer.id && !state.isGameOver,
          properties: state.propertiesOf(p.id).length,
          large: vertical && !isShort,
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

class _PlayerChip extends StatefulWidget {
  const _PlayerChip({
    required this.player,
    required this.isCurrent,
    required this.properties,
    this.large = false,
  });

  final Player player;
  final bool isCurrent;
  final int properties;
  final bool large;

  @override
  State<_PlayerChip> createState() => _PlayerChipState();
}

class _PlayerChipState extends State<_PlayerChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent && !widget.player.bankrupt) {
      _glowCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PlayerChip old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !widget.player.bankrupt) {
      if (!_glowCtrl.isAnimating) _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
      _glowCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.player.bankrupt;
    final padding = widget.large
        ? const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md)
        : const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm);

    final pawnSize = widget.large ? 48.0 : 32.0;
    final nameSize = widget.large ? 20.0 : 13.0;
    final cashSize = widget.large ? 24.0 : 13.0;
    final iconSize = widget.large ? 15.0 : 11.0;

    final nameWidget = Text(
      widget.player.name,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: nameSize,
        color: widget.isCurrent ? AppColors.accent : AppColors.textPrimary,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    final nameRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: nameWidget),
        if (widget.player.inJail)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.gavel_rounded,
              size: 14,
              color: AppColors.negative,
            ),
          ),
      ],
    );

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        nameRow,
        const SizedBox(height: 2),
        if (dim)
          const Text(
            'iflas',
            style: TextStyle(color: AppColors.negative, fontSize: 12, fontWeight: FontWeight.bold),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RollingCredit(
                  widget.player.cash,
                  size: cashSize,
                  color: widget.isCurrent ? AppColors.accent : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.home_work_rounded,
                  size: iconSize,
                  color: AppColors.textFaint,
                ),
                Text(
                  ' ${widget.properties}',
                  style: TextStyle(
                    fontSize: iconSize,
                    color: AppColors.textFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final card = AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glowOpacity = widget.isCurrent && !dim ? _glowAnim.value : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isCurrent && !dim
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35 * glowOpacity),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: GlassCard(
        padding: padding,
        border: widget.isCurrent ? AppColors.accent : AppColors.glassBorder,
        fill: widget.isCurrent
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.glassFill,
        child: Row(
          mainAxisSize: widget.large ? MainAxisSize.max : MainAxisSize.min,
          children: [
            PawnIcon(widget.player.pawn, size: pawnSize, selected: widget.isCurrent),
            const SizedBox(width: AppSpace.md),
            if (widget.large) Expanded(child: contentColumn) else contentColumn,
          ],
        ),
      ),
    );

    // İflas durumunda gri filtre + "İFLAS" badge'i
    if (dim) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.45,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: card,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.negative,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'İFLAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}
