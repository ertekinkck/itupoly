import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

void main() {
  group('temel tur akışı', () {
    test('arsaya gel → satın al → tur bitir → sıra geçer', () {
      final g = newScriptedGame([2, 4]); // toplam 6 → tile 6 (Maçka)
      var (s, _) = g.engine.submit(g.state, const RollDice());
      expect(s.currentPlayer.position, 6);
      expect(s.phase, TurnPhase.awaitBuyDecision);

      (s, _) = g.engine.submit(s, const BuyProperty());
      expect(s.tileStateAt(6).ownerId, 0);
      expect(s.players[0].cash, 1400);
      expect(s.phase, TurnPhase.endTurn);
      expect(conservationTotal(s), 2 * startingCash);

      (s, _) = g.engine.submit(s, const EndTurn());
      expect(s.currentPlayerIndex, 1);
      expect(s.phase, TurnPhase.awaitRoll);
    });

    test('reddet → arsa bankada kalır', () {
      final g = newScriptedGame([2, 4]);
      var (s, _) = g.engine.submit(g.state, const RollDice());
      (s, _) = g.engine.submit(s, const DeclineBuy());
      expect(s.tileStateAt(6).isOwned, false);
      expect(s.phase, TurnPhase.endTurn);
    });

    test("BAŞLA'dan geçince +200 burs", () {
      final g = newScriptedGame([1, 3]); // 4 kare
      final s0 = g.state.withPlayer(g.state.players[0].copyWith(position: 37));
      final (s, _) = g.engine.submit(s0, const RollDice());
      expect(s.players[0].position, 1);
      expect(s.players[0].cash, startingCash + salaryAmount);
      expect(conservationTotal(s), 2 * startingCash);
    });

    test('vergi karesi bankaya ödenir', () {
      final g = newScriptedGame([2, 2]); // 4 → Dönem Harcı 200
      final (s, _) = g.engine.submit(g.state, const RollDice());
      expect(s.players[0].cash, startingCash - 200);
      expect(conservationTotal(s), 2 * startingCash);
    });

    test('rakibe kira otomatik ödenir', () {
      final g = newScriptedGame([2, 4]); // tile 6, sahibi P1
      final s0 = g.state.withTileState(6, const TileState(ownerId: 1));
      final (s, _) = g.engine.submit(s0, const RollDice());
      expect(s.players[0].cash, startingCash - 6);
      expect(s.players[1].cash, startingCash + 6);
      expect(s.phase, TurnPhase.endTurn);
    });
  });

  group('çift zar kuralı', () {
    test('çift atınca tekrar zar hakkı', () {
      final g = newScriptedGame([3, 3]); // çift, tile 6
      var (s, _) = g.engine.submit(g.state, const RollDice());
      expect(s.doublesCount, 1);
      (s, _) = g.engine.submit(s, const DeclineBuy());
      expect(s.phase, TurnPhase.awaitRoll); // ekstra atış
    });

    test('üç kez üst üste çift → Disipline sevk', () {
      final g = newScriptedGame([2, 2, 3, 3, 1, 1]);
      var (s, _) = g.engine.submit(g.state, const RollDice()); // 4: vergi
      expect(s.doublesCount, 1);
      expect(s.phase, TurnPhase.awaitRoll);

      (s, _) = g.engine.submit(s, const RollDice()); // 10: ziyaretçi
      expect(s.doublesCount, 2);
      expect(s.players[0].position, 10);
      expect(s.phase, TurnPhase.awaitRoll);

      (s, _) = g.engine.submit(s, const RollDice()); // 3. çift → hapis
      expect(s.players[0].inJail, true);
      expect(s.players[0].position, disiplinIndex);
      expect(s.doublesCount, 0);
      expect(s.phase, TurnPhase.endTurn);
    });
  });

  group('legalActions', () {
    test('awaitRoll: zar atılabilir', () {
      final g = newScriptedGame([1, 1]);
      final legal = g.engine.legalActions(g.state);
      expect(legal.any((a) => a is RollDice), true);
    });

    test('gameOver: boş', () {
      final s = gameWith(
        players: [player(0)],
        phase: TurnPhase.gameOver,
      );
      final engine = GameEngine(ScriptedRandom([1]));
      expect(engine.legalActions(s), isEmpty);
    });
  });
}
