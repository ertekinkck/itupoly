import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/models/tile_group.dart';

/// Tahtanın tek doğruluk kaynağı. Kare isimleri/temaları İTÜ evreni; kira ve
/// fiyat değerleri klasik tablodan (denenmiş ekonomi dengesi) alınmıştır.
///
/// Kira merdiveni `[temel, 1 derslik, 2, 3, 4, amfi]` (6 eleman).
const List<Tile> boardTr = [
  // 0
  CornerTile(index: 0, name: 'Kayıt Yenileme', type: CornerType.basla),
  // 1 — Kahverengi
  PropertyTile(
    index: 1,
    name: 'Tuzla Yerleşkesi',
    group: TileGroup.kahverengi,
    price: 60,
    rents: [2, 10, 30, 90, 160, 250],
    houseCost: 50,
  ),
  // 2
  CardTile(index: 2, name: 'Kampüs Kartı', deck: DeckType.kampusKarti),
  // 3 — Kahverengi
  PropertyTile(
    index: 3,
    name: 'Denizcilik Fakültesi',
    group: TileGroup.kahverengi,
    price: 60,
    rents: [4, 20, 60, 180, 320, 450],
    houseCost: 50,
  ),
  // 4
  TaxTile(index: 4, name: 'Dönem Harcı', amount: 200),
  // 5 — Ring
  RingTile(index: 5, name: 'Ring: Ana Kapı'),
  // 6 — Açık Mavi
  PropertyTile(
    index: 6,
    name: 'Maçka Yerleşkesi',
    group: TileGroup.acikMavi,
    price: 100,
    rents: [6, 30, 90, 270, 400, 550],
    houseCost: 50,
  ),
  // 7
  CardTile(index: 7, name: 'Şans', deck: DeckType.sans),
  // 8 — Açık Mavi
  PropertyTile(
    index: 8,
    name: 'İşletme Fakültesi',
    group: TileGroup.acikMavi,
    price: 100,
    rents: [6, 30, 90, 270, 400, 550],
    houseCost: 50,
  ),
  // 9 — Açık Mavi
  PropertyTile(
    index: 9,
    name: 'Yabancı Diller YO',
    group: TileGroup.acikMavi,
    price: 120,
    rents: [8, 40, 100, 300, 450, 600],
    houseCost: 50,
  ),
  // 10
  CornerTile(
    index: 10,
    name: 'Disiplin Kurulu',
    type: CornerType.disiplinZiyaret,
  ),
  // 11 — Pembe
  PropertyTile(
    index: 11,
    name: 'Gümüşsuyu Yerleşkesi',
    group: TileGroup.pembe,
    price: 140,
    rents: [10, 50, 150, 450, 625, 750],
    houseCost: 100,
  ),
  // 12 — Altyapı
  UtilityTile(index: 12, name: 'BİDB İnterneti'),
  // 13 — Pembe
  PropertyTile(
    index: 13,
    name: 'Makine Fakültesi',
    group: TileGroup.pembe,
    price: 140,
    rents: [10, 50, 150, 450, 625, 750],
    houseCost: 100,
  ),
  // 14 — Pembe
  PropertyTile(
    index: 14,
    name: 'Taşkışla — Mimarlık',
    group: TileGroup.pembe,
    price: 160,
    rents: [12, 60, 180, 500, 700, 900],
    houseCost: 100,
  ),
  // 15 — Ring
  RingTile(index: 15, name: 'Ring: MED'),
  // 16 — Turuncu
  PropertyTile(
    index: 16,
    name: 'KYK Yurtları',
    group: TileGroup.turuncu,
    price: 180,
    rents: [14, 70, 200, 550, 750, 950],
    houseCost: 100,
  ),
  // 17
  CardTile(index: 17, name: 'Kampüs Kartı', deck: DeckType.kampusKarti),
  // 18 — Turuncu
  PropertyTile(
    index: 18,
    name: 'Vadi Yurtları',
    group: TileGroup.turuncu,
    price: 180,
    rents: [14, 70, 200, 550, 750, 950],
    houseCost: 100,
  ),
  // 19 — Turuncu
  PropertyTile(
    index: 19,
    name: '75. Yıl ÖSM',
    group: TileGroup.turuncu,
    price: 200,
    rents: [16, 80, 220, 600, 800, 1000],
    houseCost: 100,
  ),
  // 20
  CornerTile(index: 20, name: 'Çim Amfi', type: CornerType.cimAmfi),
  // 21 — Kırmızı
  PropertyTile(
    index: 21,
    name: 'İnşaat Fakültesi',
    group: TileGroup.kirmizi,
    price: 220,
    rents: [18, 90, 250, 700, 875, 1050],
    houseCost: 150,
  ),
  // 22
  CardTile(index: 22, name: 'Şans', deck: DeckType.sans),
  // 23 — Kırmızı
  PropertyTile(
    index: 23,
    name: 'Fen-Edebiyat Fakültesi',
    group: TileGroup.kirmizi,
    price: 220,
    rents: [18, 90, 250, 700, 875, 1050],
    houseCost: 150,
  ),
  // 24 — Kırmızı
  PropertyTile(
    index: 24,
    name: 'Kimya-Metalurji Fakültesi',
    group: TileGroup.kirmizi,
    price: 240,
    rents: [20, 100, 300, 750, 925, 1100],
    houseCost: 150,
  ),
  // 25 — Ring
  RingTile(index: 25, name: 'Ring: KSB'),
  // 26 — Sarı
  PropertyTile(
    index: 26,
    name: 'Uçak ve Uzay Fakültesi',
    group: TileGroup.sari,
    price: 260,
    rents: [22, 110, 330, 800, 975, 1150],
    houseCost: 150,
  ),
  // 27 — Sarı
  PropertyTile(
    index: 27,
    name: 'Elektrik-Elektronik Fak.',
    group: TileGroup.sari,
    price: 260,
    rents: [22, 110, 330, 800, 975, 1150],
    houseCost: 150,
  ),
  // 28 — Altyapı
  UtilityTile(index: 28, name: 'Yemekhane'),
  // 29 — Sarı
  PropertyTile(
    index: 29,
    name: 'Bilgisayar ve Bilişim Fak.',
    group: TileGroup.sari,
    price: 280,
    rents: [24, 120, 360, 850, 1025, 1200],
    houseCost: 150,
  ),
  // 30
  CornerTile(
    index: 30,
    name: 'Disipline Sevk!',
    type: CornerType.disiplineSevk,
  ),
  // 31 — Yeşil
  PropertyTile(
    index: 31,
    name: 'Mustafa İnan Kütüphanesi',
    group: TileGroup.yesil,
    price: 300,
    rents: [26, 130, 390, 900, 1100, 1275],
    houseCost: 200,
  ),
  // 32 — Yeşil
  PropertyTile(
    index: 32,
    name: 'SDKM',
    group: TileGroup.yesil,
    price: 300,
    rents: [26, 130, 390, 900, 1100, 1275],
    houseCost: 200,
  ),
  // 33
  CardTile(index: 33, name: 'Kampüs Kartı', deck: DeckType.kampusKarti),
  // 34 — Yeşil
  PropertyTile(
    index: 34,
    name: 'İTÜ Stadyumu',
    group: TileGroup.yesil,
    price: 320,
    rents: [28, 150, 450, 1000, 1200, 1400],
    houseCost: 200,
  ),
  // 35 — Ring
  RingTile(index: 35, name: 'Ring: Metro İstasyonu'),
  // 36
  CardTile(index: 36, name: 'Şans', deck: DeckType.sans),
  // 37 — Lacivert
  PropertyTile(
    index: 37,
    name: 'Arı Teknokent',
    group: TileGroup.lacivert,
    price: 350,
    rents: [35, 175, 500, 1100, 1300, 1500],
    houseCost: 200,
  ),
  // 38
  TaxTile(index: 38, name: 'Mezuniyet Harcı', amount: 100),
  // 39 — Lacivert
  PropertyTile(
    index: 39,
    name: 'Rektörlük',
    group: TileGroup.lacivert,
    price: 400,
    rents: [50, 200, 600, 1400, 1700, 2000],
    houseCost: 200,
  ),
];

