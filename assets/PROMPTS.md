# İTÜpoly — Görsel Üretim Promptları

Bu dosya, oyunun tüm görsel varlıkları için kullanılan / kullanılacak
**image generation promptlarını** tek kaynakta toplar. Üretilenler `assets/` ve
`web/` altına yerleştirilmiştir. Model: **nano-banana-pro (Gemini 3 Pro Image)**,
sağlayıcı: Pika. Ortak stil: koyu gece laciverti (#0B1220), arı altını (#E8B53A),
zümrüt aksan (#2DD4A7), premium-minimal, metinsiz, özgün (Hasbro trade dress ve
resmi İTÜ logosu kullanılmaz).

---

## ✅ Üretilenler

### 1. Uygulama ikonu / logo — `assets/images/logo.png`, `web/icons/*`, `web/favicon.png`
Oran 1:1. Türetildi: PWA 192/512, maskable 192/512, apple-touch 180, favicon 64.
> A premium mobile board-game app icon, rounded-square format. Deep midnight-navy
> background (#0B1220) with a subtle radial golden glow from the center. Centered
> emblem: a stylized geometric golden honeybee elegantly fused with an architect's
> compass/divider tool, built from clean minimal line-art in warm gold (#E8B53A)
> with a soft metallic sheen. Flat modern premium vector style, crisp edges, high
> contrast, perfectly centered and balanced, soft inner shadow, luxurious and
> minimal. Absolutely NO text, NO letters, NO words, NO numbers. Original design,
> must not resemble any existing trademark or logo.

### 2. OG paylaşım görseli — `web/og-image.png` (1200×630)
Oran 16:9 → 1200×630'a kırpıldı. WhatsApp/sosyal link önizlemesi için.
> A sleek premium social-share banner illustration, wide 16:9. Dark midnight-navy
> premium background (#0B1220) with soft golden bokeh glow and emerald accents. On
> the right side, a stylized isometric corner of a monopoly-style game board made
> of glowing miniature university campus faculty buildings, towers and dormitories
> rendered in gold and emerald, with a few elegant minimal game tokens nearby (a
> tiny golden bee, a compass, a hard hat, a coffee cup). Cinematic premium
> lighting, gentle depth of field, modern flat-3D illustration. Generous empty
> negative space on the LEFT third for a title overlay. NO text, NO letters, NO
> words, NO logos. Original premium design.

### 3. Tahta merkez amblemi — `assets/images/emblem.png`
Oran 1:1. Oyun tahtasının ortasında (9×9 boşluk) ve dekoratif kullanım.
> A circular premium game crest emblem on a dark midnight-navy background
> (#0B1220). The crest is a refined golden roundel containing a stylized honeybee,
> an architect's compass, and an open book, arranged symmetrically in elegant
> minimal gold (#E8B53A) line-art with subtle emerald (#2DD4A7) accents. Heraldic
> but modern and clean, premium board-game branding, soft glow, perfectly
> centered. NO text, NO letters, NO words, NO numbers. Original design, not
> resembling any real university logo.

---

## ⏳ Sonraki sürüm için promptlar (henüz vektör/Material ikonla karşılanıyor)

Oyun içi piyonlar şu an keskinlik için Material ikonla çiziliyor
(`lib/widgets/pawn_icon.dart`). İleride özel raster set istenirse:

### 4. Piyon seti (6 adet, her biri 1:1, şeffaf-benzeri koyu zemin)
Ortak kuyruk: *"…as a single premium 3D game token, glossy gold and emerald
finish, centered on deep midnight-navy, soft studio lighting, no text. Original."*
- **Arı:** a cute minimal golden honeybee game piece
- **Pergel:** a polished brass architect's compass/divider game piece
- **Baret:** a golden engineer's hard hat game piece
- **Kahve:** a small golden takeaway coffee cup game piece
- **Hesap makinesi:** a tiny golden pocket calculator game piece
- **Devre kartı:** a small emerald-and-gold circuit-board chip game piece

### 5. Zar animasyonu — `assets/dice.riv` (Rive)
Rive editöründe üretilir (image-gen kapsamı dışı). Tek `.riv`: 3B altın zar,
yuvarlanıp sonuç gösteren state machine. Şimdilik Material ikon zar kullanılıyor.

### 6. Ses efektleri — `assets/sfx/*` (image-gen değil)
zar, satın alma, kira, iflas — kısa premium UI sesleri (opsiyonel, F3).
