# İTÜPOLY — Geliştirme Planı

> Flutter Web (Dart) ile geliştirilecek, **linkle girilen, mobile-first responsive bir web uygulaması**: İTÜ temalı, sade ama premium hissiyatlı bir emlak ticareti masa oyunu.
> Bu doküman konsepti, tahta tasarımını, mimariyi, UI dilini ve fazlara bölünmüş yol haritasını tanımlar.
> Repo kökünde yaşar; geliştirme boyunca tek doğruluk kaynağıdır (Claude Code ile çalışırken de referans dosyasıdır).

---

## 0. Özet

| | |
|---|---|
| **Platform** | Web (Flutter Web) — linkle erişim, mobile-first responsive, PWA olarak yüklenebilir |
| **Tür** | Sıra tabanlı masa oyunu, 2–6 oyuncu |
| **MVP** | Tek cihazda pass-and-play + basit bot |
| **Sonrası** | Online multiplayer (Supabase Realtime) |
| **Temel ilke** | Oyun motoru saf Dart, UI'dan tamamen bağımsız, %100 test edilebilir |
| **Para birimi** | **Kredi (₭)** — hem AKTS hem para esprisi |

---

## 1. Konsept ve Tema

İTÜpoly, klasik emlak ticareti mekaniğini İTÜ kampüs evrenine taşır. Oyuncular fakülteleri, yurtları ve kampüs binalarını satın alır, üzerine "derslik" ve "amfi" (ev/otel karşılığı) inşa eder, rakiplerinden kira toplar. Amaç: diğerlerini mezun edemeden iflas ettirmek.

Tema eşleştirmeleri:

| Klasik | İTÜpoly |
|---|---|
| BAŞLA (+maaş) | **Kayıt Yenileme** (+200₭ burs) |
| Hapishane | **Disiplin Kurulu** |
| Hapse Gir | **Disipline Sevk!** |
| Serbest Park | **Çim Amfi** (dinlen, hiçbir şey olmaz) |
| İstasyonlar (4) | **Ring durakları** |
| Şirketler (2) | **BİDB İnterneti** ve **Yemekhane** |
| Şans / Sandık | **Şans** ve **Kampüs Kartı** |
| Ev / Otel | **Derslik / Amfi** |
| Hapisten çıkış kartı | **Af Kartı** |

### Marka ve hukuk notu

- Oyun **mekanikleri** telif kapsamında değildir; isim, tahta görseli, kart dili ve karakterler korunur. Bu yüzden:
  - Hasbro'nun trade dress'inden uzak dur: Mr. Monopoly figürü, ikonik köşe tasarımı, orijinal kart metinleri **kullanılmaz**.
  - Tüm görsel kimlik (ikonlar, kareler, kartlar, piyonlar) sıfırdan, özgün tasarlanır.
- "İTÜ" adı ve arı logosu da üniversitenin tescilidir. Resmi logoyu kullanmadan kampüs temalı özgün ikonografi tercih edilir; store'da ticari yayın hedeflenirse üniversiteden yazılı izin alınır. Öğrenci/topluluk projesi olarak ücretsiz dağıtım pratikte sorun çıkarmaz.

---

## 2. Tahta Tasarımı (40 kare)

Klasik 40 kare düzeni birebir korunur (denenmiş ekonomi dengesi). Fiyat/kira değerleri klasik tablodan alınır; tam tablo `board_tr.dart` içinde veri olarak tutulur. Kare isimleri sabit değildir: hepsi veri olduğu için topluluk esprileriyle tek dosyadan güncellenir.

