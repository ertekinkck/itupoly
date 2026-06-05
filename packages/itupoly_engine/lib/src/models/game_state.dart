import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/player.dart';
import 'package:meta/meta.dart';

/// Ödenmesi gereken ama nakitle karşılanamayan borç. mustLiquidate fazını
/// tetikler. [toPlayerId] null ise alacaklı bankadır.
@immutable
final class Debt {
  const Debt({
    required this.amount,
    required this.reason,
    this.toPlayerId,
    this.tileIndex,
  });

  final int amount;
  final DebtReason reason;
  final int? toPlayerId;

  /// Kira borcunda, tasfiye sonrası RentPaid'i yeniden yaymak için kare.
  final int? tileIndex;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'reason': reason.name,
    'toPlayerId': toPlayerId,
    'tileIndex': tileIndex,
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    amount: json['amount'] as int,
    reason: DebtReason.values.byName(json['reason'] as String),
    toPlayerId: json['toPlayerId'] as int?,
    tileIndex: json['tileIndex'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is Debt &&
      other.amount == amount &&
      other.reason == reason &&
      other.toPlayerId == toPlayerId &&
      other.tileIndex == tileIndex;

  @override
  int get hashCode => Object.hash(amount, reason, toPlayerId, tileIndex);
}

/// Borcun kaynağı; tasfiye sonrası ödeme hangi event'le kapanacağını belirler.
enum DebtReason { rent, tax, card }

/// Bir karenin dinamik durumu (sahip, inşaat, ipotek).
@immutable
final class TileState {
  const TileState({
    this.ownerId,
    this.houses = 0,
    this.mortgaged = false,
  });

  /// Sahibin oyuncu id'si; null ise banka (boşta).
  final int? ownerId;

  /// İnşaat sayısı: 0–4 derslik, 5 = amfi (otel).
  final int houses;

  /// İpotekli mi?
  final bool mortgaged;

  bool get isOwned => ownerId != null;
  bool get hasHotel => houses == 5;