/// Tahtadaki toplam kare sayısı.
const int boardSize = 40;

/// BAŞLA (Kayıt Yenileme) kare indeksi.
const int startIndex = 0;

/// Disiplin Kurulu (hapis) kare indeksi.
const int disiplinIndex = 10;

/// Disipline Sevk! (hapse gönderen köşe) indeksi.
const int disiplinSevkIndex = 30;

/// BAŞLA'dan geçiş bursu.
const int salaryAmount = 200;

/// Başlangıç nakdi.
const int startingCash = 1500;

/// Disiplin Kurulu çıkış cezası.
const int disiplinFine = 50;

/// Bir grubun tüm kare indeksleri.
List<int> tilesInGroup(TileGroup group) {
  final result = <int>[];
  for (final tile in boardTr) {
    if (tile is PropertyTile && tile.group == group) result.add(tile.index);
    if (tile is RingTile && group == TileGroup.istasyon) result.add(tile.index);
    if (tile is UtilityTile && group == TileGroup.altyapi) {
      result.add(tile.index);
    }
  }
  return result;
}

/// Tüm ring (istasyon) indeksleri.
List<int> get ringIndices => tilesInGroup(TileGroup.istasyon);

/// Tüm şirket (altyapı) indeksleri.
List<int> get utilityIndices => tilesInGroup(TileGroup.altyapi);
