# İTÜpoly — Online Çok Oyunculu Tasarımı (Faz 5)

> Durum: **iskelet hazır, ağ implementasyonu yapılacak.** Motor zaten online'a
> uygun (deterministik aksiyon-replay). Bu doküman bağlamayı tarif eder.

## Model: Deterministik Lockstep

İTÜpoly motoru `(seed + aksiyon dizisi) → birebir aynı state` garantisi verir
(bkz. `determinism_test.dart`). Bu yüzden ağa **state değil, aksiyon** gönderilir:

1. Host oda kurar → `seed` üretilir, `/oda/KOD` linki paylaşılır.
2. Her istemci aynı `seed` ile `GameEngine.newGame(setups)` çağırır → aynı
   başlangıç (deste karıştırma dahil).
3. Sırası gelen oyuncu bir `PlayerAction` üretir → `game_events`'e `seq` ile
   insert edilir → Realtime ile herkese yayılır.
4. Her istemci gelen aksiyonu `seq` sırasıyla `engine.submit` eder → state
   senkron kalır. (Aynı reducer, aynı rng dizisi.)

`unique(room_id, seq)` çakışan hamleyi DB seviyesinde reddeder. **Reconnect** =
eksik `seq`'leri çekip sırayla replay. **Debug** = periyodik
`jsonEncode(state.toJson())` hash karşılaştırması.

## Parçalar

| Parça | Yer | Durum |
|---|---|---|
| Şema (rooms, room_players, game_events) | `supabase/schema.sql` | ✅ |
| Taşıma sözleşmesi (ağdan bağımsız) | `lib/features/online/online_transport.dart` | ✅ |
| `/oda/:kod` derin bağlantı + lobi | `lib/features/online/online_room_screen.dart` | ✅ (placeholder) |
| Supabase Realtime implementasyonu | `supabase_online_transport.dart` | ⏳ |
| Lobi presence + start akışı | online lobby screen | ⏳ |

## Yapılacaklar (implementasyon)

1. `supabase_flutter` bağımlılığını ekle; `Supabase.initialize(url, anonKey)`.
2. `OnlineTransport`'u Supabase ile uygula:
   - `createRoom`: `rooms` insert (code, seed, host), `room_players` insert.
   - `joinRoom`: koddan oda bul, boş seat al.
   - `watchActions`: `game_events` üzerinde Realtime channel + ilk backfill.
   - `sendAction`: `game_events` insert (seq, payload = action.toJson()).
3. `GameController`'a online modu: yerel aksiyonu hem `submit` et hem `sendAction`;
   uzak aksiyonları `watchActions`'tan al ve `submit` et. (Mevcut `dispatch`
   neredeyse hazır — sadece kaynak ayrımı + seq yönetimi eklenir.)
4. İlk sürümde host = referee (kural doğrulayıcı). Sonra RLS + edge function.

Online, MVP kapsamı dışıdır; pass & play ve bota karşı mod tam çalışır.
