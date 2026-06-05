import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/data/cards_tr.dart';
import 'package:itupoly_engine/src/events/events.dart';
import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/player.dart';

/// Saf reducer: bir event'i state'e uygular ve yeni state döner.
///
/// Faz / currentPlayerIndex / doublesCount / pendingDebt gibi KONTROL AKIŞI
/// alanları `submit()` tarafından yönetilir; burada yalnızca KALICI veri
/// (nakit, konum, sahiplik, inşaat, ipotek, desteler, banka akışı) güncellenir.
GameState reduce(GameState state, GameEvent event) {
  switch (event) {
    case DiceRolled(:final d1, :final d2):
      return state.copyWith(lastDie1: d1, lastDie2: d2);

    case TokenMoved(:final playerId, :final to):
      return _updatePlayer(state, playerId, (p) => p.copyWith(position: to));

    case SalaryPaid(:final playerId, :final amount):
      return _addCash(state, playerId, amount, bankDelta: -amount);

    case PropertyBought(:final playerId, :final tileIndex, :final price):
      final withOwner = state.withTileState(
        tileIndex,
        state.tileStateAt(tileIndex).copyWith(ownerId: playerId),
      );
      return _addCash(withOwner, playerId, -price, bankDelta: price);

    case BuyDeclined():
      return state;

    case RentPaid(:final fromId, :final toId, :final amount):
      return _transfer(state, fromId, toId, amount);

    case TaxPaid(:final playerId, :final amount):
      return _addCash(state, playerId, -amount, bankDelta: amount);

    case MoneyChanged(:final playerId, :final delta):
      return _addCash(state, playerId, delta, bankDelta: -delta);

    case MoneyTransferred(:final fromId, :final toId, :final amount):
      return _transfer(state, fromId, toId, amount);

    case CardDrawn(
      :final playerId,
      :final deck,
      :final cardId,
      :final retained,
    ):
      return _drawCard(state, playerId, deck, cardId, retained: retained);

    case HouseBuilt(:final tileIndex, :final houses, :final cost):
      final owner = state.tileStateAt(tileIndex).ownerId!;
      final withHouse = state.withTileState(
        tileIndex,
        state.tileStateAt(tileIndex).copyWith(houses: houses),
      );
      return _addCash(withHouse, owner, -cost, bankDelta: cost);

    case HouseSold(:final tileIndex, :final houses, :final refund):
      final owner = state.tileStateAt(tileIndex).ownerId!;
      final withHouse = state.withTileState(
        tileIndex,
        state.tileStateAt(tileIndex).copyWith(houses: houses),
      );
      return _addCash(withHouse, owner, refund, bankDelta: -refund);

    case Mortgaged(:final tileIndex, :final amount):
      final owner = state.tileStateAt(tileIndex).ownerId!;
      final withMort = state.withTileState(
        tileIndex,
        state.tileStateAt(tileIndex).copyWith(mortgaged: true),
      );
      return _addCash(withMort, owner, amount, bankDelta: -amount);

    case Unmortgaged(:final tileIndex, :final amount):
      final owner = state.tileStateAt(tileIndex).ownerId!;
      final withMort = state.withTileState(
        tileIndex,
        state.tileStateAt(tileIndex).copyWith(mortgaged: false),
      );
      return _addCash(withMort, owner, -amount, bankDelta: amount);

    case SentToDisiplin(:final playerId):
      return _updatePlayer(
        state,
        playerId,
        (p) => p.copyWith(
          position: disiplinIndex,
          inJail: true,
          jailTurns: 0,
        ),
      );

    case LeftDisiplin(:final playerId):
      return _updatePlayer(
        state,
        playerId,
        (p) => p.copyWith(inJail: false, jailTurns: 0),
      );

    case JailRollFailed(:final playerId, :final attempt):
      return _updatePlayer(
        state,
        playerId,
        (p) => p.copyWith(jailTurns: attempt),
      );

    case AfKartiUsed(:final playerId, :final deck, :final cardId):
      return _useAfKarti(state, playerId, deck, cardId);

    case DebtIncurred():
      return state;

    case DebtSettled():
      return state;

    case PlayerBankrupted(:final playerId, :final toPlayerId):
      return _bankrupt(state, playerId, toPlayerId);

    case TurnEnded():
      return state.copyWith(turnCount: state.turnCount + 1);

    case TurnStarted():
      return state;

    case GameEnded():
      return state;
  }
}