| # | Kare | Tür | Grup | Fiyat |
|---|---|---|---|---|
| 0 | Kayıt Yenileme (BAŞLA) | köşe | — | — |
| 1 | Tuzla Yerleşkesi | arsa | Kahverengi | 60 |
| 2 | Kampüs Kartı | kart | — | — |
| 3 | Denizcilik Fakültesi | arsa | Kahverengi | 60 |
| 4 | Dönem Harcı | vergi | — | 200 öde |
| 5 | Ring: Ana Kapı | ring | İstasyon | 200 |
| 6 | Maçka Yerleşkesi | arsa | Açık Mavi | 100 |
| 7 | Şans | kart | — | — |
| 8 | İşletme Fakültesi | arsa | Açık Mavi | 100 |
| 9 | Yabancı Diller YO | arsa | Açık Mavi | 120 |
| 10 | Disiplin Kurulu (Ziyaretçi) | köşe | — | — |
| 11 | Gümüşsuyu Yerleşkesi | arsa | Pembe | 140 |
| 12 | BİDB İnterneti | şirket | Altyapı | 150 |
| 13 | Makine Fakültesi | arsa | Pembe | 140 |
| 14 | Taşkışla — Mimarlık | arsa | Pembe | 160 |
| 15 | Ring: MED | ring | İstasyon | 200 |
| 16 | KYK Yurtları | arsa | Turuncu | 180 |
| 17 | Kampüs Kartı | kart | — | — |
| 18 | Vadi Yurtları | arsa | Turuncu | 180 |
| 19 | 75. Yıl ÖSM | arsa | Turuncu | 200 |
| 20 | Çim Amfi | köşe | — | — |
| 21 | İnşaat Fakültesi | arsa | Kırmızı | 220 |
| 22 | Şans | kart | — | — |
| 23 | Fen-Edebiyat Fakültesi | arsa | Kırmızı | 220 |
| 24 | Kimya-Metalurji Fakültesi | arsa | Kırmızı | 240 |
| 25 | Ring: KSB | ring | İstasyon | 200 |
| 26 | Uçak ve Uzay Fakültesi | arsa | Sarı | 260 |
| 27 | Elektrik-Elektronik Fak. | arsa | Sarı | 260 |
| 28 | Yemekhane | şirket | Altyapı | 150 |
| 29 | Bilgisayar ve Bilişim Fak. | arsa | Sarı | 280 |
| 30 | Disipline Sevk! | köşe | — | — |
| 31 | Mustafa İnan Kütüphanesi | arsa | Yeşil | 300 |
| 32 | SDKM | arsa | Yeşil | 300 |
| 33 | Kampüs Kartı | kart | — | — |
| 34 | İTÜ Stadyumu | arsa | Yeşil | 320 |
| 35 | Ring: Metro İstasyonu | ring | İstasyon | 200 |
| 36 | Şans | kart | — | — |
| 37 | Arı Teknokent | arsa | Lacivert | 350 |
| 38 | Mezuniyet Harcı | vergi | — | 100 öde |
| 39 | Rektörlük | arsa | Lacivert | 400 |

### Ekonomi kuralları (klasik değerler)

- Başlangıç parası: **1500₭**, BAŞLA'dan geçiş: **+200₭**.
- Kira: temel kira → tekel (grup tamamsa boş arsada ×2) → 1–4 derslik → amfi (klasik kira merdiveni).
- Derslik maliyeti kenara göre: **50 / 100 / 150 / 200₭** (kahverengi kenarından lacivert kenarına).
- Ring kirası sahip olunan durak sayısına göre: **25 / 50 / 100 / 200₭**.
- Şirket kirası: 1 şirket → zar×4, 2 şirket → zar×10.
- İpotek: fiyatın yarısı; geri alma %10 faizle. İpotekli karede kira işlemez.
- Disiplin Kurulu'ndan çıkış: 50₭ ceza, çift zar (3 deneme) veya **Af Kartı**.
- Üç kez üst üste çift atan **Disipline sevk** edilir.

### Kart desteleri (16 + 16)

Tüm metinler özgün yazılır, `cards_tr.dart` içinde veri olarak tutulur. Örnek ton:

**Şans:** "Bütünlemeye kaldın — 100₭ öde." · "TÜBİTAK bursu onaylandı — 150₭ al." · "Ring'i kaçırdın — Ring: MED durağına yürü." · "Disipline sevk edildin." · "Hocadan +1 — Af Kartı kazandın."

**Kampüs Kartı:** "Dönem projesi ödülü — 100₭ al." · "Kütüphane gecikme cezası — 30₭ öde." · "Mezuniyet fotoğrafı — her oyuncudan 10₭ al." · "Kayıt yenileme zamanı — BAŞLA'ya ilerle, 200₭ al."

---

## 3. Kural Kapsamı

**MVP'de var:** zar/hareket, satın alma, kira, tekel çarpanı, derslik/amfi inşaatı (eşit inşaat kuralı), ipotek, vergiler, kart desteleri, Disiplin Kurulu akışı, çift zar, iflas ve tasfiye, kazanan tespiti.

