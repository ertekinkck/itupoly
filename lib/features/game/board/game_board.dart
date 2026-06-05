import 'package:flutter/widgets.dart';
// Web'de three.js 3B tahta, diğer hedeflerde (VM/test) 2B tahta.
import 'package:itupoly/features/game/board/board_impl_2d.dart'
    if (dart.library.js_interop) 'package:itupoly/features/game/board/board_impl_3d.dart'
    as impl;
import 'package:itupoly_engine/itupoly_engine.dart';

/// Platforma göre doğru tahta uygulamasını seçen sarmalayıcı.
class GameBoard extends StatelessWidget {
  const GameBoard({
    required this.state,
    required this.onTapTile,
    this.onAnimEvent,
    super.key,
  });

  final GameState state;
  final void Function(int index) onTapTile;
  /// 3B sahne animasyon olayları: 'diceSettled' | 'idle'.
  /// 2B modda asla çağrılmaz.
  final void Function(String kind)? onAnimEvent;

  @override
  Widget build(BuildContext context) =>
      impl.buildBoard(state, onTapTile, onAnimEvent: onAnimEvent);
}
