# İTÜpoly 🐝

İTÜ temalı, **linkle girilen, mobile-first responsive web** emlak ticareti masa
oyunu. Sade ama premium; 2–6 oyuncu pass & play + bota karşı.

> Tam konsept, tahta, mimari ve yol haritası: **[ITUPOLY_PLAN.md](ITUPOLY_PLAN.md)** (tek doğruluk kaynağı).

## Mimari

```
itupoly/
├── packages/itupoly_engine/   # saf Dart oyun motoru (Flutter bağımsız)
│   ├── lib/src/{models,actions,events,rules,data,bot,sim}/
│   └── test/                  # birim + determinizm + 1000-oyun fuzz
├── lib/                       # Flutter Web sunum katmanı (Riverpod + go_router)
│   ├── app/                   # tema, tokens, router
│   ├── features/{home,setup,game,end,online}/
│   └── widgets/
├── assets/images/             # üretilen marka görselleri (bkz. PROMPTS.md)
├── supabase/schema.sql        # online lockstep şeması (Faz 5)
└── web/                       # PWA manifest, OG meta, favicon, splash
```

**Motor:** event-sourced + deterministik. `PlayerAction → submit() doğrular →
GameEvent listesi → reducer → yeni GameState`. Determinizm aksiyon-replay ile:
`seed + aksiyon dizisi → birebir aynı state`. Kayıt = seed + aksiyon listesi.

## Çalıştırma

```bash
flutter pub get
flutter run -d chrome                      # web'de oyna
flutter build web --wasm                   # yayın derlemesi

# Motor (UI'sız doğrulama):
dart test --directory packages/itupoly_engine
dart run itupoly_engine:itupoly_sim 7 4    # terminalde bot vs bot
```

## Durum

- ✅ **MVP (Faz 0–4)**: motor + kurallar + testler + UI + bot tamamlandı, doğrulandı.
- 🟡 **Faz 5 (online)**: iskelet (şema + lockstep arayüzü + `/oda/:kod`); ağ implementasyonu → [ONLINE.md](ONLINE.md).
- 🟡 **Faz 6 (yayın)**: PWA + OG + Wasm hazır; hosting + beta kaldı.

Test: motor 58 test (1000-oyun fuzz, determinizm, para korunumu) + Flutter widget
testleri. `flutter analyze` & `dart analyze` temiz.

## Hukuk

Özgün isim/görsel/kart dili; Hasbro trade dress'inden ve resmi İTÜ logosundan
uzak. Öğrenci/topluluk projesi olarak ücretsiz dağıtım. (Bkz. plan §1.)
