import 'dart:convert';
import 'dart:math';

import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

List<PlayerSetup> _setups() => const [
  PlayerSetup(name: 'A', pawn: PawnType.ari, isBot: true),
  PlayerSetup(name: 'B', pawn: PawnType.pergel, isBot: true),
  PlayerSetup(name: 'C', pawn: PawnType.baret, isBot: true),
  PlayerSetup(name: 'D', pawn: PawnType.kahve, isBot: true),
];

String _hash(GameState s) => jsonEncode(s.toJson());

void main() {
  test('aynı seed + aynı aksiyon dizisi → birebir aynı state', () {
    for (final seed in [1, 7, 42, 100, 2026]) {
      final e1 = GameEngine(Random(seed));
      final r1 = autoPlay(e1, e1.newGame(_setups()));

      final e2 = GameEngine(Random(seed));
      final r2 = autoPlay(e2, e2.newGame(_setups()));

      expect(
        _hash(r1.finalState),
        _hash(r2.finalState),
        reason: 'seed=$seed state farklı',
      );
      expect(r1.actions.length, r2.actions.length, reason: 'seed=$seed');
    }
  });

  test('kaydet=seed+aksiyonlar, yükle=replay aynı state üretir', () {
    for (final seed in [3, 21, 99]) {
      final e1 = GameEngine(Random(seed));
      final init1 = e1.newGame(_setups());
      final r1 = autoPlay(e1, init1);

      // Taze motor + aynı seed (deste karıştırma aynı) + kayıtlı aksiyonlar.
      final e2 = GameEngine(Random(seed));
      final init2 = e2.newGame(_setups());
      final replayed = replay(e2, init2, r1.actions);

      expect(
        _hash(replayed),
        _hash(r1.finalState),
        reason: 'seed=$seed replay',
      );
    }
  });

  test('state JSON round-trip (serileştirme tutarlı)', () {
    final e = GameEngine(Random(5));
    final r = autoPlay(e, e.newGame(_setups()), maxActions: 500);
    final json = _hash(r.finalState);
    final restored = GameState.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
    expect(_hash(restored), json);
  });
}
