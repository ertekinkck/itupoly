import 'package:flutter/widgets.dart';
import 'package:itupoly/features/game/board/board_view.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// VM/test ortamı (ve web olmayan hedefler) için 2B tahta.
/// [onAnimEvent] 2B modda kullanılmaz (3B köprüsü yok); null geçirilir.
Widget buildBoard(
  GameState state,
  void Function(int index) onTapTile, {
  void Function(String kind)? onAnimEvent,
}) {
  return BoardView(state: state, onTapTile: onTapTile);
}
