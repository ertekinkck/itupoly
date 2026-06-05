import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/tile.dart';

/// İpotek değeri (fiyatın yarısı).
int mortgageValue(int tileIndex) => boardTr[tileIndex].purchasePrice ~/ 2;

/// İpoteği geri alma maliyeti (ipotek değeri + %10 faiz).
int unmortgageCost(int tileIndex) {
  final v = mortgageValue(tileIndex);
  return v + (v * 0.1).round();
}

/// Bir kare ipotek edilebilir mi?
///
/// Koşullar: satın alınabilir kare, sahip oyuncu, ipotekli değil, ve (arsaysa)
/// grubunda hiç inşaat olmamalı (önce derslikler satılmalı).
bool canMortgage(GameState state, int tileIndex, int playerId) {
  final tile = boardTr[tileIndex];
  if (!tile.isOwnable) return false;
  final ts = state.tileStateAt(tileIndex);
  if (ts.ownerId != playerId) return false;
  if (ts.mortgaged) return false;
  if (tile is PropertyTile) {
    final anyHouses = tilesInGroup(
      tile.group,
    ).any((i) => state.tileStateAt(i).houses > 0);
    if (anyHouses) return false;
  }
  return true;
}

/// İpotek geri alınabilir mi? (yeterli nakit gerekir)
bool canUnmortgage(GameState state, int tileIndex, int playerId) {
  final tile = boardTr[tileIndex];
  if (!tile.isOwnable) return false;
  final ts = state.tileStateAt(tileIndex);
  if (ts.ownerId != playerId) return false;
  if (!ts.mortgaged) return false;
  return state.playerById(playerId).cash >= unmortgageCost(tileIndex);
}
