/// İTÜpoly oyun motoru — saf Dart, Flutter bağımsız.
///
/// Event-sourced, deterministik çekirdek: PlayerAction → Engine doğrular →
/// GameEvent listesi → reducer → yeni GameState.
library;

export 'src/actions/actions.dart';
export 'src/bot/bot.dart';
export 'src/data/board_tr.dart';
export 'src/data/cards_tr.dart';
export 'src/engine.dart';
export 'src/events/events.dart';
export 'src/events/reducer.dart';
export 'src/models/models.dart';
export 'src/rules/rules.dart';
export 'src/sim/auto_play.dart';
