import 'dart:io';
import 'dart:math';

import 'package:itupoly_engine/itupoly_engine.dart';

/// Terminalde bot vs bot oyun izleme — UI'sız doğrulama.
///
/// Kullanım: `dart run itupoly_engine:itupoly_sim [seed] [oyuncu] [--quiet]`
void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final quiet = args.contains('--quiet');
  final seed = positional.isNotEmpty ? int.tryParse(positional[0]) ?? 42 : 42;
  final count = positional.length > 1 ? int.tryParse(positional[1]) ?? 4 : 4;

  const names = ['Arı', 'Pergel', 'Baret', 'Kahve', 'Hesap', 'Devre'];
  final engine = GameEngine(Random(seed));
  final init = engine.newGame([
    for (var i = 0; i < count; i++)
      PlayerSetup(name: names[i], pawn: PawnType.values[i], isBot: true),
  ]);

  stdout.writeln('🎲 İTÜpoly simülasyon — seed=$seed, $count bot\n');

  final result = autoPlay(
    engine,
    init,
    onStep: quiet
        ? null
        : (s, action, events) {
            for (final e in events) {
              if (e is TokenMoved) continue; // hareket gürültüsünü atla
              if (e is TurnStarted) {
                stdout.writeln(
                  '\n— ${e.describe(s.players)} '
                  '(tur ${s.turnCount}) —',
                );
              } else {
                stdout.writeln('  ${e.describe(s.players)}');
              }
            }
          },
  );

  stdout.writeln('\n${'=' * 40}');
  stdout.writeln(
    result.completed
        ? '✅ Oyun bitti — ${result.actionCount} aksiyon, '
              '${result.finalState.turnCount} tur'
        : '⏱️ Aksiyon limitine ulaşıldı',
  );

  final standings = [...result.finalState.players]
    ..sort(
      (a, b) => netWorth(
        result.finalState,
        b.id,
      ).compareTo(netWorth(result.finalState, a.id)),
    );
  stdout.writeln('\nSıralama (net değer):');
  for (final p in standings) {
    final mark = p.id == result.finalState.winnerId ? '🎓' : '  ';
    final status = p.bankrupt ? 'İFLAS' : '${p.cash}₭ nakit';
    stdout.writeln(
      '$mark ${p.name.padRight(8)} '
      'net ${netWorth(result.finalState, p.id)}₭  ($status)',
    );
  }
}
