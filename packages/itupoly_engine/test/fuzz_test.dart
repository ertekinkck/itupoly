import 'dart:math';

import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

List<PlayerSetup> _setups(int n) => [
  for (var i = 0; i < n; i++)
    PlayerSetup(
      name: 'Bot$i',
      pawn: PawnType.values[i],
      isBot: true,
    ),
];

void main() {
  test(
    '1000 tam oyun: tüm invariantlar korunur',
    () {
      const gameCount = 1000;
      var totalActions = 0;
      var longest = 0;
      var byElimination = 0;
      var byTurnLimit = 0;

      for (var seed = 0; seed < gameCount; seed++) {
        final engine = GameEngine(Random(seed));
        final n = 2 + (seed % 5); // 2–6 oyuncu çeşitliliği
        final init = engine.newGame(_setups(n));
        final expectedTotal = init.totalPlayerCash;

        final result = autoPlay(
          engine,
          init,
          maxActions: 60000,
          onStep: (s, action, events) {
            // (1) Hiçbir bakiye negatif kalmaz.
            for (final p in s.players) {
              if (p.cash < 0) {
                fail(
                  'Negatif bakiye: seed=$seed oyuncu=${p.id} nakit=${p.cash}',
                );
              }
            }
            // (2) Para korunumu (banka giriş-çıkışıyla).
            if (s.totalPlayerCash + s.bankBalanceDelta != expectedTotal) {
              fail('Para korunumu bozuldu: seed=$seed');
            }
            // (3) İnşaat 0–5 aralığında.
            for (final ts in s.tileStates) {
              if (ts.houses < 0 || ts.houses > 5) {
                fail('Geçersiz inşaat: seed=$seed houses=${ts.houses}');
              }
            }
          },
        );

        // (4) Her oyun sonlanır (tur limiti emniyeti).
        if (!result.completed) {
          fail('Oyun bitmedi: seed=$seed (${result.actionCount} adım)');
        }
        // (5) Kazanan tespit edilir ve kazanan iflas etmemiştir.
        final winnerId = result.finalState.winnerId;
        expect(winnerId, isNotNull, reason: 'seed=$seed kazanan yok');
        expect(
          result.finalState.playerById(winnerId!).bankrupt,
          false,
          reason: 'seed=$seed kazanan iflas etmiş',
        );

        final survivors = result.finalState.players
            .where((p) => !p.bankrupt)
            .length;
        if (survivors == 1) {
          byElimination++;
        } else {
          byTurnLimit++;
        }

        totalActions += result.actionCount;
        if (result.actionCount > longest) longest = result.actionCount;
      }

      // Test özetini görünür kılmak için kasıtlı çıktı.
      // ignore: avoid_print
      print(
        'Fuzz: $gameCount oyun — eleme ile $byElimination, '
        'tur limiti ile $byTurnLimit. Toplam $totalActions aksiyon, '
        'en uzun $longest adım, ort. ${totalActions ~/ gameCount}.',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
