import 'dart:math';

import 'package:itupoly_engine/src/actions/actions.dart';
import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/data/cards_tr.dart';
import 'package:itupoly_engine/src/events/events.dart';
import 'package:itupoly_engine/src/events/reducer.dart';
import 'package:itupoly_engine/src/models/card.dart';
import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/player.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/rules/bankruptcy.dart';
import 'package:itupoly_engine/src/rules/build.dart';
import 'package:itupoly_engine/src/rules/mortgage.dart';
import 'package:itupoly_engine/src/rules/rent.dart';

/// Geçersiz aksiyon denendiğinde fırlatılır. UI/bot yalnızca [legalActions]
/// içinden seçtiğinde bu hata oluşmaz.
class RuleViolation implements Exception {
  RuleViolation(this.message);
  final String message;
  @override
  String toString() => 'RuleViolation: $message';
}

/// Oyun kurulumu için bir oyuncu tanımı.
class PlayerSetup {
  const PlayerSetup({
    required this.name,
    required this.pawn,
    this.isBot = false,
  });
  final String name;
  final PawnType pawn;
  final bool isBot;
}

/// `submit()` sonucu: yeni state + UI/online için olay listesi.
typedef SubmitResult = (GameState state, List<GameEvent> events);

/// Tek bir submit çağrısı boyunca state + event biriktiren işlem bağlamı.
class _Txn {
  _Txn(this.state);
  GameState state;
  final List<GameEvent> events = [];

  void emit(GameEvent e) {
    events.add(e);
    state = reduce(state, e);
  }

  void setPhase(TurnPhase phase) => state = state.copyWith(phase: phase);
}

/// İTÜpoly oyun motoru.
///
/// Determinizm: rng yalnızca [newGame] (deste karıştırma) ve [submit]
/// (zar atışı) içinde kullanılır. Aynı seed + aynı aksiyon dizisi → aynı state.
class GameEngine {
  GameEngine(this.rng, {this.maxTurns = 600});

  final Random rng;

  /// Sonsuz oyun emniyeti: tur sayısı bu sınıra ulaşınca oyun en yüksek net
  /// değere sahip oyuncuyla biter. (MVP'de derslik kıtlığı yok; bu sınır,
  /// nadir de olsa stalemate'i kapatır.) null → sınırsız.
  final int? maxTurns;

  static const _buildPhases = {
    TurnPhase.awaitRoll,
    TurnPhase.endTurn,
    TurnPhase.inDisiplin,
  };
  static const _mortgagePhases = {
    TurnPhase.awaitRoll,
    TurnPhase.endTurn,
    TurnPhase.inDisiplin,
    TurnPhase.mustLiquidate,
  };
  static const _unmortgagePhases = {
    TurnPhase.awaitRoll,
    TurnPhase.endTurn,
    TurnPhase.inDisiplin,
  };

  /// Yeni oyun başlat (desteler seed ile karıştırılır).
  GameState newGame(List<PlayerSetup> setups) {
    if (setups.length < 2 || setups.length > 6) {
      throw ArgumentError(
        'Oyuncu sayısı 2–6 olmalı (verilen: ${setups.length})',
      );
    }
    final players = [
      for (var i = 0; i < setups.length; i++)
        Player(
          id: i,
          name: setups[i].name,
          pawn: setups[i].pawn,
          isBot: setups[i].isBot,
          cash: startingCash,
        ),
    ];
    final tileStates = List<TileState>.generate(
      boardSize,
      (_) => const TileState(),
    );
    final sansDeck = List<int>.generate(sansCards.length, (i) => i)
      ..shuffle(rng);
    final kampusDeck = List<int>.generate(kampusCards.length, (i) => i)
      ..shuffle(rng);
    return GameState(
      players: players,
      tileStates: tileStates,
      sansDeck: sansDeck,
      kampusDeck: kampusDeck,
    );
  }

