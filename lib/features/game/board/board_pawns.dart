import 'dart:math';

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/board/board_geometry.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Piyon katmanı — kare kare hop animasyonuyla çevre boyunca hareket.
class BoardPawns extends StatefulWidget {
  const BoardPawns({
    required this.players,
    required this.tile,
    required this.activeId,
    super.key,
  });

  final List<Player> players;
  final double tile;
  final int? activeId;

  @override
  State<BoardPawns> createState() => _BoardPawnsState();
}

class _BoardPawnsState extends State<BoardPawns> with TickerProviderStateMixin {
  final Map<int, double> _curT = {};
  final Map<int, AnimationController> _ctrl = {};

  @override
  void initState() {
    super.initState();
    for (final p in widget.players) {
      _curT[p.id] = p.position.toDouble();
    }
  }

  @override
  void didUpdateWidget(BoardPawns old) {
    super.didUpdateWidget(old);
    for (final p in widget.players) {
      final cur = _curT[p.id] ?? p.position.toDouble();
      final curIndex = (cur.round()) % 40;
      if (curIndex != p.position) {
        _animate(p.id, cur, p.position);
      }
    }
  }

  void _animate(int id, double fromT, int target) {
    _ctrl[id]?.dispose();
    final steps = signedSteps(fromT.round() % 40, target);
    final toT = fromT + steps;
    final controller = AnimationController(
      vsync: this,
      duration: AppDuration.hopPerTile * steps.abs().clamp(1, 12),
    );
    _ctrl[id] = controller;
    controller.addListener(() {
      setState(() {
        _curT[id] =
            fromT +
            (toT - fromT) * Curves.easeInOut.transform(controller.value);
      });
    });
    controller.forward().whenComplete(() {
      _curT[id] = target.toDouble();
      controller.dispose();
      _ctrl.remove(id);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Aynı karedeki piyonlar için küçük dağıtım ofseti.
  Offset _clusterOffset(int id) {
    final col = id % 3 - 1;
    final row = id ~/ 3 - 0.5;
    return Offset(col * widget.tile * 0.20, row * widget.tile * 0.24);
  }

  @override
  Widget build(BuildContext context) {
    final pawnSize = widget.tile * 0.52;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in widget.players)
            if (!p.bankrupt) _positioned(p, pawnSize),
        ],
      ),
    );
  }

  Widget _positioned(Player p, double pawnSize) {
    final t = _curT[p.id] ?? p.position.toDouble();
    final center = trackToOffset(t, widget.tile) + _clusterOffset(p.id);

    // Kare kare yay: her segment ortasında zirve, kare merkezinde yere değer.
    final frac = t - t.floorToDouble();
    final maxLift = widget.tile * 0.45;
    final lift = maxLift * sin(pi * frac).abs();
    final liftRatio = lift / maxLift;
    final shadowScale = 1 - liftRatio * 0.55;

    final boxH = pawnSize * 2.6;
    return Positioned(
      left: center.dx - pawnSize / 2,
      top: center.dy - boxH,
      width: pawnSize,
      height: boxH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Zeminde yatan gölge (düzlemde; yükseldikçe küçülüp soluyor).
          Container(
            width: pawnSize * 0.7 * shadowScale,
            height: pawnSize * 0.2 * shadowScale,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4 * shadowScale),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Dik ayakta token (ters-döndürülerek kameraya bakar).
          Positioned(
            bottom: lift,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()..rotateX(-boardTilt),
              child: PawnIcon(
                p.pawn,
                size: pawnSize,
                selected: p.id == widget.activeId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
