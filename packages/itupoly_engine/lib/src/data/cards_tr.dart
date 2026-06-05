import 'package:itupoly_engine/src/models/card.dart';
import 'package:itupoly_engine/src/models/enums.dart';

/// "Şans" destesi — 16 özgün kart. Tüm metinler özgün yazılmıştır.
const List<GameCard> sansCards = [
  GameCard(
    id: 0,
    deck: DeckType.sans,
    text: 'Bütünlemeye kaldın — 100₺ öde.',
    action: PayMoney(100),
  ),
  GameCard(
    id: 1,
    deck: DeckType.sans,
    text: 'TÜBİTAK bursu onaylandı — 150₺ al.',
    action: GainMoney(150),
  ),
  GameCard(
    id: 2,
    deck: DeckType.sans,
    text: "Ring'i kaçırdın — Ring: MED durağına yürü.",
    action: MoveTo(15),
  ),
  GameCard(
    id: 3,
    deck: DeckType.sans,
    text: 'Devamsızlıktan disipline sevk edildin.',
    action: GoToDisiplin(),
  ),
  GameCard(
    id: 4,
    deck: DeckType.sans,
    text: 'Hocadan +1 — Af Kartı kazandın.',
    action: GetAfKarti(),
  ),
  GameCard(
    id: 5,
    deck: DeckType.sans,
    text: 'Yüksek onur belgesi — 100₺ al.',
    action: GainMoney(100),
  ),
  GameCard(
    id: 6,
    deck: DeckType.sans,
    text: 'Staj maaşın yattı — 50₺ al.',
    action: GainMoney(50),
  ),
  GameCard(
    id: 7,
    deck: DeckType.sans,
    text: "Kayıt Yenileme'ye (BAŞLA) ilerle.",
    action: MoveTo(0),
  ),
  GameCard(
    id: 8,
    deck: DeckType.sans,
    text: 'Laboratuvar cihazını bozdun — 75₺ öde.',
    action: PayMoney(75),
  ),
  GameCard(
    id: 9,
    deck: DeckType.sans,
    text: 'Bisikletin arızalandı — 3 kare geri git.',
    action: MoveBack(3),
  ),
  GameCard(
    id: 10,
    deck: DeckType.sans,
    text: 'Şenlikte herkese çay ısmarladın — her oyuncuya 25₺ öde.',
    action: PayEach(25),
  ),
  GameCard(
    id: 11,
    deck: DeckType.sans,
    text: "Yarışma birinciliği — Arı Teknokent'e ilerle.",
    action: MoveTo(37),
  ),
  GameCard(
    id: 12,
    deck: DeckType.sans,
    text: 'Vize haftası kantinde fazla harcadın — 60₺ öde.',
    action: PayMoney(60),
  ),
  GameCard(
    id: 13,
    deck: DeckType.sans,
    text: "Erasmus'a kabul edildin — Rektörlük'e ilerle.",
    action: MoveTo(39),
  ),
  GameCard(
    id: 14,
    deck: DeckType.sans,
    text: 'Proje yarışması büyük ödülü — 200₺ al.',
    action: GainMoney(200),
  ),
  GameCard(
    id: 15,
    deck: DeckType.sans,
    text: "Mezuniyet yaklaştı — Ring: Metro İstasyonu'na ilerle.",
    action: MoveTo(35),
  ),
];

/// "Kampüs Kartı" destesi — 16 özgün kart.
const List<GameCard> kampusCards = [
  GameCard(
    id: 0,
    deck: DeckType.kampusKarti,
    text: 'Dönem projesi ödülü — 100₺ al.',
    action: GainMoney(100),
  ),
  GameCard(
    id: 1,
    deck: DeckType.kampusKarti,
    text: 'Kütüphane gecikme cezası — 30₺ öde.',
    action: PayMoney(30),
  ),
  GameCard(
    id: 2,
    deck: DeckType.kampusKarti,
    text: 'Mezuniyet fotoğrafı — her oyuncudan 10₺ al.',
    action: CollectFromEach(10),
  ),
  GameCard(
    id: 3,
    deck: DeckType.kampusKarti,
    text: "Kayıt yenileme zamanı — BAŞLA'ya ilerle, 200₺ al.",
    action: MoveTo(0),
  ),
  GameCard(
    id: 4,
    deck: DeckType.kampusKarti,
    text: 'Danışman hocan kefil oldu — Af Kartı kazandın.',
    action: GetAfKarti(),
  ),
  GameCard(
    id: 5,
    deck: DeckType.kampusKarti,
    text: 'Yemekhane iadesi — 50₺ al.',
    action: GainMoney(50),
  ),
  GameCard(
    id: 6,
    deck: DeckType.kampusKarti,
    text: 'Laptopun arızalandı, tamir — 100₺ öde.',
    action: PayMoney(100),
  ),
  GameCard(
    id: 7,
    deck: DeckType.kampusKarti,
    text: 'Topluluk standında bağış topladın — 25₺ al.',
    action: GainMoney(25),
  ),
  GameCard(
    id: 8,
    deck: DeckType.kampusKarti,
    text: 'Fotokopi borcun birikti — 50₺ öde.',
    action: PayMoney(50),
  ),
  GameCard(
    id: 9,
    deck: DeckType.kampusKarti,
    text: 'Sınavda kopya iddiası — Disipline sevk edildin.',
    action: GoToDisiplin(),
  ),
  GameCard(
    id: 10,
    deck: DeckType.kampusKarti,
    text: 'Bölüm birinciliği bursu — 150₺ al.',
    action: GainMoney(150),
  ),
  GameCard(
    id: 11,
    deck: DeckType.kampusKarti,
    text: 'Kan bağışı teşekkür çeki — 20₺ al.',
    action: GainMoney(20),
  ),
  GameCard(
    id: 12,
    deck: DeckType.kampusKarti,
    text: 'Ulaşım kartına yükleme — 40₺ öde.',
    action: PayMoney(40),
  ),
  GameCard(
    id: 13,
    deck: DeckType.kampusKarti,
    text: 'Asistanlık ücreti — 75₺ al.',
    action: GainMoney(75),
  ),
  GameCard(
    id: 14,
    deck: DeckType.kampusKarti,
    text: 'Mezuniyet pastası ısmarladın — her oyuncuya 15₺ öde.',
    action: PayEach(15),
  ),
  GameCard(
    id: 15,
    deck: DeckType.kampusKarti,
    text: 'Harç fazlası iadesi — 100₺ al.',
    action: GainMoney(100),
  ),
];

/// Bir destenin kart listesi.
List<GameCard> deckCards(DeckType deck) =>
    deck == DeckType.sans ? sansCards : kampusCards;

/// Belirli bir kart.
GameCard cardOf(DeckType deck, int id) => deckCards(deck)[id];

/// Bir destedeki Af Kartı'nın id'si.
int afKartiCardId(DeckType deck) =>
    deckCards(deck).firstWhere((c) => c.action is GetAfKarti).id;
