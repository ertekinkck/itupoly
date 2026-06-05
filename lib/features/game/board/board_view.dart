import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/board/board_geometry.dart';
import 'package:itupoly/features/game/board/board_pawns.dart';
import 'package:itupoly/features/game/board/tile_widget.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Tahta — açılı 3B perspektif (kuşbakışı değil). Düzlem eğik; piyonlar/binalar
/// dik ayakta. Kamera, perspektif projeksiyonuyla aktif piyonu izler.
class BoardView extends StatefulWidget {
  const BoardView({required this.state, required this.onTapTile, super.key});

  final GameState state;
  final void Function(int index) onTapTile;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _cam;
  Matrix4Tween? _camTween;

  double _side = 0;
  bool _userControlling = false;
  Timer? _resumeTimer;
  String _focusKey = '';

  @override
  void initState() {
    super.initState();
    _cam =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          final tween = _camTween;
          if (tween != null) _transform.value = tween.evaluate(_cam);
        });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _cam.dispose();
    _transform.dispose();
    super.dispose();
  }

  /// Tahta düzlemine uygulanan perspektif (alignment center hariç ham matris).
  Matrix4 _rawPersp() => Matrix4.identity()
    ..setEntry(3, 2, boardDepth)
    ..rotateX(boardTilt)
    ..scaleByDouble(boardFit, boardFit, 1, 1);

  /// Alignment-center'lı tam perspektif (projeksiyon için).
  Matrix4 _wrappedPersp(double side) {
    final c = side / 2;
    return Matrix4.identity()
      ..translateByDouble(c, c, 0, 1)
      ..multiply(_rawPersp())
      ..translateByDouble(-c, -c, 0, 1);
  }

  /// Kamera matrisi: bekleme → tüm tahta; aksiyon/karar → piyona yakınlaş.
  Matrix4 _focusMatrix(double side) {
    final phase = widget.state.phase;
    final tile = side / gridDim;
    final waiting =
        phase == TurnPhase.awaitRoll ||
        phase == TurnPhase.inDisiplin ||
        phase == TurnPhase.gameOver;

    final double s;
    final Offset planeP;
    if (waiting) {
      s = 0.95;
      planeP = Offset(side / 2, side / 2); // tüm tahta
    } else {
      s = switch (phase) {
        TurnPhase.awaitBuyDecision || TurnPhase.mustLiquidate => 1.5,
        TurnPhase.endTurn => 1.3,
        _ => 1.1,
      };
      final cell = tileCell(widget.state.currentPlayer.position);
      planeP = Offset((cell.$2 + 0.5) * tile, (cell.$1 + 0.5) * tile);
    }

    final pj = MatrixUtils.transformPoint(_wrappedPersp(side), planeP);
    final tx = side / 2 - s * pj.dx;
    final ty = side / 2 - s * pj.dy;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _maybeUpdateCamera(double side) {
    _side = side;
    final key =
        '${widget.state.currentPlayerIndex}'
        ':${widget.state.currentPlayer.position}'
        ':${widget.state.phase}'
        ':${side.toStringAsFixed(0)}';
    if (key == _focusKey) return;
    final first = _focusKey.isEmpty;
    _focusKey = key;
    if (_userControlling) return;
    final target = _focusMatrix(side);
    if (first) {
      _transform.value = target;
      return;
    }
    _camTween = Matrix4Tween(begin: _transform.value, end: target);
    _cam.forward(from: 0);
  }

  void _onInteractionStart(ScaleStartDetails _) {
    _userControlling = true;
    _resumeTimer?.cancel();
    if (_cam.isAnimating) _cam.stop();
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _userControlling = false;
      _camTween = Matrix4Tween(
        begin: _transform.value,
        end: _focusMatrix(_side),
      );
      _cam.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final highlight = s.phase == TurnPhase.awaitBuyDecision
        ? s.currentPlayer.position
        : -1;

    return LayoutBuilder(
      builder: (context, c) {
        final side = min(c.maxWidth, c.maxHeight);
        final tile = side / gridDim;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeUpdateCamera(side);
        });
        return ClipRect(
          child: Center(
            child: SizedBox(
              width: side,
              height: side,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 0.6,
                maxScale: 3,
                boundaryMargin: EdgeInsets.all(side * 1.5),
                onInteractionStart: _onInteractionStart,
                onInteractionEnd: _onInteractionEnd,
                child: Transform(
                  alignment: Alignment.center,
                  transform: _rawPersp(),
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Masaya gömülü zemin gölgesi (derinlik).
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(tile * 0.4),
                              gradient: const RadialGradient(
                                colors: [Color(0xFF13203B), AppColors.bg],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 40,
                                  offset: const Offset(0, 30),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: tile,
                          top: tile,
                          width: side - 2 * tile,
                          height: side - 2 * tile,
                          child: const _BoardCenter(),
                        ),
                        for (var i = 0; i < boardSize; i++)
                          _positionedTile(i, tile, highlight),
                        BoardPawns(
                          players: s.players,
                          tile: tile,
                          activeId: s.currentPlayer.id,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _positionedTile(int i, double tile, int highlight) {
    final cell = tileCell(i);
    final ts = widget.state.tileStateAt(i);
    final ownerColor = ts.ownerId != null
        ? PawnVisuals.colorOf(widget.state.playerById(ts.ownerId!).pawn)
        : null;
    return Positioned(
      left: cell.$2 * tile,
      top: cell.$1 * tile,
      width: tile,
      height: tile,
      child: RepaintBoundary(
        child: BoardTile(
          tile: boardTr[i],
          ts: ts,
          size: tile,
          ownerColor: ownerColor,
          highlighted: i == highlight,
          onTap: () => widget.onTapTile(i),
        ),
      ),
    );
  }
}

/// Tahtanın ortasında dik duran amblem (3B merkez parça).
class _BoardCenter extends StatelessWidget {
  const _BoardCenter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..rotateX(-boardTilt),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/emblem.png',
              width: 120,
              height: 120,
              errorBuilder: (context, _, __) => Icon(
                Icons.hive_rounded,
                color: AppColors.accent.withValues(alpha: 0.6),
                size: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
