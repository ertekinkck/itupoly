import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

void main() {
  final engine = GameEngine(ScriptedRandom([1]));

  group('inşaat', () {
    GameState brownMonopoly() => gameWith(
      players: [player(0), player(1)],
      tiles: {
        1: const TileState(ownerId: 0),
        3: const TileState(ownerId: 0),
      },
      phase: TurnPhase.endTurn,
    );

    test('tekel olmadan inşaat yapılamaz', () {
      final s = gameWith(
        players: [player(0)],
        tiles: {1: const TileState(ownerId: 0)},
        phase: TurnPhase.endTurn,
      );
      expect(canBuildHouse(s, 1, 0), false);
    });

    test('tekelde inşaat + maliyet', () {
      final s = brownMonopoly();
      expect(canBuildHouse(s, 1, 0), true);
      final (s2, _) = engine.submit(s, const BuildHouse(1));
      expect(s2.tileStateAt(1).houses, 1);
      expect(s2.players[0].cash, 1500 - 50);
      expect(conservationTotal(s2), 2 * startingCash);
    });

    test('eşit inşaat kuralı', () {
      final s = brownMonopoly();
      final (s2, _) = engine.submit(s, const BuildHouse(1));
      // 1'de 1 derslik var; 3'te 0. Tekrar 1'e yapılamaz, 3'e yapılır.
      expect(canBuildHouse(s2, 1, 0), false);
      expect(canBuildHouse(s2, 3, 0), true);
    });

    test('amfi (5. seviye) ancak hepsi 4 dersliğe ulaşınca', () {
      var s = gameWith(
        players: [player(0)],
        tiles: {
          1: const TileState(ownerId: 0, houses: 4),
          3: const TileState(ownerId: 0, houses: 3),
        },
        phase: TurnPhase.endTurn,
      );
      expect(canBuildHouse(s, 1, 0), false); // 3 henüz 4 değil
      s = s.withTileState(3, const TileState(ownerId: 0, houses: 4));
      expect(canBuildHouse(s, 1, 0), true);
      final (s2, _) = engine.submit(s, const BuildHouse(1));
      expect(s2.tileStateAt(1).hasHotel, true);
    });

    test('derslik satışı eşit kuralla, yarı iade', () {
      final s = gameWith(
        players: [player(0)],
        tiles: {
          1: const TileState(ownerId: 0, houses: 2),
          3: const TileState(ownerId: 0, houses: 1),
        },
        phase: TurnPhase.endTurn,
      );
      expect(canSellHouse(s, 1, 0), true); // 1 en yüksekte
      expect(canSellHouse(s, 3, 0), false);
      final (s2, _) = engine.submit(s, const SellHouse(1));
      expect(s2.tileStateAt(1).houses, 1);
      expect(s2.players[0].cash, 1500 + 25); // 50/2
    });
  });

  group('ipotek', () {
    test('ipotek değeri ve geri alma maliyeti', () {
      expect(mortgageValue(39), 200); // fiyat 400
      expect(unmortgageCost(39), 220); // 200 + %10
      expect(mortgageValue(37), 175); // fiyat 350
      expect(unmortgageCost(37), 193); // 175 + 18 (17.5 yuvarlanır)
    });

    test('ipotek + nakit', () {
      final s = gameWith(
        players: [player(0)],
        tiles: {6: const TileState(ownerId: 0)},
        phase: TurnPhase.endTurn,
      );
      expect(canMortgage(s, 6, 0), true);
      final (s2, _) = engine.submit(s, const MortgageTile(6));
      expect(s2.tileStateAt(6).mortgaged, true);
      expect(s2.players[0].cash, 1500 + 50);
      expect(conservationTotal(s2), startingCash);
    });

    test('grupta inşaat varken ipotek yapılamaz', () {
      final s = gameWith(
        players: [player(0)],
        tiles: {
          1: const TileState(ownerId: 0, houses: 1),
          3: const TileState(ownerId: 0),
        },
        phase: TurnPhase.endTurn,
      );
      expect(canMortgage(s, 3, 0), false);
    });

    test('ipotek geri alma', () {
      var s = gameWith(
        players: [player(0)],
        tiles: {6: const TileState(ownerId: 0, mortgaged: true)},
        phase: TurnPhase.endTurn,
      );
      expect(canUnmortgage(s, 6, 0), true);
      final (s2, _) = engine.submit(s, const UnmortgageTile(6));
      s = s2;
      expect(s.tileStateAt(6).mortgaged, false);
      expect(s.players[0].cash, 1500 - unmortgageCost(6));
    });
  });
}
