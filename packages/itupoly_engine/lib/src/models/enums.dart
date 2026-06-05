/// Bir turun içinde bulunabileceği fazlar.
///
/// Faz, kontrol akışı durumudur: `submit()` tarafından yönetilir. Determinizm
/// aksiyon-replay ile sağlandığından (seed + aksiyon dizisi → aynı state) faz
/// event ile değil doğrudan state üzerinde güncellenir.
enum TurnPhase {
  /// Sıradaki oyuncu zar atmayı bekliyor.
  awaitRoll,

  /// Boş bir arsaya gelindi; oyuncu satın al / pas kararı veriyor.
  awaitBuyDecision,

  /// Oyuncu Disiplin Kurulu'nda; ceza öde / Af Kartı / çift zar seçimi.
  inDisiplin,

  /// Ödenecek borç nakitten fazla; oyuncu ipotek/satışla nakit yaratmalı
  /// ya da iflas etmeli.
  mustLiquidate,

  /// Tur işlemleri bitti; oyuncu turu bitirebilir (veya inşaat/ipotek yapar).
  endTurn,

  /// Oyun bitti; kazanan belli.
  gameOver,
}

/// İki kart destesi.
enum DeckType {
  /// "Şans" destesi.
  sans,

  /// "Kampüs Kartı" destesi.
  kampusKarti,
}

/// Köşe karelerinin türü.
enum CornerType {
  /// BAŞLA — Kayıt Yenileme (0).
  basla,

  /// Disiplin Kurulu — ziyaretçi (10).
  disiplinZiyaret,

  /// Çim Amfi — serbest park (20).
  cimAmfi,

  /// Disipline Sevk! — hapse gir (30).
  disiplineSevk,
}

/// Oyuncu piyon türleri (özgün ikon seti).
enum PawnType {
  ari,
  pergel,
  baret,
  kahve,
  hesapMakinesi,
  devreKarti,
}
