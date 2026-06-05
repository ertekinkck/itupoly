/// UI/bot → engine yönündeki niyet bildirimleri.
///
/// Kayıt = seed + aksiyon dizisi. Bu yüzden her aksiyon JSON serileştirilebilir;
/// `submit()` ile yeniden oynatınca (replay) birebir aynı state üretilir.
sealed class PlayerAction {
  const PlayerAction();

  Map<String, dynamic> toJson();

  static PlayerAction fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'roll' => const RollDice(),
      'buy' => const BuyProperty(),
      'decline' => const DeclineBuy(),
      'build' => BuildHouse(json['tile'] as int),
      'sell' => SellHouse(json['tile'] as int),
      'mortgage' => MortgageTile(json['tile'] as int),
      'unmortgage' => UnmortgageTile(json['tile'] as int),
      'payFine' => const PayDisiplinFine(),
      'useAf' => const UseAfKarti(),
      'bankrupt' => const DeclareBankruptcy(),
      'endTurn' => const EndTurn(),
      _ => throw ArgumentError('Bilinmeyen aksiyon türü: $type'),
    };
  }
}

/// Zar at (normal tur başı veya Disiplin Kurulu'nda çift denemesi).
final class RollDice extends PlayerAction {
  const RollDice();
  @override
  Map<String, dynamic> toJson() => {'type': 'roll'};
}

/// Üzerinde bulunulan boş arsayı satın al.
final class BuyProperty extends PlayerAction {
  const BuyProperty();
  @override
  Map<String, dynamic> toJson() => {'type': 'buy'};
}

/// Satın almayı reddet (arsa bankada kalır; açık artırma yok).
final class DeclineBuy extends PlayerAction {
  const DeclineBuy();
  @override
  Map<String, dynamic> toJson() => {'type': 'decline'};
}

/// Bir arsaya derslik/amfi inşa et.
final class BuildHouse extends PlayerAction {
  const BuildHouse(this.tileIndex);
  final int tileIndex;
  @override
  Map<String, dynamic> toJson() => {'type': 'build', 'tile': tileIndex};
}

/// Bir arsadaki dersliği/amfiyi sat (yarı fiyat geri alınır).
final class SellHouse extends PlayerAction {
  const SellHouse(this.tileIndex);
  final int tileIndex;
  @override
  Map<String, dynamic> toJson() => {'type': 'sell', 'tile': tileIndex};
}

/// Bir kareyi ipotek et (fiyatın yarısı kadar nakit).
final class MortgageTile extends PlayerAction {
  const MortgageTile(this.tileIndex);
  final int tileIndex;
  @override
  Map<String, dynamic> toJson() => {'type': 'mortgage', 'tile': tileIndex};
}

/// İpotekli kareyi geri al (%10 faizle).
final class UnmortgageTile extends PlayerAction {
  const UnmortgageTile(this.tileIndex);
  final int tileIndex;
  @override
  Map<String, dynamic> toJson() => {'type': 'unmortgage', 'tile': tileIndex};
}

/// Disiplin Kurulu çıkış cezasını öde (50₭).
final class PayDisiplinFine extends PlayerAction {
  const PayDisiplinFine();
  @override
  Map<String, dynamic> toJson() => {'type': 'payFine'};
}

/// Af Kartı kullanarak Disiplin Kurulu'ndan çık.
final class UseAfKarti extends PlayerAction {
  const UseAfKarti();
  @override
  Map<String, dynamic> toJson() => {'type': 'useAf'};
}

/// İflas ilan et (borç ödenemiyor); varlıklar alacaklıya/bankaya devredilir.
final class DeclareBankruptcy extends PlayerAction {
  const DeclareBankruptcy();
  @override
  Map<String, dynamic> toJson() => {'type': 'bankrupt'};
}

/// Turu bitir; sıra sonraki oyuncuya geçer.
final class EndTurn extends PlayerAction {
  const EndTurn();
  @override
  Map<String, dynamic> toJson() => {'type': 'endTurn'};
}