**Kapsam dışı (kalıcı karar):**
- **Açık artırma** — eklenmeyecek. Reddedilen arsa bankada kalır; ileride üzerine gelen herkes alabilir. Motor bu yüzden auction fazı hiç içermez.

**MVP'de yok, sonraki sürümde:**
- **Oyuncular arası takas** — v1.1'de basit teklif UI'ı ile (arsa + nakit ⇄ arsa + nakit).
- Derslik kıtlığı (32 derslik / 12 amfi limiti) — v1.2.

Bu kapsam kilidi scope creep'e karşı ana savunmadır.

---

## 4. Teknik Mimari

### 4.1 Katman ayrımı

```
itupoly/
├── packages/itupoly_engine/   ← saf Dart, Flutter import'u YOK
└── lib/                       ← Flutter uygulaması (sadece sunum)
```

Motor saf Dart paketi olduğu için: `dart test` ile saniyede binlerce oyun simüle edilir, bot eğitimi headless çalışır, ileride online doğrulama için yeniden kullanılır.

### 4.2 Event-sourced çekirdek

Akış: **PlayerAction (niyet) → Engine doğrular → GameEvent listesi (gerçekleşen) → reducer → yeni GameState**.

Kazanımlar:
- **Determinizm:** aynı seed + aynı aksiyon dizisi = aynı state. Test ve online senkron bunun üstüne kurulur.
- **Kayıt = event log:** oyunu kaydetmek JSON'a event listesi yazmak; yüklemek replay etmektir.
- **Animasyon kuyruğu:** UI, event listesini sırayla oynatır (zar → hop hop hareket → kira uçuşu).
- **Online senkron:** ağa state değil, sadece event'ler gider.

### 4.3 Çekirdek tipler (eskiz)

```dart
// packages/itupoly_engine

enum TurnPhase { awaitRoll, moving, resolveTile, awaitDecision, inDisiplin, endTurn, gameOver }

sealed class Tile { final int index; final String name; }
class PropertyTile extends Tile { final TileGroup group; final int price; final List<int> rents; final int houseCost; }
class RingTile extends Tile { final int price; }
class UtilityTile extends Tile { final int price; }
class TaxTile extends Tile { final int amount; }
class CardTile extends Tile { final DeckType deck; }
class CornerTile extends Tile { final CornerType type; }

sealed class PlayerAction {}                 // UI/bot → engine
class RollDice extends PlayerAction {}
class BuyProperty extends PlayerAction {}
class DeclineBuy extends PlayerAction {}
class BuildHouse extends PlayerAction { final int tileIndex; }
class MortgageTile extends PlayerAction { final int tileIndex; }
class PayDisiplinFine extends PlayerAction {}
class UseAfKarti extends PlayerAction {}
class EndTurn extends PlayerAction {}

sealed class GameEvent {}                    // engine → state/UI
class DiceRolled extends GameEvent { final int d1, d2; }
class TokenMoved extends GameEvent { final int playerId, from, to; final bool passedStart; }
class PropertyBought extends GameEvent { final int playerId, tileIndex; }
class RentPaid extends GameEvent { final int fromId, toId, amount; }
class CardDrawn extends GameEvent { final DeckType deck; final int cardId; }
class SentToDisiplin extends GameEvent { final int playerId; }
class PlayerBankrupted extends GameEvent { final int playerId; final int? toPlayerId; }
class GameEnded extends GameEvent { final int winnerId; }

class GameEngine {
  final Random rng;                          // seed dışarıdan enjekte → deterministik
  GameEngine(this.rng);

  /// Aksiyonu doğrular; geçersizse RuleViolation döner,
  /// geçerliyse event listesi üretir ve yeni state'i hesaplar.
  (GameState, List<GameEvent>) submit(GameState state, PlayerAction action);
}
```

`GameState` ve modeller **freezed** ile immutable; `json_serializable` ile serileştirilir (kayıt + ağ).

### 4.4 Tur durum makinesi

```
awaitRoll ──RollDice──▶ moving ──▶ resolveTile ──┬─▶ awaitDecision (boş arsa: al / pas)
    ▲                                            ├─▶ otomatik: kira / vergi / kart / sevk
    │            (çift attıysa tekrar awaitRoll) │
 endTurn ◀───────────────────────────────────────┘
```