  TileState copyWith({
    int? ownerId,
    bool clearOwner = false,
    int? houses,
    bool? mortgaged,
  }) {
    return TileState(
      ownerId: clearOwner ? null : (ownerId ?? this.ownerId),
      houses: houses ?? this.houses,
      mortgaged: mortgaged ?? this.mortgaged,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerId': ownerId,
    'houses': houses,
    'mortgaged': mortgaged,
  };

  factory TileState.fromJson(Map<String, dynamic> json) => TileState(
    ownerId: json['ownerId'] as int?,
    houses: json['houses'] as int,
    mortgaged: json['mortgaged'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      other is TileState &&
      other.ownerId == ownerId &&
      other.houses == houses &&
      other.mortgaged == mortgaged;

  @override
  int get hashCode => Object.hash(ownerId, houses, mortgaged);
}

/// Oyunun tüm değişmez durumu. Tahtanın statik tanımı ([boardTr]) buraya
/// dahil değildir; yalnızca dinamik veri tutulur.
final class GameState {
  const GameState({
    required this.players,
    required this.tileStates,
    required this.sansDeck,
    required this.kampusDeck,
    this.currentPlayerIndex = 0,
    this.phase = TurnPhase.awaitRoll,
    this.doublesCount = 0,
    this.pendingDebt,
    this.lastDie1 = 0,
    this.lastDie2 = 0,
    this.winnerId,
    this.bankBalanceDelta = 0,
    this.turnCount = 0,
  });

  final List<Player> players;

  /// 40 karenin dinamik durumu (indeks = kare konumu).
  final List<TileState> tileStates;

  /// Şans destesi sırası (kart id kuyruğu); öndeki çekilir, arkaya gider.
  final List<int> sansDeck;

  /// Kampüs Kartı destesi sırası.
  final List<int> kampusDeck;

  final int currentPlayerIndex;
  final TurnPhase phase;

  /// Bu turda üst üste atılan çift sayısı (3 → Disipline sevk).
  final int doublesCount;

  /// Açık borç (varsa); mustLiquidate fazında işlenir.
  final Debt? pendingDebt;

  final int lastDie1;
  final int lastDie2;

  /// Oyun bittiyse kazananın id'si.
  final int? winnerId;

  /// Banka tarafı net para akışı (korunum invariantı için).
  ///
  /// `sum(player.cash) + bankBalanceDelta == başlangıç toplam nakit` her zaman.
  final int bankBalanceDelta;

  /// Tamamlanan tur sayısı (istatistik + sonsuz döngü emniyeti).
  final int turnCount;

  int get lastDiceTotal => lastDie1 + lastDie2;

  Player get currentPlayer => players[currentPlayerIndex];

  TileState tileStateAt(int index) => tileStates[index];

  Iterable<Player> get activePlayers => players.where((p) => !p.bankrupt);

  bool get isGameOver => phase == TurnPhase.gameOver;

  int get totalPlayerCash => players.fold(0, (sum, p) => sum + p.cash);

  Player playerById(int id) => players.firstWhere((p) => p.id == id);

  /// Bir oyuncunun sahip olduğu kare indeksleri.
  List<int> propertiesOf(int playerId) {
    final result = <int>[];
    for (var i = 0; i < tileStates.length; i++) {
      if (tileStates[i].ownerId == playerId) result.add(i);
    }
    return result;
  }

  GameState copyWith({
    List<Player>? players,
    List<TileState>? tileStates,
    List<int>? sansDeck,
    List<int>? kampusDeck,
    int? currentPlayerIndex,
    TurnPhase? phase,
    int? doublesCount,
    Debt? pendingDebt,
    bool clearPendingDebt = false,
    int? lastDie1,
    int? lastDie2,
    int? winnerId,
    int? bankBalanceDelta,
    int? turnCount,
  }) {
    return GameState(
      players: players ?? this.players,
      tileStates: tileStates ?? this.tileStates,
      sansDeck: sansDeck ?? this.sansDeck,
      kampusDeck: kampusDeck ?? this.kampusDeck,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      doublesCount: doublesCount ?? this.doublesCount,
      pendingDebt: clearPendingDebt ? null : (pendingDebt ?? this.pendingDebt),
      lastDie1: lastDie1 ?? this.lastDie1,
      lastDie2: lastDie2 ?? this.lastDie2,
      winnerId: winnerId ?? this.winnerId,
      bankBalanceDelta: bankBalanceDelta ?? this.bankBalanceDelta,
      turnCount: turnCount ?? this.turnCount,
    );
  }

  /// İlgili oyuncuyu yenisiyle değiştiren yardımcı (immutable update).
  GameState withPlayer(Player updated) {
    final next = List<Player>.of(players);
    final idx = next.indexWhere((p) => p.id == updated.id);
    next[idx] = updated;
    return copyWith(players: next);
  }

  /// İlgili kare durumunu güncelleyen yardımcı.
  GameState withTileState(int index, TileState updated) {
    final next = List<TileState>.of(tileStates);
    next[index] = updated;
    return copyWith(tileStates: next);
  }

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'tileStates': tileStates.map((t) => t.toJson()).toList(),
    'sansDeck': sansDeck,
    'kampusDeck': kampusDeck,
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'doublesCount': doublesCount,
    'pendingDebt': pendingDebt?.toJson(),
    'lastDie1': lastDie1,
    'lastDie2': lastDie2,
    'winnerId': winnerId,
    'bankBalanceDelta': bankBalanceDelta,
    'turnCount': turnCount,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    players: (json['players'] as List<dynamic>)
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList(),
    tileStates: (json['tileStates'] as List<dynamic>)
        .map((t) => TileState.fromJson(t as Map<String, dynamic>))
        .toList(),
    sansDeck: (json['sansDeck'] as List<dynamic>).cast<int>(),
    kampusDeck: (json['kampusDeck'] as List<dynamic>).cast<int>(),
    currentPlayerIndex: json['currentPlayerIndex'] as int,
    phase: TurnPhase.values.byName(json['phase'] as String),
    doublesCount: json['doublesCount'] as int,
    pendingDebt: json['pendingDebt'] == null
        ? null
        : Debt.fromJson(json['pendingDebt'] as Map<String, dynamic>),
    lastDie1: json['lastDie1'] as int,
    lastDie2: json['lastDie2'] as int,
    winnerId: json['winnerId'] as int?,
    bankBalanceDelta: json['bankBalanceDelta'] as int,
    turnCount: json['turnCount'] as int,
  );
}
