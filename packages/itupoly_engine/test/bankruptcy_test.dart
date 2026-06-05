import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

void main() {
  test('ödenemeyen kira → tasfiye → ipotekle borç kapanır', () {
    final engine = GameEngine(ScriptedRandom([1, 2])); // 3 kare: 13 → 16
    final s = gameWith(
      players: [player(0, cash: 20, position: 13), player(1)],
      tiles: {
        6: const TileState(ownerId: 0), // P0 ipotek edebilir (değer 50)
        16: const TileState(ownerId: 1),
        18: const TileState(ownerId: 1),
        19: const TileState(ownerId: 1), // P1 turuncu tekel
      },
    );
    final total0 = conservationTotal(s);

    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.phase, TurnPhase.mustLiquidate);
    expect(s1.pendingDebt!.amount, 28); // 14 × 2 (tekel)

    final (s2, _) = engine.submit(s1, const MortgageTile(6));
    expect(s2.pendingDebt, isNull);
    expect(s2.players[0].cash, 20 + 50 - 28);
    expect(s2.players[1].cash, 1500 + 28);
    expect(conservationTotal(s2), total0);
  });

  test('iflas → varlıklar alacaklı oyuncuya geçer + oyun biter', () {
    final engine = GameEngine(ScriptedRandom([3, 5])); // 8 kare: 31 → 39
    final s = gameWith(
      players: [player(0, cash: 20, position: 31), player(1)],
      tiles: {
        37: const TileState(ownerId: 1),
        39: const TileState(ownerId: 1, houses: 5), // amfi, kira 2000
      },
    );
    final total0 = conservationTotal(s);

    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.phase, TurnPhase.mustLiquidate);

    final (s2, _) = engine.submit(s1, const DeclareBankruptcy());
    expect(s2.players[0].bankrupt, true);
    expect(s2.phase, TurnPhase.gameOver);
    expect(s2.winnerId, 1);
    expect(s2.players[1].cash, 1500 + 20); // P0'ın nakdi alacaklıya
    expect(conservationTotal(s2), total0);
  });

  test('bankaya iflas → kareler serbest kalır, oyun sürer', () {
    final engine = GameEngine(ScriptedRandom([2, 2])); // 4: Dönem Harcı 200
    final s = gameWith(
      players: [player(0, cash: 20), player(1), player(2)],
      tiles: {6: const TileState(ownerId: 0)},
    );
    final total0 = conservationTotal(s);

    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.phase, TurnPhase.mustLiquidate);
    expect(s1.pendingDebt!.toPlayerId, isNull); // banka

    final (s2, _) = engine.submit(s1, const DeclareBankruptcy());
    expect(s2.players[0].bankrupt, true);
    expect(s2.tileStateAt(6).isOwned, false); // bankaya döndü
    expect(s2.phase, isNot(TurnPhase.gameOver)); // 2 oyuncu kaldı
    expect(conservationTotal(s2), total0);
  });

  test('maxRaisableCash hesabı', () {
    final s = gameWith(
      players: [player(0, cash: 100)],
      tiles: {
        6: const TileState(ownerId: 0), // ipotek 50
        8: const TileState(ownerId: 0, mortgaged: true), // ipotekli, 0
      },
    );
    expect(maxRaisableCash(s, 0), 100 + 50);
  });
}
