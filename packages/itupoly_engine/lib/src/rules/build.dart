import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/models/tile_group.dart';
import 'package:itupoly_engine/src/rules/rent.dart';

/// Gruptaki en az inşaat sayısı.
int minHousesInGroup(GameState state, TileGroup group) => tilesInGroup(
  group,
).map((i) => state.tileStateAt(i).houses).reduce((a, b) => a < b ? a : b);

/// Gruptaki en çok inşaat sayısı.
int maxHousesInGroup(GameState state, TileGroup group) => tilesInGroup(
  group,
).map((i) => state.tileStateAt(i).houses).reduce((a, b) => a > b ? a : b);

/// Bir kareye derslik/amfi inşa edilebilir mi?
///
/// Koşullar: arsa, sahip oyuncu, tekel, grupta ipotek yok, < 5 inşaat,
/// eşit inşaat kuralı (gruptaki minimumda olan kareye), yeterli nakit.
bool canBuildHouse(GameState state, int tileIndex, int playerId) {
  final tile = boardTr[tileIndex];
  if (tile is! PropertyTile) return false;
  final ts = state.tileStateAt(tileIndex);
  if (ts.ownerId != playerId) return false;
  if (!ownsFullGroup(state, tile.group, playerId)) return false;
  if (anyMortgagedInGroup(state, tile.group)) return false;
  if (ts.houses >= 5) return false;
  if (ts.houses != minHousesInGroup(state, tile.group)) return false;
  if (state.playerById(playerId).cash < tile.houseCost) return false;
  return true;
}

/// Bir karedeki derslik/amfi satılabilir mi? (eşit satış kuralı)
bool canSellHouse(GameState state, int tileIndex, int playerId) {
  final tile = boardTr[tileIndex];
  if (tile is! PropertyTile) return false;
  final ts = state.tileStateAt(tileIndex);
  if (ts.ownerId != playerId) return false;
  if (ts.houses <= 0) return false;
  if (ts.houses != maxHousesInGroup(state, tile.group)) return false;
  return true;
}

/// Bir dersliğin/amfinin satış iadesi (inşaat maliyetinin yarısı).
int houseSellRefund(int tileIndex) {
  final tile = boardTr[tileIndex];
  return tile is PropertyTile ? tile.houseCost ~/ 2 : 0;
}
