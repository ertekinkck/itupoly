import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/rules/build.dart';
import 'package:itupoly_engine/src/rules/mortgage.dart';

/// Bir oyuncunun tasfiyeyle yaratabileceği azami nakit:
/// mevcut nakit + ipotek değerleri + inşaat satış iadeleri.
///
/// Borç bu değeri aşıyorsa oyuncu iflas etmek zorundadır.
int maxRaisableCash(GameState state, int playerId) {
  var total = state.playerById(playerId).cash;
  for (final i in state.propertiesOf(playerId)) {
    final ts = state.tileStateAt(i);
    if (!ts.mortgaged) total += mortgageValue(i);
    total += ts.houses * houseSellRefund(i);
  }
  return total;
}

/// Görsel/sıralama için net değer:
/// nakit + (ipoteksiz arsa tam değeri / ipotekli arsa öz sermayesi) + inşaatlar.
int netWorth(GameState state, int playerId) {
  var total = state.playerById(playerId).cash;
  for (final i in state.propertiesOf(playerId)) {
    final ts = state.tileStateAt(i);
    final tile = boardTr[i];
    if (ts.mortgaged) {
      total += tile.purchasePrice - mortgageValue(i);
    } else {
      total += tile.purchasePrice;
    }
    if (tile is PropertyTile) {
      total += ts.houses * tile.houseCost;
    }
  }
  return total;
}
