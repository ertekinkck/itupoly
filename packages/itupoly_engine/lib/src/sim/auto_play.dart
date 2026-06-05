import 'package:itupoly_engine/src/actions/actions.dart';
import 'package:itupoly_engine/src/bot/bot.dart';
import 'package:itupoly_engine/src/engine.dart';
import 'package:itupoly_engine/src/events/events.dart';
import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/game_state.dart';

/// Tam bot oyununun sonucu.
class AutoPlayResult {
  const AutoPlayResult({
    required this.finalState,
    required this.actionCount,
    required this.completed,
    required this.actions,
  });

  final GameState finalState;
  final int actionCount;

  /// Tur limitine takılmadan gameOver'a ulaşıldı mı?
  final bool completed;

  /// Uygulanan aksiyon dizisi (replay/determinizm için).
  final List<PlayerAction> actions;
}

/// Bir oyunu bot kararlarıyla baştan sona oynatır.
///
/// [onStep] her adımda (yeni state, aksiyon, üretilen event'ler) ile çağrılır;
/// fuzz invariant kontrolü ve CLI çıktısı için kullanılır.
AutoPlayResult autoPlay(
  GameEngine engine,
  GameState initial, {
  Bot bot = const Bot(),
  int maxActions = 50000,
  void Function(GameState state, PlayerAction action, List<GameEvent> events)?
  onStep,
}) {
  var s = initial;
  final actions = <PlayerAction>[];
  var count = 0;
  while (s.phase != TurnPhase.gameOver && count < maxActions) {
    final action = bot.decide(engine, s);
    final (next, events) = engine.submit(s, action);
    actions.add(action);
    s = next;
    count++;
    onStep?.call(s, action, events);
  }
  return AutoPlayResult(
    finalState: s,
    actionCount: count,
    completed: s.phase == TurnPhase.gameOver,
    actions: actions,
  );
}

/// Bir aksiyon dizisini taze bir motor + başlangıç state üzerinde yeniden
/// oynatır (kayıt yükleme / online senkron için temel).
GameState replay(
  GameEngine engine,
  GameState initial,
  List<PlayerAction> actions,
) {
  var s = initial;
  for (final a in actions) {
    final (next, _) = engine.submit(s, a);
    s = next;
  }
  return s;
}
