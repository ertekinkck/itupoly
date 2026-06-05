import 'dart:ui';

/// 40 kareyi 11×11 grid'in çevresine yerleştirir (klasik düzen).
///
/// 0 = sağ-alt köşe (BAŞLA); kareler saat yönünün tersine artar:
/// alt sıra sağ→sol, sol sütun aşağı→yukarı, üst sıra sol→sağ, sağ sütun
/// yukarı→aşağı.
(int row, int col) tileCell(int index) {
  if (index <= 10) return (10, 10 - index); // 0..10 alt sıra
  if (index <= 20) return (20 - index, 0); // 11..20 sol sütun
  if (index <= 30) return (0, index - 20); // 21..30 üst sıra
  return (index - 30, 10); // 31..39 sağ sütun
}

/// Grid boyutu (11×11).
const int gridDim = 11;

/// Tahtanın 3B masa eğimi (radyan). Kuşbakışı yerine açılı perspektif.
const double boardTilt = 0.58;

/// Perspektif derinlik katsayısı (Matrix4 w-satırı).
const double boardDepth = 0.0011;

/// İçeriği eğim sonrası görünüme sığdırmak için ölçek.
const double boardFit = 0.86;

/// Bir track koordinatının (sürekli, 0..40) piksel merkezini hesaplar.
/// [tile] = bir karenin piksel boyutu. Ardışık kareler ortogonal komşu
/// olduğundan köşeler doğal döner (çapraz kesme olmaz).
Offset trackToOffset(double t, double tile) {
  final base = t.floor();
  final frac = t - base;
  final a = tileCell(base % 40);
  final b = tileCell((base + 1) % 40);
  final ax = (a.$2 + 0.5) * tile;
  final ay = (a.$1 + 0.5) * tile;
  final bx = (b.$2 + 0.5) * tile;
  final by = (b.$1 + 0.5) * tile;
  return Offset(ax + (bx - ax) * frac, ay + (by - ay) * frac);
}

/// İleri (pozitif) veya geri (negatif) en kısa adım sayısı.
int signedSteps(int from, int to) {
  final forward = (to - from + 40) % 40;
  return forward <= 20 ? forward : forward - 40;
}