/// Bir event listesini sırayla katlar.
GameState reduceAll(GameState state, Iterable<GameEvent> events) {
  var s = state;
  for (final e in events) {
    s = reduce(s, e);
  }
  return s;
}

GameState _updatePlayer(
  GameState state,
  int playerId,
  Player Function(Player) update,
) {
  final next = List<Player>.of(state.players);
  final idx = next.indexWhere((p) => p.id == playerId);
  next[idx] = update(next[idx]);
  return state.copyWith(players: next);
}

GameState _addCash(
  GameState state,
  int playerId,
  int delta, {
  int bankDelta = 0,
}) {
  final next = List<Player>.of(state.players);
  final idx = next.indexWhere((p) => p.id == playerId);
  next[idx] = next[idx].copyWith(cash: next[idx].cash + delta);
  return state.copyWith(
    players: next,
    bankBalanceDelta: state.bankBalanceDelta + bankDelta,
  );
}

GameState _transfer(GameState state, int fromId, int toId, int amount) {
  final next = List<Player>.of(state.players);
  final fromIdx = next.indexWhere((p) => p.id == fromId);
  final toIdx = next.indexWhere((p) => p.id == toId);
  next[fromIdx] = next[fromIdx].copyWith(cash: next[fromIdx].cash - amount);
  next[toIdx] = next[toIdx].copyWith(cash: next[toIdx].cash + amount);
  return state.copyWith(players: next);
}

GameState _drawCard(
  GameState state,
  int playerId,
  DeckType deck,
  int cardId, {
  required bool retained,
}) {
  final isSans = deck == DeckType.sans;
  final source = isSans ? state.sansDeck : state.kampusDeck;
  final newDeck = List<int>.of(source)..remove(cardId);
  if (!retained) newDeck.add(cardId);

  var s = isSans
      ? state.copyWith(sansDeck: newDeck)
      : state.copyWith(kampusDeck: newDeck);

  if (retained) {
    s = _updatePlayer(
      s,
      playerId,
      (p) => p.copyWith(afKarti: [...p.afKarti, deck]),
    );
  }
  return s;
}

GameState _useAfKarti(
  GameState state,
  int playerId,
  DeckType deck,
  int cardId,
) {
  final isSans = deck == DeckType.sans;
  final src = isSans ? state.sansDeck : state.kampusDeck;
  final newDeck = List<int>.of(src)..add(cardId);

  var s = isSans
      ? state.copyWith(sansDeck: newDeck)
      : state.copyWith(kampusDeck: newDeck);

  s = _updatePlayer(s, playerId, (p) {
    final cards = List.of(p.afKarti)..remove(deck);
    return p.copyWith(afKarti: cards);
  });
  return s;
}

GameState _bankrupt(GameState state, int playerId, int? toPlayerId) {
  final p = state.playerById(playerId);
  final props = state.propertiesOf(playerId);

  final tiles = List<TileState>.of(state.tileStates);
  final players = List<Player>.of(state.players);
  var bankDelta = state.bankBalanceDelta;
  final sans = List<int>.of(state.sansDeck);
  final kampus = List<int>.of(state.kampusDeck);

  final cIdx = toPlayerId == null
      ? -1
      : players.indexWhere((x) => x.id == toPlayerId);
  if (toPlayerId != null && cIdx != -1) {
    players[cIdx] = players[cIdx].copyWith(cash: players[cIdx].cash + p.cash);
    for (final i in props) {
      // İpotek durumu transfer sırasında sıfırlanır (Monopoly kuralı).
      tiles[i] = tiles[i].copyWith(ownerId: toPlayerId, mortgaged: false);
    }
  } else {
    bankDelta += p.cash;
    for (final i in props) {
      tiles[i] = const TileState();
    }
  }

  // Af kartlarını destelere geri koy.
  for (final d in p.afKarti) {
    final id = afKartiCardId(d);
    if (d == DeckType.sans) {
      sans.add(id);
    } else {
      kampus.add(id);
    }
  }

  final pIdx = players.indexWhere((x) => x.id == playerId);
  players[pIdx] = players[pIdx].copyWith(
    cash: 0,
    bankrupt: true,
    afKarti: const [],
  );

  return state.copyWith(
    players: players,
    tileStates: tiles,
    bankBalanceDelta: bankDelta,
    sansDeck: sans,
    kampusDeck: kampus,
  );
}
