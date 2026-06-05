import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

/// Desteyi belirli bir kartı en üste alacak şekilde düzenler.
GameState withSansTop(GameState s, int cardId) =>
    s.copyWith(sansDeck: [cardId, ...s.sansDeck.where((x) => x != cardId)]);

GameState withKampusTop(GameState s, int cardId) =>
    s.copyWith(kampusDeck: [cardId, ...s.kampusDeck.where((x) => x != cardId)]);

void main() {
  test('GainMoney kartı + deste döngüsü', () {
    final engine = GameEngine(ScriptedRandom([3, 4])); // 7 → Şans
    final s = withSansTop(gameWith(players: [player(0), player(1)]), 1);
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].cash, 1500 + 150);
    expect(s1.sansDeck.last, 1); // çekilen kart en alta gitti
    expect(s1.sansDeck.length, 16);
  });

  test('GoToDisiplin kartı → hapis', () {
    final engine = GameEngine(ScriptedRandom([3, 4]));
    final s = withSansTop(gameWith(players: [player(0), player(1)]), 3);
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].inJail, true);
    expect(s1.phase, TurnPhase.endTurn);
  });

  test('MoveTo BAŞLA → ilerle + 200 burs', () {
    final engine = GameEngine(ScriptedRandom([3, 4]));
    final s = withSansTop(gameWith(players: [player(0), player(1)]), 7);
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].position, 0);
    expect(s1.players[0].cash, 1500 + salaryAmount);
  });

  test('GetAfKarti kartı oyuncuda kalır, desteden çıkar', () {
    final engine = GameEngine(ScriptedRandom([3, 4]));
    final s = withSansTop(gameWith(players: [player(0), player(1)]), 4);
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].afKarti, contains(DeckType.sans));
    expect(s1.sansDeck.contains(4), false);
    expect(s1.sansDeck.length, 15);
  });

  test('CollectFromEach: her rakipten toplanır', () {
    final engine = GameEngine(ScriptedRandom([3, 4])); // 10 → 17 Kampüs
    final s = withKampusTop(
      gameWith(players: [player(0, position: 10), player(1), player(2)]),
      2,
    );
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].cash, 1500 + 20);
    expect(s1.players[1].cash, 1490);
    expect(s1.players[2].cash, 1490);
    expect(conservationTotal(s1), 3 * startingCash);
  });

  test('PayMoney kartı bankaya öder', () {
    final engine = GameEngine(ScriptedRandom([3, 4]));
    // Şans id 0 = Bütünleme -100
    final s = withSansTop(gameWith(players: [player(0), player(1)]), 0);
    final (s1, _) = engine.submit(s, const RollDice());
    expect(s1.players[0].cash, 1500 - 100);
    expect(conservationTotal(s1), 2 * startingCash);
  });
}
