import 'dart:math';

import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

void main() {
  test('tur limitine ulaşan oyun en yüksek net değerle biter', () {
    final engine = GameEngine(Random(3), maxTurns: 20);
    final result = autoPlay(
      engine,
      engine.newGame(const [
        PlayerSetup(name: 'A', pawn: PawnType.ari, isBot: true),
        PlayerSetup(name: 'B', pawn: PawnType.pergel, isBot: true),
      ]),
    );
    expect(result.completed, true);
    final s = result.finalState;
    expect(s.winnerId, isNotNull);
    expect(s.playerById(s.winnerId!).bankrupt, false);
    // Eleme olmadıysa tur limitinde bitmeli.
    if (s.players.where((p) => !p.bankrupt).length > 1) {
      expect(s.turnCount, greaterThanOrEqualTo(20));
    }
  });

  test('bozuk alacaklı id ile iflas reducer çökmez (savunmacı guard)', () {
    final s = gameWith(
      players: [player(0, cash: 100), player(1)],
      tiles: {6: const TileState(ownerId: 0)},
    );
    final before = conservationTotal(s);
    // Geçersiz toPlayerId (999) → bankaya iflas gibi davranır, RangeError yok.
    final after = reduce(
      s,
      const PlayerBankrupted(playerId: 0, toPlayerId: 999),
    );
    expect(after.playerById(0).bankrupt, true);
    expect(after.tileStateAt(6).isOwned, false); // bankaya döndü
    expect(conservationTotal(after), before);
  });
}
