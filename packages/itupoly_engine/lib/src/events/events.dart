import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/data/cards_tr.dart';
import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/player.dart';

/// engine → state/UI yönünde gerçekleşen olaylar.
///
/// Event'ler animasyon kuyruğunu, olay günlüğünü ve online senkronu besler.
/// Kalıcı state değişiklikleri [reduce] tarafından uygulanır.
sealed class GameEvent {
  const GameEvent();

  String get tag;

  Map<String, dynamic> toJson();

  /// Olay günlüğü için okunabilir Türkçe satır.
  String describe(List<Player> players);

  static String _name(List<Player> players, int id) {
    final p = players.where((p) => p.id == id);
    return p.isEmpty ? 'Oyuncu $id' : p.first.name;
  }

  static GameEvent fromJson(Map<String, dynamic> j) {
    final t = j['tag'] as String;
    return switch (t) {
      'diceRolled' => DiceRolled(j['d1'] as int, j['d2'] as int),
      'tokenMoved' => TokenMoved(
        playerId: j['playerId'] as int,
        from: j['from'] as int,
        to: j['to'] as int,
        passedStart: j['passedStart'] as bool,
        steps: j['steps'] as int,
      ),
      'salaryPaid' => SalaryPaid(j['playerId'] as int, j['amount'] as int),
      'propertyBought' => PropertyBought(
        playerId: j['playerId'] as int,
        tileIndex: j['tileIndex'] as int,
        price: j['price'] as int,
      ),
      'buyDeclined' => BuyDeclined(j['playerId'] as int, j['tileIndex'] as int),
      'rentPaid' => RentPaid(
        fromId: j['fromId'] as int,
        toId: j['toId'] as int,
        tileIndex: j['tileIndex'] as int,
        amount: j['amount'] as int,
      ),
      'taxPaid' => TaxPaid(j['playerId'] as int, j['amount'] as int),
      'moneyChanged' => MoneyChanged(
        playerId: j['playerId'] as int,
        delta: j['delta'] as int,
        reason: j['reason'] as String,
      ),
      'moneyTransferred' => MoneyTransferred(
        fromId: j['fromId'] as int,
        toId: j['toId'] as int,
        amount: j['amount'] as int,
        reason: j['reason'] as String,
      ),
      'cardDrawn' => CardDrawn(
        playerId: j['playerId'] as int,
        deck: DeckType.values.byName(j['deck'] as String),
        cardId: j['cardId'] as int,
        retained: j['retained'] as bool,
      ),
      'houseBuilt' => HouseBuilt(
        tileIndex: j['tileIndex'] as int,
        houses: j['houses'] as int,
        cost: j['cost'] as int,
      ),
      'houseSold' => HouseSold(
        tileIndex: j['tileIndex'] as int,
        houses: j['houses'] as int,
        refund: j['refund'] as int,
      ),
      'mortgaged' => Mortgaged(
        tileIndex: j['tileIndex'] as int,
        amount: j['amount'] as int,
      ),
      'unmortgaged' => Unmortgaged(
        tileIndex: j['tileIndex'] as int,
        amount: j['amount'] as int,
      ),
      'sentToDisiplin' => SentToDisiplin(j['playerId'] as int),
      'leftDisiplin' => LeftDisiplin(
        j['playerId'] as int,
        LeaveReason.values.byName(j['reason'] as String),
      ),
      'jailRollFailed' => JailRollFailed(
        j['playerId'] as int,
        j['attempt'] as int,
      ),
      'afKartiUsed' => AfKartiUsed(
        playerId: j['playerId'] as int,
        deck: DeckType.values.byName(j['deck'] as String),
        cardId: j['cardId'] as int,
      ),
      'debtIncurred' => DebtIncurred(
        playerId: j['playerId'] as int,
        amount: j['amount'] as int,
        toPlayerId: j['toPlayerId'] as int?,
      ),
      'debtSettled' => DebtSettled(j['playerId'] as int),
      'playerBankrupted' => PlayerBankrupted(
        playerId: j['playerId'] as int,
        toPlayerId: j['toPlayerId'] as int?,
      ),
      'turnEnded' => TurnEnded(j['playerId'] as int),
      'turnStarted' => TurnStarted(j['playerId'] as int),
      'gameEnded' => GameEnded(j['winnerId'] as int),
      _ => throw ArgumentError('Bilinmeyen event: $t'),
    };
  }
}

/// Disiplin Kurulu'ndan çıkış nedeni.
enum LeaveReason { fine, card, doubles, served }

final class DiceRolled extends GameEvent {
  const DiceRolled(this.d1, this.d2);
  final int d1;
  final int d2;
  bool get isDouble => d1 == d2;
  int get total => d1 + d2;
  @override
  String get tag => 'diceRolled';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'd1': d1, 'd2': d2};
  @override
  String describe(List<Player> players) =>
      'Zar atıldı: $d1 + $d2 = $total${isDouble ? ' (çift!)' : ''}';
}