  /// Bir aksiyonu doğrular, event üretir ve yeni state'i hesaplar.
  SubmitResult submit(GameState state, PlayerAction action) {
    if (state.phase == TurnPhase.gameOver) {
      throw RuleViolation('Oyun bitti');
    }
    final t = _Txn(state);
    switch (action) {
      case RollDice():
        _roll(t);
      case BuyProperty():
        _buy(t);
      case DeclineBuy():
        _decline(t);
      case BuildHouse(:final tileIndex):
        _build(t, tileIndex);
      case SellHouse(:final tileIndex):
        _sell(t, tileIndex);
      case MortgageTile(:final tileIndex):
        _mortgage(t, tileIndex);
      case UnmortgageTile(:final tileIndex):
        _unmortgage(t, tileIndex);
      case PayDisiplinFine():
        _payFine(t);
      case UseAfKarti():
        _useAf(t);
      case DeclareBankruptcy():
        _bankruptcy(t);
      case EndTurn():
        _endTurn(t);
    }
    return (t.state, t.events);
  }

  /// Mevcut oyuncu için şu an yasal olan aksiyonlar (UI + bot + fuzz için).
  List<PlayerAction> legalActions(GameState s) {
    if (s.phase == TurnPhase.gameOver) return const [];
    final p = s.currentPlayer;
    final actions = <PlayerAction>[];
    switch (s.phase) {
      case TurnPhase.awaitRoll:
        actions.add(const RollDice());
        _addManagement(s, actions);
      case TurnPhase.inDisiplin:
        actions.add(const RollDice());
        if (p.cash >= disiplinFine) actions.add(const PayDisiplinFine());
        if (p.hasAfKarti) actions.add(const UseAfKarti());
        _addManagement(s, actions);
      case TurnPhase.awaitBuyDecision:
        if (p.cash >= boardTr[p.position].purchasePrice) {
          actions.add(const BuyProperty());
        }
        actions.add(const DeclineBuy());
      case TurnPhase.mustLiquidate:
        _addManagement(s, actions, onlyLiquidation: true);
        actions.add(const DeclareBankruptcy());
      case TurnPhase.endTurn:
        actions.add(const EndTurn());
        _addManagement(s, actions);
      case TurnPhase.gameOver:
        break;
    }
    return actions;
  }

