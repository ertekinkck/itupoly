import 'dart:math';

import 'package:itupoly_engine/itupoly_engine.dart';

/// Zar atışlarını betikle kontrol eden Random. [faces] = istenen zar yüzleri
/// (1–6); `nextInt(6)` çağrısı yüz-1 döner, böylece engine tam o yüzü görür.
class ScriptedRandom implements Random {
  ScriptedRandom(this.faces);

  final List<int> faces;
  int _i = 0;

  @override
  int nextInt(int max) {
    final face = faces[_i++ % faces.length];
    return (face - 1) % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

/// Betikli zarlarla 2–6 oyunculu bir oyun kurar. Desteler sabit seed (42) ile
/// karıştırılır; zar dizisi ayrı [ScriptedRandom] ile sürülür.
({GameEngine engine, GameState state}) newScriptedGame(
  List<int> diceFaces, {
  int playerCount = 2,
}) {
  final setup = GameEngine(Random(42));
  final state = setup.newGame([
    for (var i = 0; i < playerCount; i++)
      PlayerSetup(name: 'P$i', pawn: PawnType.values[i], isBot: true),
  ]);
  return (engine: GameEngine(ScriptedRandom(diceFaces)), state: state);
}

/// Belirli kare durumlarıyla elle kurulan state (kural birim testleri için).
GameState gameWith({
  required List<Player> players,
  Map<int, TileState> tiles = const {},
  int currentPlayerIndex = 0,
  TurnPhase phase = TurnPhase.awaitRoll,
  Debt? pendingDebt,
}) {
  final tileStates = List<TileState>.generate(
    boardSize,
    (i) => tiles[i] ?? const TileState(),
  );
  return GameState(
    players: players,
    tileStates: tileStates,
    sansDeck: List<int>.generate(sansCards.length, (i) => i),
    kampusDeck: List<int>.generate(kampusCards.length, (i) => i),
    currentPlayerIndex: currentPlayerIndex,
    phase: phase,
    pendingDebt: pendingDebt,
  );
}

/// Kısa oyuncu kurucu.
Player player(
  int id, {
  int cash = 1500,
  int position = 0,
  bool inJail = false,
  int jailTurns = 0,
  bool bankrupt = false,
  List<DeckType> afKarti = const [],
}) => Player(
  id: id,
  name: 'P$id',
  pawn: PawnType.values[id % PawnType.values.length],
  cash: cash,
  position: position,
  inJail: inJail,
  jailTurns: jailTurns,
  bankrupt: bankrupt,
  isBot: true,
  afKarti: afKarti,
);

/// Para korunumu invariantı: sum(cash) + bankBalanceDelta sabit kalmalı.
int conservationTotal(GameState s) => s.totalPlayerCash + s.bankBalanceDelta;