final class TokenMoved extends GameEvent {
  const TokenMoved({
    required this.playerId,
    required this.from,
    required this.to,
    required this.passedStart,
    required this.steps,
  });
  final int playerId;
  final int from;
  final int to;
  final bool passedStart;
  final int steps;
  @override
  String get tag => 'tokenMoved';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'from': from,
    'to': to,
    'passedStart': passedStart,
    'steps': steps,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} → ${boardTr[to].name}';
}

final class SalaryPaid extends GameEvent {
  const SalaryPaid(this.playerId, this.amount);
  final int playerId;
  final int amount;
  @override
  String get tag => 'salaryPaid';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'amount': amount,
  };
  @override
  String describe(List<Player> players) =>
      "${GameEvent._name(players, playerId)} BAŞLA'dan geçti, +$amount₺ burs";
}

final class PropertyBought extends GameEvent {
  const PropertyBought({
    required this.playerId,
    required this.tileIndex,
    required this.price,
  });
  final int playerId;
  final int tileIndex;
  final int price;
  @override
  String get tag => 'propertyBought';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'tileIndex': tileIndex,
    'price': price,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} '
      '${boardTr[tileIndex].name} aldı (-$price₺)';
}

final class BuyDeclined extends GameEvent {
  const BuyDeclined(this.playerId, this.tileIndex);
  final int playerId;
  final int tileIndex;
  @override
  String get tag => 'buyDeclined';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'tileIndex': tileIndex,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} '
      '${boardTr[tileIndex].name} almadı';
}

final class RentPaid extends GameEvent {
  const RentPaid({
    required this.fromId,
    required this.toId,
    required this.tileIndex,
    required this.amount,
  });
  final int fromId;
  final int toId;
  final int tileIndex;
  final int amount;
  @override
  String get tag => 'rentPaid';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'fromId': fromId,
    'toId': toId,
    'tileIndex': tileIndex,
    'amount': amount,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, fromId)} → '
      '${GameEvent._name(players, toId)}: $amount₺ kira '
      '(${boardTr[tileIndex].name})';
}

final class TaxPaid extends GameEvent {
  const TaxPaid(this.playerId, this.amount);
  final int playerId;
  final int amount;
  @override
  String get tag => 'taxPaid';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'amount': amount,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} vergi ödedi (-$amount₺)';
}

final class MoneyChanged extends GameEvent {
  const MoneyChanged({
    required this.playerId,
    required this.delta,
    required this.reason,
  });
  final int playerId;

  /// Pozitif: bankadan alındı; negatif: bankaya ödendi.
  final int delta;
  final String reason;
  @override
  String get tag => 'moneyChanged';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'delta': delta,
    'reason': reason,
  };
  @override
  String describe(List<Player> players) {
    final sign = delta >= 0 ? '+' : '';
    return '${GameEvent._name(players, playerId)}: $sign$delta₺ ($reason)';
  }
}

final class MoneyTransferred extends GameEvent {
  const MoneyTransferred({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.reason,
  });
  final int fromId;
  final int toId;
  final int amount;
  final String reason;
  @override
  String get tag => 'moneyTransferred';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'fromId': fromId,
    'toId': toId,
    'amount': amount,
    'reason': reason,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, fromId)} → '
      '${GameEvent._name(players, toId)}: $amount₺ ($reason)';
}

final class CardDrawn extends GameEvent {
  const CardDrawn({
    required this.playerId,
    required this.deck,
    required this.cardId,
    required this.retained,
  });
  final int playerId;
  final DeckType deck;
  final int cardId;

  /// Af Kartı olup oyuncuda kaldı mı?
  final bool retained;
  @override
  String get tag => 'cardDrawn';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'deck': deck.name,
    'cardId': cardId,
    'retained': retained,
  };
  @override
  String describe(List<Player> players) {
    final deckName = deck == DeckType.sans ? 'Şans' : 'Kampüs Kartı';
    return '${GameEvent._name(players, playerId)} $deckName: '
        '"${cardOf(deck, cardId).text}"';
  }
}

final class HouseBuilt extends GameEvent {
  const HouseBuilt({
    required this.tileIndex,
    required this.houses,
    required this.cost,
  });
  final int tileIndex;
  final int houses;
  final int cost;
  @override
  String get tag => 'houseBuilt';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'tileIndex': tileIndex,
    'houses': houses,
    'cost': cost,
  };
  @override
  String describe(List<Player> players) {
    final what = houses == 5 ? 'amfi' : '$houses. derslik';
    return '${boardTr[tileIndex].name}: $what inşa edildi (-$cost₺)';
  }
}

