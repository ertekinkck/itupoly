import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/tile_group.dart';

/// Tahtadaki bir kare. Statik tanım: sahiplik/inşaat/ipotek gibi dinamik durum
/// burada DEĞİL, [GameState.tileStates] içinde tutulur.
sealed class Tile {
  const Tile({required this.index, required this.name});

  /// 0–39 arası kare konumu.
  final int index;

  /// Kare adı (örn. "Rektörlük").
  final String name;

  /// Serileştirme/golden için tür etiketi.
  String get kindTag;

  /// Satın alınabilir mi? (arsa / ring / şirket)
  bool get isOwnable => false;

  /// Satın alma fiyatı; satılamayan karelerde 0.
  int get purchasePrice => 0;

  Map<String, dynamic> toJson() => {
    'kind': kindTag,
    'index': index,
    'name': name,
  };
}

/// Renk grubuna ait arsa (fakülte/yurt/bina). Üstüne derslik/amfi inşa edilir.
final class PropertyTile extends Tile {
  const PropertyTile({
    required super.index,
    required super.name,
    required this.group,
    required this.price,
    required this.rents,
    required this.houseCost,
  });

  /// Renk grubu (tekel hesabı için).
  final TileGroup group;

  /// Temel satın alma fiyatı.
  final int price;

  /// Kira merdiveni: `[temel, 1 derslik, 2, 3, 4, amfi]` (6 eleman).
  final List<int> rents;

  /// Bir derslik inşaat maliyeti (gruba göre 50/100/150/200).
  final int houseCost;

  @override
  String get kindTag => 'property';

  @override
  bool get isOwnable => true;

  @override
  int get purchasePrice => price;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'group': group.name,
    'price': price,
    'rents': rents,
    'houseCost': houseCost,
  };
}

/// Ring durağı (klasik istasyon). Kira sahip olunan durak sayısına bağlı.
final class RingTile extends Tile {
  const RingTile({
    required super.index,
    required super.name,
    this.price = 200,
  });

  final int price;

  @override
  String get kindTag => 'ring';

  @override
  bool get isOwnable => true;

  @override
  int get purchasePrice => price;

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'price': price};
}

/// Şirket / altyapı (BİDB İnterneti, Yemekhane). Kira zar çarpanına bağlı.
final class UtilityTile extends Tile {
  const UtilityTile({
    required super.index,
    required super.name,
    this.price = 150,
  });

  final int price;

  @override
  String get kindTag => 'utility';

  @override
  bool get isOwnable => true;

  @override
  int get purchasePrice => price;

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'price': price};
}

/// Vergi karesi (Dönem Harcı / Mezuniyet Harcı). Sabit tutar bankaya ödenir.
final class TaxTile extends Tile {
  const TaxTile({
    required super.index,
    required super.name,
    required this.amount,
  });

  final int amount;

  @override
  String get kindTag => 'tax';

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'amount': amount};
}

/// Kart karesi (Şans / Kampüs Kartı). Gelince ilgili desteden kart çekilir.
final class CardTile extends Tile {
  const CardTile({
    required super.index,
    required super.name,
    required this.deck,
  });

  final DeckType deck;

  @override
  String get kindTag => 'card';

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deck': deck.name};
}

/// Köşe karesi (BAŞLA, Disiplin Kurulu, Çim Amfi, Disipline Sevk).
final class CornerTile extends Tile {
  const CornerTile({
    required super.index,
    required super.name,
    required this.type,
  });

  final CornerType type;

  @override
  String get kindTag => 'corner';

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'corner': type.name};
}
