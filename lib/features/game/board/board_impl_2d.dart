import 'package:flutter/widgets.dart';
import 'package:itupoly/features/game/board/board_view.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// VM/test ortamı (ve web olmayan hedefler) için 2B tahta.
Widget buildBoard(GameState state, void Function(int index) onTapTile) {
  return BoardView(state: state, onTapTile: onTapTile);
}