  void _addManagement(
    GameState s,
    List<PlayerAction> actions, {
    bool onlyLiquidation = false,
  }) {
    final p = s.currentPlayer;
    for (final i in s.propertiesOf(p.id)) {
      if (!onlyLiquidation && canBuildHouse(s, i, p.id)) {
        actions.add(BuildHouse(i));
      }
      if (canSellHouse(s, i, p.id)) actions.add(SellHouse(i));
      if (canMortgage(s, i, p.id)) actions.add(MortgageTile(i));
      if (!onlyLiquidation && canUnmortgage(s, i, p.id)) {
        actions.add(UnmortgageTile(i));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Zar / hareket / kare çözümü
  // ---------------------------------------------------------------------------

  void _roll(_Txn t) {
    final phase = t.state.phase;
    if (phase != TurnPhase.awaitRoll && phase != TurnPhase.inDisiplin) {
      throw RuleViolation('Şu an zar atılamaz');
    }
    final d1 = rng.nextInt(6) + 1;
    final d2 = rng.nextInt(6) + 1;
    t.emit(DiceRolled(d1, d2));
    final isDouble = d1 == d2;
    final total = d1 + d2;
    final player = t.state.currentPlayer;

    if (phase == TurnPhase.inDisiplin) {
      _rollInJail(t, isDouble: isDouble, total: total, player: player);
      return;
    }

    final newDoubles = isDouble ? t.state.doublesCount + 1 : 0;
    t.state = t.state.copyWith(doublesCount: newDoubles);
    if (isDouble && newDoubles == 3) {
      // Üç kez üst üste çift → Disipline sevk.
      t.emit(SentToDisiplin(player.id));
      t.state = t.state.copyWith(doublesCount: 0);
      t.setPhase(TurnPhase.endTurn);
      return;
    }
    _moveAndResolve(t, total);
  }

  void _rollInJail(
    _Txn t, {
    required bool isDouble,
    required int total,
    required Player player,
  }) {
    if (isDouble) {
      t.emit(LeftDisiplin(player.id, LeaveReason.doubles));
      _moveAndResolve(t, total);
      return;
    }
    final attempt = player.jailTurns + 1;
    t.emit(JailRollFailed(player.id, attempt));
    if (attempt >= 3) {
      // Üçüncü başarısız deneme: ceza zorunlu, sonra hareket.
      t.emit(LeftDisiplin(player.id, LeaveReason.served));
      if (t.state.currentPlayer.cash >= disiplinFine) {
        t.emit(
          MoneyChanged(
            playerId: player.id,
            delta: -disiplinFine,
            reason: 'Disiplin cezası',
          ),
        );
        _moveAndResolve(t, total);
      } else {
        _incurDebt(t, disiplinFine, reason: DebtReason.card);
      }
    } else {
      t.setPhase(TurnPhase.endTurn);
    }
  }

  void _moveAndResolve(_Txn t, int steps) {
    final player = t.state.currentPlayer;
    final from = player.position;
    final to = (from + steps) % boardSize;
    final passed = from + steps >= boardSize;
    t.emit(
      TokenMoved(
        playerId: player.id,
        from: from,
        to: to,
        passedStart: passed,
        steps: steps,
      ),
    );
    if (passed) t.emit(SalaryPaid(player.id, salaryAmount));
    _resolveTile(t, to, allowCardDraw: true);
  }

  void _resolveTile(_Txn t, int index, {required bool allowCardDraw}) {
    final tile = boardTr[index];
    final player = t.state.currentPlayer;
    switch (tile) {
      case CornerTile(:final type):
        switch (type) {
          case CornerType.basla:
          case CornerType.disiplinZiyaret:
          case CornerType.cimAmfi:
            _postResolution(t);
          case CornerType.disiplineSevk:
            t.emit(SentToDisiplin(player.id));
            t.state = t.state.copyWith(doublesCount: 0);
            t.setPhase(TurnPhase.endTurn);
        }
      case PropertyTile():
      case RingTile():
      case UtilityTile():
        _resolveOwnable(t, index);
      case TaxTile(:final amount):
        _payToBank(t, amount, reason: DebtReason.tax);
        if (t.state.pendingDebt == null) _postResolution(t);
      case CardTile(:final deck):
        if (!allowCardDraw) {
          _postResolution(t);
        } else {
          _drawAndApplyCard(t, deck);
        }
    }
  }

  void _resolveOwnable(_Txn t, int index) {
    final ts = t.state.tileStateAt(index);
    final player = t.state.currentPlayer;
    if (!ts.isOwned) {
      t.setPhase(TurnPhase.awaitBuyDecision);
      return;
    }
    if (ts.ownerId == player.id || ts.mortgaged) {
      _postResolution(t);
      return;
    }
    final rent = rentFor(t.state, index, diceTotal: t.state.lastDiceTotal);
    if (rent <= 0) {
      _postResolution(t);
      return;
    }
    if (player.cash >= rent) {
      t.emit(
        RentPaid(
          fromId: player.id,
          toId: ts.ownerId!,
          tileIndex: index,
          amount: rent,
        ),
      );
      _postResolution(t);
    } else {
      t.emit(
        DebtIncurred(
          playerId: player.id,
          amount: rent,
          toPlayerId: ts.ownerId,
        ),
      );
      t.state = t.state.copyWith(
        pendingDebt: Debt(
          amount: rent,
          reason: DebtReason.rent,
          toPlayerId: ts.ownerId,
          tileIndex: index,
        ),
      );
      t.setPhase(TurnPhase.mustLiquidate);
    }
  }

  /// Tur sonrası faz geçişi: çift atıldıysa tekrar zar, değilse tur sonu.
  void _postResolution(_Txn t) {
    final dc = t.state.doublesCount;
    t.setPhase(dc == 1 || dc == 2 ? TurnPhase.awaitRoll : TurnPhase.endTurn);
  }

  // ---------------------------------------------------------------------------
  // Kartlar
  // ---------------------------------------------------------------------------

  void _drawAndApplyCard(_Txn t, DeckType deck) {
    final deckList = deck == DeckType.sans
        ? t.state.sansDeck
        : t.state.kampusDeck;
    final cardId = deckList.first;
    final card = cardOf(deck, cardId);
    final player = t.state.currentPlayer;
    final retained = card.action is GetAfKarti;
    t.emit(
      CardDrawn(
        playerId: player.id,
        deck: deck,
        cardId: cardId,
        retained: retained,
      ),
    );
    _applyCardAction(t, card.action);
  }

  void _applyCardAction(_Txn t, CardAction action) {
    final player = t.state.currentPlayer;
    switch (action) {
      case GainMoney(:final amount):
        t.emit(
          MoneyChanged(playerId: player.id, delta: amount, reason: 'kart'),
        );
        _postResolution(t);
      case PayMoney(:final amount):
        _payToBank(t, amount, reason: DebtReason.card);
        if (t.state.pendingDebt == null) _postResolution(t);
      case MoveTo(:final tileIndex, :final collectIfPass):
        _moveToTile(t, tileIndex, collectIfPass: collectIfPass);
      case MoveBack(:final steps):
        _moveBack(t, steps);
      case GoToDisiplin():
        t.emit(SentToDisiplin(player.id));
        t.state = t.state.copyWith(doublesCount: 0);
        t.setPhase(TurnPhase.endTurn);
      case GetAfKarti():
        _postResolution(t);
      case CollectFromEach(:final amount):
        _collectFromEach(t, amount);
        _postResolution(t);
      case PayEach(:final amount):
        _payEach(t, amount);
        if (t.state.pendingDebt == null) _postResolution(t);
    }
  }

  void _moveToTile(_Txn t, int target, {required bool collectIfPass}) {
    final player = t.state.currentPlayer;
    final from = player.position;
    final wrapped = target < from;
    final steps = (target - from + boardSize) % boardSize;
    t.emit(
      TokenMoved(
        playerId: player.id,
        from: from,
        to: target,
        passedStart: wrapped,
        steps: steps,
      ),
    );
    if (wrapped && collectIfPass) t.emit(SalaryPaid(player.id, salaryAmount));
    _resolveTile(t, target, allowCardDraw: false);
  }

  void _moveBack(_Txn t, int steps) {
    final player = t.state.currentPlayer;
    final from = player.position;
    final to = (from - steps + boardSize) % boardSize;
    t.emit(
      TokenMoved(
        playerId: player.id,
        from: from,
        to: to,
        passedStart: false,
        steps: -steps,
      ),
    );
    _resolveTile(t, to, allowCardDraw: false);
  }

  void _collectFromEach(_Txn t, int amount) {
    final player = t.state.currentPlayer;
    final opponents = t.state.players
        .where((p) => !p.bankrupt && p.id != player.id)
        .toList();
    for (final opp in opponents) {
      final pay = opp.cash >= amount ? amount : opp.cash;
      if (pay > 0) {
        t.emit(
          MoneyTransferred(
            fromId: opp.id,
            toId: player.id,
            amount: pay,
            reason: 'kart',
          ),
        );
      }
    }
  }

  void _payEach(_Txn t, int amount) {
    final player = t.state.currentPlayer;
    final opponents = t.state.players
        .where((p) => !p.bankrupt && p.id != player.id)
        .toList();
    final total = amount * opponents.length;
    if (player.cash >= total) {
      for (final opp in opponents) {
        t.emit(
          MoneyTransferred(
            fromId: player.id,
            toId: opp.id,
            amount: amount,
            reason: 'kart',
          ),
        );
      }
    } else if (total > 0) {
      _incurDebt(t, total, reason: DebtReason.card);
    }
  }

  // ---------------------------------------------------------------------------
  // Para / borç
  // ---------------------------------------------------------------------------

  void _payToBank(_Txn t, int amount, {required DebtReason reason}) {
    final player = t.state.currentPlayer;
    if (player.cash >= amount) {
      if (reason == DebtReason.tax) {
        t.emit(TaxPaid(player.id, amount));
      } else {
        t.emit(
          MoneyChanged(playerId: player.id, delta: -amount, reason: 'kart'),
        );
      }
    } else {
      _incurDebt(t, amount, reason: reason);
    }
  }

  void _incurDebt(_Txn t, int amount, {required DebtReason reason}) {
    final player = t.state.currentPlayer;
    t.emit(
      DebtIncurred(playerId: player.id, amount: amount, toPlayerId: null),
    );
    t.state = t.state.copyWith(
      pendingDebt: Debt(amount: amount, reason: reason),
    );
    t.setPhase(TurnPhase.mustLiquidate);
  }

  void _trySettleDebt(_Txn t) {
    final debt = t.state.pendingDebt;
    if (debt == null) return;
    final player = t.state.currentPlayer;
    if (player.cash < debt.amount) return;
    switch (debt.reason) {
      case DebtReason.rent:
        t.emit(
          RentPaid(
            fromId: player.id,
            toId: debt.toPlayerId!,
            tileIndex: debt.tileIndex!,
            amount: debt.amount,
          ),
        );
      case DebtReason.tax:
        t.emit(TaxPaid(player.id, debt.amount));
      case DebtReason.card:
        if (debt.toPlayerId == null) {
          t.emit(
            MoneyChanged(
              playerId: player.id,
              delta: -debt.amount,
              reason: 'kart',
            ),
          );
        } else {
          t.emit(
            MoneyTransferred(
              fromId: player.id,
              toId: debt.toPlayerId!,
              amount: debt.amount,
              reason: 'kart',
            ),
          );
        }
    }
    t.emit(DebtSettled(player.id));
    t.state = t.state.copyWith(clearPendingDebt: true);
    _postResolution(t);
  }

  // ---------------------------------------------------------------------------
  // Kararlar / yönetim
  // ---------------------------------------------------------------------------

  void _buy(_Txn t) {
    if (t.state.phase != TurnPhase.awaitBuyDecision) {
      throw RuleViolation('Şu an satın alınamaz');
    }
    final player = t.state.currentPlayer;
    final index = player.position;
    final price = boardTr[index].purchasePrice;
    if (player.cash < price) throw RuleViolation('Yeterli nakit yok');
    t.emit(
      PropertyBought(playerId: player.id, tileIndex: index, price: price),
    );
    _postResolution(t);
  }

  void _decline(_Txn t) {
    if (t.state.phase != TurnPhase.awaitBuyDecision) {
      throw RuleViolation('Şu an karar verilemez');
    }
    final player = t.state.currentPlayer;
    t.emit(BuyDeclined(player.id, player.position));
    _postResolution(t);
  }

  void _build(_Txn t, int tileIndex) {
    _checkTileIndex(tileIndex);
    if (!_buildPhases.contains(t.state.phase)) {
      throw RuleViolation('Şu an inşaat yapılamaz');
    }
    final player = t.state.currentPlayer;
    if (!canBuildHouse(t.state, tileIndex, player.id)) {
      throw RuleViolation('İnşaat kuralı ihlali');
    }
    final tile = boardTr[tileIndex] as PropertyTile;
    final newHouses = t.state.tileStateAt(tileIndex).houses + 1;
    t.emit(
      HouseBuilt(tileIndex: tileIndex, houses: newHouses, cost: tile.houseCost),
    );
  }

  void _sell(_Txn t, int tileIndex) {
    _checkTileIndex(tileIndex);
    if (!_mortgagePhases.contains(t.state.phase)) {
      throw RuleViolation('Şu an satış yapılamaz');
    }
    final player = t.state.currentPlayer;
    if (!canSellHouse(t.state, tileIndex, player.id)) {
      throw RuleViolation('Satış kuralı ihlali');
    }
    final newHouses = t.state.tileStateAt(tileIndex).houses - 1;
    t.emit(
      HouseSold(
        tileIndex: tileIndex,
        houses: newHouses,
        refund: houseSellRefund(tileIndex),
      ),
    );
    if (t.state.phase == TurnPhase.mustLiquidate) _trySettleDebt(t);
  }

  void _mortgage(_Txn t, int tileIndex) {
    _checkTileIndex(tileIndex);
    if (!_mortgagePhases.contains(t.state.phase)) {
      throw RuleViolation('Şu an ipotek yapılamaz');
    }
    final player = t.state.currentPlayer;
    if (!canMortgage(t.state, tileIndex, player.id)) {
      throw RuleViolation('İpotek kuralı ihlali');
    }
    t.emit(Mortgaged(tileIndex: tileIndex, amount: mortgageValue(tileIndex)));
    if (t.state.phase == TurnPhase.mustLiquidate) _trySettleDebt(t);
  }

  void _unmortgage(_Txn t, int tileIndex) {
    _checkTileIndex(tileIndex);
    if (!_unmortgagePhases.contains(t.state.phase)) {
      throw RuleViolation('Şu an ipotek geri alınamaz');
    }
    final player = t.state.currentPlayer;
    if (!canUnmortgage(t.state, tileIndex, player.id)) {
      throw RuleViolation('İpotek geri alma kuralı ihlali');
    }
    t.emit(
      Unmortgaged(tileIndex: tileIndex, amount: unmortgageCost(tileIndex)),
    );
  }

  void _payFine(_Txn t) {
    if (t.state.phase != TurnPhase.inDisiplin) {
      throw RuleViolation('Ceza yalnızca Disiplin Kurulu\'nda ödenir');
    }
    final player = t.state.currentPlayer;
    if (player.cash < disiplinFine) {
      throw RuleViolation('Ceza için yeterli nakit yok');
    }
    t.emit(
      MoneyChanged(
        playerId: player.id,
        delta: -disiplinFine,
        reason: 'Disiplin cezası',
      ),
    );
    t.emit(LeftDisiplin(player.id, LeaveReason.fine));
    t.setPhase(TurnPhase.awaitRoll);
  }

  void _useAf(_Txn t) {
    if (t.state.phase != TurnPhase.inDisiplin) {
      throw RuleViolation('Af Kartı yalnızca Disiplin Kurulu\'nda kullanılır');
    }
    final player = t.state.currentPlayer;
    if (!player.hasAfKarti) throw RuleViolation('Af Kartı yok');
    final deck = player.afKarti.first;
    t.emit(
      AfKartiUsed(
        playerId: player.id,
        deck: deck,
        cardId: afKartiCardId(deck),
      ),
    );
    t.emit(LeftDisiplin(player.id, LeaveReason.card));
    t.setPhase(TurnPhase.awaitRoll);
  }

  void _bankruptcy(_Txn t) {
    if (t.state.phase != TurnPhase.mustLiquidate) {
      throw RuleViolation('İflas yalnızca tasfiye fazında ilan edilir');
    }
    final player = t.state.currentPlayer;
    final creditor = t.state.pendingDebt?.toPlayerId;
    // Önce tüm inşaatlar bankaya satılır (iade oyuncuya).
    for (final i in t.state.propertiesOf(player.id)) {
      var houses = t.state.tileStateAt(i).houses;
      while (houses > 0) {
        houses--;
        t.emit(
          HouseSold(tileIndex: i, houses: houses, refund: houseSellRefund(i)),
        );
      }
    }
    t.emit(PlayerBankrupted(playerId: player.id, toPlayerId: creditor));
    t.state = t.state.copyWith(clearPendingDebt: true, doublesCount: 0);
    _advanceTurn(t);
  }

  void _endTurn(_Txn t) {
    if (t.state.phase != TurnPhase.endTurn) {
      throw RuleViolation('Tur şu an bitirilemez');
    }
    t.emit(TurnEnded(t.state.currentPlayer.id));
    _advanceTurn(t);
  }

  void _advanceTurn(_Txn t) {
    final active = t.state.players.where((p) => !p.bankrupt).toList();
    if (active.length <= 1) {
      final winner = active.isNotEmpty
          ? active.first.id
          : t.state.currentPlayer.id;
      t.emit(GameEnded(winner));
      t.state = t.state.copyWith(winnerId: winner);
      t.setPhase(TurnPhase.gameOver);
      return;
    }
    if (maxTurns != null && t.state.turnCount >= maxTurns!) {
      final winner = _richestActiveId(t.state);
      t.emit(GameEnded(winner));
      t.state = t.state.copyWith(winnerId: winner);
      t.setPhase(TurnPhase.gameOver);
      return;
    }
    var idx = t.state.currentPlayerIndex;
    do {
      idx = (idx + 1) % t.state.players.length;
    } while (t.state.players[idx].bankrupt);
    final next = t.state.players[idx];
    t.emit(TurnStarted(next.id));
    t.state = t.state.copyWith(currentPlayerIndex: idx, doublesCount: 0);
    t.setPhase(next.inJail ? TurnPhase.inDisiplin : TurnPhase.awaitRoll);
  }

  /// Aktif oyuncular arasında en yüksek net değere sahip olan (eşitlikte en
  /// küçük id).
  int _richestActiveId(GameState s) {
    final active = s.players.where((p) => !p.bankrupt).toList();
    active.sort((a, b) {
      final cmp = netWorth(s, b.id).compareTo(netWorth(s, a.id));
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });
    return active.first.id;
  }

  void _checkTileIndex(int index) {
    if (index < 0 || index >= boardSize) {
      throw RuleViolation('Geçersiz kare: $index');
    }
  }
}