final class HouseSold extends GameEvent {
  const HouseSold({
    required this.tileIndex,
    required this.houses,
    required this.refund,
  });
  final int tileIndex;
  final int houses;
  final int refund;
  @override
  String get tag => 'houseSold';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'tileIndex': tileIndex,
    'houses': houses,
    'refund': refund,
  };
  @override
  String describe(List<Player> players) =>
      '${boardTr[tileIndex].name}: inşaat satıldı (+$refund₺)';
}

final class Mortgaged extends GameEvent {
  const Mortgaged({required this.tileIndex, required this.amount});
  final int tileIndex;
  final int amount;
  @override
  String get tag => 'mortgaged';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'tileIndex': tileIndex,
    'amount': amount,
  };
  @override
  String describe(List<Player> players) =>
      '${boardTr[tileIndex].name} ipotek edildi (+$amount₺)';
}

final class Unmortgaged extends GameEvent {
  const Unmortgaged({required this.tileIndex, required this.amount});
  final int tileIndex;
  final int amount;
  @override
  String get tag => 'unmortgaged';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'tileIndex': tileIndex,
    'amount': amount,
  };
  @override
  String describe(List<Player> players) =>
      '${boardTr[tileIndex].name} ipoteği kaldırıldı (-$amount₺)';
}

final class SentToDisiplin extends GameEvent {
  const SentToDisiplin(this.playerId);
  final int playerId;
  @override
  String get tag => 'sentToDisiplin';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'playerId': playerId};
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} Disiplin Kurulu\'na sevk edildi!';
}

final class LeftDisiplin extends GameEvent {
  const LeftDisiplin(this.playerId, this.reason);
  final int playerId;
  final LeaveReason reason;
  @override
  String get tag => 'leftDisiplin';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'reason': reason.name,
  };
  @override
  String describe(List<Player> players) {
    final how = switch (reason) {
      LeaveReason.fine => 'ceza ödeyerek',
      LeaveReason.card => 'Af Kartı ile',
      LeaveReason.doubles => 'çift atarak',
      LeaveReason.served => 'süresi dolunca',
    };
    return '${GameEvent._name(players, playerId)} Disiplin Kurulu\'ndan '
        'çıktı ($how)';
  }
}

final class JailRollFailed extends GameEvent {
  const JailRollFailed(this.playerId, this.attempt);
  final int playerId;
  final int attempt;
  @override
  String get tag => 'jailRollFailed';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'attempt': attempt,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} çift atamadı '
      '($attempt. deneme)';
}

final class AfKartiUsed extends GameEvent {
  const AfKartiUsed({
    required this.playerId,
    required this.deck,
    required this.cardId,
  });
  final int playerId;
  final DeckType deck;
  final int cardId;
  @override
  String get tag => 'afKartiUsed';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'deck': deck.name,
    'cardId': cardId,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} Af Kartı kullandı';
}

final class DebtIncurred extends GameEvent {
  const DebtIncurred({
    required this.playerId,
    required this.amount,
    required this.toPlayerId,
  });
  final int playerId;
  final int amount;
  final int? toPlayerId;
  @override
  String get tag => 'debtIncurred';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'amount': amount,
    'toPlayerId': toPlayerId,
  };
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} $amount₺ ödeyemiyor — '
      'tasfiye gerekli';
}

final class DebtSettled extends GameEvent {
  const DebtSettled(this.playerId);
  final int playerId;
  @override
  String get tag => 'debtSettled';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'playerId': playerId};
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} borcunu kapattı';
}

final class PlayerBankrupted extends GameEvent {
  const PlayerBankrupted({required this.playerId, required this.toPlayerId});
  final int playerId;
  final int? toPlayerId;
  @override
  String get tag => 'playerBankrupted';
  @override
  Map<String, dynamic> toJson() => {
    'tag': tag,
    'playerId': playerId,
    'toPlayerId': toPlayerId,
  };
  @override
  String describe(List<Player> players) {
    final to = toPlayerId == null
        ? 'banka'
        : GameEvent._name(players, toPlayerId!);
    return '${GameEvent._name(players, playerId)} iflas etti '
        '(varlıklar → $to)';
  }
}

final class TurnEnded extends GameEvent {
  const TurnEnded(this.playerId);
  final int playerId;
  @override
  String get tag => 'turnEnded';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'playerId': playerId};
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} turu bitirdi';
}

final class TurnStarted extends GameEvent {
  const TurnStarted(this.playerId);
  final int playerId;
  @override
  String get tag => 'turnStarted';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'playerId': playerId};
  @override
  String describe(List<Player> players) =>
      '${GameEvent._name(players, playerId)} sırası';
}

final class GameEnded extends GameEvent {
  const GameEnded(this.winnerId);
  final int winnerId;
  @override
  String get tag => 'gameEnded';
  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'winnerId': winnerId};
  @override
  String describe(List<Player> players) =>
      '🎓 ${GameEvent._name(players, winnerId)} kazandı!';
}
