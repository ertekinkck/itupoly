import 'package:itupoly_engine/src/models/enums.dart';
import 'package:meta/meta.dart';

/// Bir oyuncunun değişmez (immutable) durumu.
///
/// Sahip olunan kareler burada tutulmaz; tek doğruluk kaynağı
/// `GameState.tileStates` içindeki `ownerId`'dir.
@immutable
final class Player {
  const Player({
    required this.id,
    required this.name,
    required this.pawn,
    this.cash = 1500,
    this.position = 0,
    this.inJail = false,
    this.jailTurns = 0,
    this.bankrupt = false,
    this.isBot = false,
    this.afKarti = const [],
  });

  /// 0'dan başlayan oturma sırası kimliği.
  final int id;
  final String name;
  final PawnType pawn;

  /// Nakit bakiye (kredi, ₭).
  final int cash;

  /// Bulunduğu kare (0–39).
  final int position;

  /// Disiplin Kurulu'nda (hapiste) mi?
  final bool inJail;

  /// Hapisten çıkmak için başarısız çift-zar denemesi sayısı (0–3).
  final int jailTurns;

  /// İflas etti mi? (oyundan elendi)
  final bool bankrupt;

  /// Bot tarafından mı kontrol ediliyor?
  final bool isBot;

  /// Elde tutulan Af Kartları (her desteden en fazla bir tane).
  final List<DeckType> afKarti;

  bool get hasAfKarti => afKarti.isNotEmpty;

  Player copyWith({
    String? name,
    PawnType? pawn,
    int? cash,
    int? position,
    bool? inJail,
    int? jailTurns,
    bool? bankrupt,
    bool? isBot,
    List<DeckType>? afKarti,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      pawn: pawn ?? this.pawn,
      cash: cash ?? this.cash,
      position: position ?? this.position,
      inJail: inJail ?? this.inJail,
      jailTurns: jailTurns ?? this.jailTurns,
      bankrupt: bankrupt ?? this.bankrupt,
      isBot: isBot ?? this.isBot,
      afKarti: afKarti ?? this.afKarti,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pawn': pawn.name,
    'cash': cash,
    'position': position,
    'inJail': inJail,
    'jailTurns': jailTurns,
    'bankrupt': bankrupt,
    'isBot': isBot,
    'afKarti': afKarti.map((d) => d.name).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as int,
    name: json['name'] as String,
    pawn: PawnType.values.byName(json['pawn'] as String),
    cash: json['cash'] as int,
    position: json['position'] as int,
    inJail: json['inJail'] as bool,
    jailTurns: json['jailTurns'] as int,
    bankrupt: json['bankrupt'] as bool,
    isBot: json['isBot'] as bool,
    afKarti: (json['afKarti'] as List<dynamic>)
        .map((d) => DeckType.values.byName(d as String))
        .toList(),
  );

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.id == id &&
      other.name == name &&
      other.pawn == pawn &&
      other.cash == cash &&
      other.position == position &&
      other.inJail == inJail &&
      other.jailTurns == jailTurns &&
      other.bankrupt == bankrupt &&
      other.isBot == isBot &&
      _listEq(other.afKarti, afKarti);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    pawn,
    cash,
    position,
    inJail,
    jailTurns,
    bankrupt,
    isBot,
    Object.hashAll(afKarti),
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