İnşaat ve ipotek (`BuildHouse`, `MortgageTile`) sıra sendeyken `awaitRoll`/`endTurn` fazlarında her an yapılabilir. Borç ödenemediğinde engine `mustLiquidate` bayrağı koyar; oyuncu ipotek/satışla nakit yaratamazsa iflas event'i üretilir.

### 4.5 State management (Flutter tarafı)

```dart
final engineProvider = Provider((_) => GameEngine(Random(seed)));
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

class GameNotifier extends Notifier<GameState> {
  void submit(PlayerAction a) {
    final (next, events) = ref.read(engineProvider).submit(state, a);
    state = next;
    ref.read(fxQueueProvider).enqueue(events); // animasyon + ses + haptik kuyruğu
  }
}
```

Riverpod yeterli; Bloc'a gerek yok. UI hiçbir kural bilmez, sadece state'i çizer ve action gönderir.

### 4.6 Paketler

| Paket | Amaç |
|---|---|
| `flutter_riverpod` | state management |
| `freezed` + `json_serializable` | immutable modeller, (de)serileştirme |
| `go_router` | URL tabanlı navigasyon (path strategy, #'siz adresler), `/oda/KOD` deep linkleri |
| `google_fonts` | tipografi (Manrope) |
| `rive` | zar animasyonu (tek .riv dosyası) |
| `audioplayers` | ses efektleri (opsiyonel, F3) |
| `shared_preferences` | otomatik kayıt — event log JSON, localStorage'a |
| `supabase_flutter` | F5 — online |

---

## 5. UI/UX Tasarımı

Hedef his: **sade, karanlık, premium**. Oyun ekranı tek bakışta okunur; süsleme mikro-etkileşimlerde.

### 5.1 Design tokens

| Token | Değer |
|---|---|
| Arka plan | `#0B1220` (gece laciverti) |
| Yüzey (glass) | `rgba(255,255,255,0.05)` + blur 20, border `rgba(255,255,255,0.08)` |
| Vurgu | `#E8B53A` (arı altını) |
| Pozitif / negatif para | `#2DD4A7` zümrüt / `#F0556B` |
| Radius | kart 20, buton 12 |
| Tipografi | Manrope; para için tabular rakamlar |
| Grup renkleri | 8 doygun pastel; renk körlüğü için her grupta **ikon + renk** birlikte |

### 5.2 Ekranlar

1. **Ana Menü** — logo, "Yeni Oyun", "Devam Et", "Nasıl Oynanır", ayarlar.
2. **Oyun Kurulumu** — 2–6 oyuncu; isim, piyon seçimi, bot toggle'ı.
3. **Oyun** — ana ekran (aşağıda).
4. **Oyun Sonu** — kazanan, net değer grafiği, "tekrar oyna".

### 5.3 Oyun ekranı düzeni

- **Tahta:** 11×11 mantıksal grid, kenar şeritlerinde 40 kare. `InteractiveViewer` ile zoom/pan (1.0×–2.5×). Kare başına `RepaintBoundary`.
- **Kare detayı:** kareye dokununca bottom sheet — tapu kartı görünümü (kira merdiveni, sahip, ipotek/inşaat butonları).
- **İnşaat görseli:** kare üstünde **minyatür bina ikonları** — 1–4 derslik küçük SVG dizisi (grup rengiyle tonlu), amfi tek altın bina. Rozet sayaç değil; premium his buradan gelir.
- **HUD (alt bar):** sıradaki oyuncu, bakiye (animasyonlu sayaç), küçük avatar şeridi.
- **Zar:** ortada overlay Rive animasyonu; sonuç + haptik `mediumImpact`.
- **Piyon hareketi:** kare kare hop (~140 ms/kare, `easeOutBack`), her karede `selectionClick` haptiği.
- **Para transferi:** bakiyeden bakiyeye uçan ₭ çipi (overlay katmanı).
- **Kart çekme:** 3D flip animasyonlu kart modalı.
- **Pass-and-play gizliliği:** sıra değişiminde "Telefonu X'e ver" perdesi (varlıklar herkese açık olduğu için hafif tutulur).

### 5.4 Responsive düzen (web)

Tahta her zaman 1:1 kare kalır; `LayoutBuilder` + üç breakpoint:

- **< 600 px (telefon, dikey):** tahta tam genişlik, HUD altta, tüm detaylar bottom sheet. **Birincil hedef bu.**
- **600–1024 px (tablet):** tahta ortalanır, HUD kompakt yan şeride geçer.
- **> 1024 px (desktop):** tahta solda sabit kare; sağda oyuncu paneli + canlı **olay günlüğü** (event-sourced mimarinin bedava çıktısı — her event zaten okunabilir bir satır).

Desktop'ta hover (kare üzerine gelince tapu önizleme), mobilde dokunma. Haptik yalnızca destekleyen mobil tarayıcılarda çalışır (Android Chrome); iOS Safari'de geri bildirim ses + animasyonla sağlanır.

### 5.5 Piyonlar (özgün ikon seti)

Arı, pergel, baret, kahve bardağı, hesap makinesi, devre kartı. SVG olarak sıfırdan çizilir (Figma veya pycairo pipeline'ı — Masraff/Curo ikon iş akışının aynısı).

---

## 6. Bot AI

- **v0 (MVP):** kurallı greedy. `minCash = 150₭` tamponunu koru; tampon üstündeyse boş arsayı al; grup tamamlanıyorsa tamponu deler. İnşaatı tamamlanmış en değerli grupta eşit kuralla yap. Borçta en düşük getirili kareden ipoteğe başla.
- **v1:** heuristik değer fonksiyonu — grup tamamlama bonusu, rakip yoğunluğu (turuncu/kırmızı kareler en çok basılan bölge), nakit/varlık oranı.
- **Stretch (araştırma mini-projesi):** engine headless ve deterministik olduğundan self-play ile RL denenebilir; öğrenilen politika karar tablosuna damıtılıp Dart'a gömülür. Ayrı branch, ana plana bağımlılık yok.

---

## 7. Online Multiplayer (Faz 5 — Supabase)

Model: **deterministik lockstep**. Ağa sadece aksiyon/event gider, her istemci aynı reducer'ı çalıştırır.

```sql
create table rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,          -- 6 haneli oda kodu
  host_id uuid not null,
  seed bigint not null,
  status text not null default 'lobby',
  created_at timestamptz default now()
);

create table room_players (
  room_id uuid references rooms(id),
  user_id uuid not null,
  seat int not null,
  name text not null,
  primary key (room_id, seat)
);

create table game_events (
  id bigserial primary key,
  room_id uuid references rooms(id),
  seq int not null,                   -- sıra numarası: senkronun bel kemiği
  payload jsonb not null,
  sender_id uuid not null,
  unique (room_id, seq)
);
```

Akış: host oda kurar → **`/oda/KOD` linki paylaşılır** (web'in en büyük avantajı: tıkla, gir) → Realtime **presence** ile lobi → start(seed) → her aksiyon `game_events`'e insert → Realtime ile tüm istemcilere yayılır → herkes uygular. `unique(room_id, seq)` çakışan hamleyi DB seviyesinde reddeder. Reconnect = eksik seq'leri çekip replay. İlk sürümde host doğrulayıcıdır (referee); ileride RLS + edge function ile sunucu taraflı kural doğrulaması eklenir. Debug için periyodik state-hash karşılaştırması.

---

## 8. Test Stratejisi

Motor önce yazıldığı için oyun, UI'dan haftalar önce testlerde "oynanabilir" olur.

- **Birim testleri (engine):** kira merdiveni (tekel, derslik, amfi), ring 1–4 sahiplik, şirket zar çarpanı, Disiplin Kurulu akışı, 3 çift → sevk, ipotekli karede kira işlememesi, iflas ve varlık devri.
- **Determinizm testi:** aynı seed + aynı aksiyon dizisi → birebir aynı state hash'i.
- **Fuzz / invariant testleri:** 4 random bot, 1000 tam oyun. Kontroller: hiçbir bakiye negatif kalmaz, para korunumu tutarlıdır (banka giriş-çıkışıyla), her oyun sonlanır (tur limiti emniyeti), hiçbir aksiyon exception fırlatmaz.
- **Widget testleri:** HUD, tapu sheet'i, satın alma diyaloğu.
- **Golden testler (ops.):** tahta layout'u üç breakpoint'te (telefon / tablet / desktop).
- **Entegrasyon:** bot vs bot tam oyun, UI üzerinden başa-sona.

CI (GitHub Actions): `format` → `analyze` → `dart test` (engine) → `flutter test`.

---

## 9. Klasör Yapısı

```
itupoly/
├── packages/
│   └── itupoly_engine/
│       ├── lib/
│       │   ├── src/
│       │   │   ├── models/        # tile, player, game_state, card
│       │   │   ├── actions/       # PlayerAction tipleri
│       │   │   ├── events/        # GameEvent + reducer
│       │   │   ├── rules/         # kira, inşaat, ipotek, iflas
│       │   │   ├── data/          # board_tr.dart, cards_tr.dart
│       │   │   └── engine.dart    # GameEngine.submit()
│       │   └── itupoly_engine.dart
│       └── test/
├── lib/
│   ├── app/                       # tema, tokens, router
│   ├── features/
│   │   ├── home/
│   │   ├── setup/                 # oyuncu kurulumu
│   │   ├── game/
│   │   │   ├── board/             # tahta + kareler + piyonlar
│   │   │   ├── hud/
│   │   │   ├── sheets/            # tapu, kart, takas (v1.1)
│   │   │   └── providers/         # GameNotifier, FxQueue
│   │   └── end/
│   └── main.dart
├── assets/                        # rive zar, ses, piyon SVG'leri
├── web/                           # index.html, PWA manifest, OG meta, favicon
└── test/
```

---

## 10. Yol Haritası

### Faz 0 — Hazırlık (~yarım hafta) ✅
- [x] Repo + lint (`very_good_analysis`) + CI (`.github/workflows/ci.yml`)
- [x] `packages/itupoly_engine` iskeleti (freezed yerine elle immutable model — bkz. Karar Kaydı)
- [x] Bu planın repo köküne konması

### Faz 1 — Motor (~2 hafta) ⟵ projenin kalbi ✅
- [x] Modeller + `board_tr.dart` + `cards_tr.dart`
- [x] Reducer + tur durum makinesi
- [x] Kira / inşaat / ipotek / iflas kuralları
- [x] Birim + determinizm + fuzz testleri (58 test, 1000-oyun fuzz, tüm invariantlar)
- [x] Mini CLI runner (`dart run itupoly_engine:itupoly_sim`)

### Faz 2 — Çekirdek UI (~2 hafta) ✅
- [x] Tema + design tokens
- [x] Tahta render + InteractiveViewer + kare detay sheet'i
- [x] Minyatür derslik/amfi ikonları (inşaat görseli)
- [x] HUD, zar, satın alma akışı
- [x] Pass-and-play uçtan uca oynanabilir

### Faz 3 — Polish (~1–1.5 hafta) ✅
- [x] Piyon hop animasyonu (çevre yolu takipli) + haptikler + animasyonlu bakiye sayacı
- [x] Kart flip modalı (Rive zar/ses ertelendi — Material zar; bkz. Karar Kaydı)
- [x] Otomatik kayıt / devam et (seed + aksiyon replay, shared_preferences)
- [x] Onboarding ("Nasıl Oynanır")

### Faz 4 — Bot (~1 hafta) ✅
- [x] v0 greedy bot + "tek başına / bota karşı oyna" modu
- [x] v1 heuristik iyileştirme (grup trafiği, tamamlama, ROI)

### Faz 5 — Online (~2–3 hafta) — 🟡 iskelet
- [x] Supabase şema (`supabase/schema.sql`) + lockstep transport arayüzü + `/oda/:kod`
- [ ] Event senkronizasyonu + reconnect/replay (ağ implementasyonu — `ONLINE.md`)
- [ ] State-hash debug aracı (tasarım hazır: `GameState.toJson` hash)

### Faz 6 — Yayın (~1 hafta) — 🟡 kısmi
- [ ] Hosting + domain (Cloudflare Pages / Firebase Hosting — `build/web` hazır)
- [x] PWA: manifest, ikonlar (arı motifi), favicon, apple-touch
- [x] OG meta etiketleri — WhatsApp önizleme kartı (`og-image.png`)
- [x] Wasm build (`flutter build web --wasm` ✓) + markalı splash (index.html)
- [ ] Kapalı beta: link İTÜ'lü arkadaşlara

**MVP = Faz 0–3 + Faz 4 v0.** Takas v1.1; online v1.2. Açık artırma kapsam dışı.

---

## 11. MVP Tanımı ve Başarı Kriterleri

MVP "bitti" sayılır, eğer:

1. 2–6 oyuncu tek cihazda baştan sona, kural hatasız oyun bitirebiliyor.
2. Fuzz testleri 1000 oyunu istisnasız tamamlıyor.
3. Telefon yatay tutulmadan, zoom'a mecbur kalmadan tahta okunabiliyor.
4. Bir tur (zar→hareket→işlem) 10 saniyenin altında akıyor; animasyonlar atlanabiliyor (uzun basışla hızlandır).
5. Uygulama oyun ortasında kapatılıp açıldığında kaldığı yerden devam ediyor.

---

## 12. Riskler ve Önlemler

| Risk | Önlem |
|---|---|
| Marka (Hasbro) | Özgün isim/görsel/kart dili; trade dress'ten uzak durma (bkz. §1) |
| İTÜ adı/logosu | Resmi logo yok, özgün ikonografi; ticari yayın öncesi izin |
| Scope creep | Kapsam kilidi (§3) + fazlara bağlı checkbox'lar |
| Online senkron hataları | Determinizm + seq + state-hash karşılaştırma; online'ın en sona bırakılması |
| Performans (40 kare + animasyon) | Kare başına RepaintBoundary, const widget'lar, animasyonun overlay'de izole edilmesi |
| Flutter Web ilk yükleme boyutu | Wasm build, deferred loading, markalı splash; oyun tek sayfa olduğundan sonrası akıcı |
| iOS Safari kısıtları (ses/haptik) | Ses ilk dokunuşla başlatılır; haptik yerine görsel + ses geri bildirim |
| Tek geliştirici zamanı | Motor-önce yaklaşım: UI gecikse bile test/CLI üzerinden oynanabilir çekirdek var |

---

## 13. Karar Kaydı

| Tarih | Karar |
|---|---|
| 04.06.2026 | **Açık artırma kapsam dışı** — hiçbir sürümde olmayacak. Motor auction fazı içermez. |
| 04.06.2026 | Kare isimleri topluluk esprileriyle güncellenecek; tek kaynak `board_tr.dart`. |
| 04.06.2026 | 36 kareli hızlı mod **yok** — tek tahta, tek mod. |
| 04.06.2026 | İnşaat görseli **kesin var**: minyatür bina ikonları (1–4 derslik + altın amfi). |
| 04.06.2026 | Lokalizasyon yok — oyun **yalnızca Türkçe**. |
| 04.06.2026 | Platform: mobil app değil — **linkle girilen, mobile-first responsive web app** (Flutter Web + PWA). Store süreci yok; dağıtım = URL. |
| 04.06.2026 | **freezed/codegen yerine elle yazılmış immutable modeller** (copyWith + toJson). Gerekçe: planın hedefleri (immutability, serileştirme, determinizm, %100 test) korunur; build_runner kırılganlığı ve otonom doğrulama riski ortadan kalkar. |
| 04.06.2026 | **Determinizm = aksiyon-replay** (seed + aksiyon dizisi → birebir aynı state). rng yalnızca `submit` (zar) ve `newGame` (karıştırma) içinde. Event'ler animasyon/olay günlüğü/online senkron besler. Kayıt = seed + aksiyon listesi. |
| 04.06.2026 | **Tur limiti emniyeti** (varsayılan 600 tur): MVP'de derslik kıtlığı (v1.2) olmadığından stalemate olabilir; limitte oyun en yüksek **net değer**le biter. 1000-oyun fuzz bununla istisnasız sonlanır. |
| 04.06.2026 | **Rive zar + ses (audioplayers) ertelendi** — Material zar + custom animasyon (hop, kart flip, sayaç) + haptik kullanıldı. Build hafif, ek asset bağımlılığı yok. Promptlar/notlar `assets/PROMPTS.md`. |
| 04.06.2026 | **Görsel kimlik image generation ile üretildi** (nano-banana-pro): logo/app icon/favicon/PWA, OG paylaşım görseli, tahta amblemi. Tüm promptlar `assets/PROMPTS.md`. Piyonlar keskinlik için Material ikon (prompt'lar belgeli). |
| 04.06.2026 | **Online (Faz 5) iskelet olarak teslim**: Supabase şema (`supabase/schema.sql`), lockstep transport arayüzü, `/oda/:kod` derin bağlantı, `ONLINE.md`. Tam ağ implementasyonu MVP dışı. |
