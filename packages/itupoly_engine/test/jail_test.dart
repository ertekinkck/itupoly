import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

GameState jailedGame({
  int jailTurns = 0,
  List<DeckType> afKarti = const [],
  int cash = 1500,
}) => gameWith(
  players: [
    player(
      0,
      inJail: true,
      position: disiplinIndex,
      jailTurns: jailTurns,
      afKarti: afKarti,
      cash: cash,
    ),
    player(1),
  ],
  phase: TurnPhase.inDisiplin,
);

void main() {
  test('Disipline Sevk! köşesine gelince hapse', () {
    final g = newScriptedGame([2, 3]); // 5 → 25'ten 30'a
    final s0 = g.state.withPlayer(g.state.players[0].copyWith(position: 25));
    final (s, _) = g.engine.submit(s0, const RollDice());
    expect(s.players[0].inJail, true);
    expect(s.players[0].position, disiplinIndex);
    expect(s.phase, TurnPhase.endTurn);
  });

  test('ceza ödeyerek çıkış → zar at', () {
    final engine = GameEngine(ScriptedRandom([1, 3])); // sonra 4 kare
    var (s, _) = engine.submit(jailedGame(), const PayDisiplinFine());
    expect(s.players[0].inJail, false);
    expect(s.players[0].cash, 1500 - disiplinFine);
    expect(s.phase, TurnPhase.awaitRoll);

    (s, _) = engine.submit(s, const RollDice());
    expect(s.players[0].position, 14);
    expect(conservationTotal(s), 2 * startingCash);
  });

  test('Af Kartı ile çıkış, kart desteye döner', () {
    final engine = GameEngine(ScriptedRandom([1, 1]));
    final (s, _) = engine.submit(
      jailedGame(afKarti: [DeckType.sans]),
      const UseAfKarti(),
    );
    expect(s.players[0].inJail, false);
    expect(s.players[0].afKarti, isEmpty);
    expect(s.phase, TurnPhase.awaitRoll);
    expect(s.sansDeck.contains(afKartiCardId(DeckType.sans)), true);
  });

  test('çift atarak çıkış → hareket, ekstra atış yok', () {
    final engine = GameEngine(ScriptedRandom([4, 4])); // çift
    final (s, _) = engine.submit(jailedGame(), const RollDice());
    expect(s.players[0].inJail, false);
    expect(s.players[0].position, 18); // 10 + 8
    expect(s.doublesCount, 0);
    expect(s.phase, TurnPhase.awaitBuyDecision);
  });

  test('ilk başarısız deneme → hapiste kal', () {
    final engine = GameEngine(ScriptedRandom([1, 2])); // çift değil
    final (s, _) = engine.submit(jailedGame(), const RollDice());
    expect(s.players[0].inJail, true);
    expect(s.players[0].jailTurns, 1);
    expect(s.phase, TurnPhase.endTurn);
  });

  test('üçüncü başarısız deneme → ceza zorunlu + hareket', () {
    final engine = GameEngine(ScriptedRandom([1, 2])); // 3, çift değil
    final (s, _) = engine.submit(jailedGame(jailTurns: 2), const RollDice());
    expect(s.players[0].inJail, false);
    expect(s.players[0].cash, 1500 - disiplinFine);
    expect(s.players[0].position, 13); // 10 + 3
    expect(conservationTotal(s), 2 * startingCash);
  });
}
