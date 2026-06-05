import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/models/tile_group.dart';

/// Bir oyuncu [ownerId] grubun tüm karelerine sahip mi? (tekel)
bool ownsFullGroup(GameState state, TileGroup group, int ownerId) {
  final indices = tilesInGroup(group);
  if (indices.isEmpty) return false;
  return indices.every((i) => state.tileStateAt(i).ownerId == ownerId);
}

/// Grupta ipotekli kare var mı? (inşaat engeli)
bool anyMortgagedInGroup(GameState state, TileGroup group) =>
    tilesInGroup(group).any((i) => state.tileStateAt(i).mortgaged);

/// Oyuncunun ipoteksiz sahip olduğu ring (istasyon) sayısı.
int ringsOwnedUnmortgaged(GameState state, int ownerId) => ringIndices
    .where(
      (i) =>
          state.tileStateAt(i).ownerId == ownerId &&
          !state.tileStateAt(i).mortgaged,
    )
    .length;

/// Oyuncunun ipoteksiz sahip olduğu şirket (altyapı) sayısı.
int utilitiesOwnedUnmortgaged(GameState state, int ownerId) => utilityIndices
    .where(
      (i) =>
          state.tileStateAt(i).ownerId == ownerId &&
          !state.tileStateAt(i).mortgaged,
    )
    .length;

/// Bir kareye gelindiğinde ödenecek kira.
///
/// [diceTotal] yalnızca şirket (altyapı) kirası için gereklidir.
/// İpotekli ya da sahipsiz karede kira 0'dır.
int rentFor(GameState state, int tileIndex, {int diceTotal = 0}) {
  final tile = boardTr[tileIndex];
  final ts = state.tileStateAt(tileIndex);
  if (!ts.isOwned || ts.mortgaged) return 0;

  switch (tile) {
    case PropertyTile(:final rents, :final group):
      if (ts.houses >= 1) return rents[ts.houses];
      // Hiç inşaat yok: tekel varsa temel kira ×2.
      final monopoly = ownsFullGroup(state, group, ts.ownerId!);
      return monopoly ? rents[0] * 2 : rents[0];
    case RingTile _:
      const table = [0, 25, 50, 100, 200];
      return table[ringsOwnedUnmortgaged(state, ts.ownerId!)];
    case UtilityTile _:
      final mult = utilitiesOwnedUnmortgaged(state, ts.ownerId!) >= 2 ? 10 : 4;
      return diceTotal * mult;
    case TaxTile _:
    case CardTile _:
    case CornerTile _:
      return 0;
  }
}
