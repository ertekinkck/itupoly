import 'package:flutter/widgets.dart';
import 'package:itupoly/features/game/board/board3d_view.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Web hedefi için gerçek 3B tahta (three.js).
Widget buildBoard(
  GameState state,
  void Function(int index) onTapTile, {
  void Function(String kind)? onAnimEvent,
}) {
  return Board3DView(state: state, onTapTile: onTapTile, onAnimEvent: onAnimEvent);
}
