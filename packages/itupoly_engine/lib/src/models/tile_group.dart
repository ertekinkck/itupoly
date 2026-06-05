/// Kare grupları. 8 renk grubu + istasyon (ring) + altyapı (şirket).
///
/// Renk körlüğü için her grupta **renk + ikon** birlikte verilir (UI bunu
/// kullanır). Motor saf Dart'tır; renk/ikon yalnızca veridir, çizim yapmaz.
enum TileGroup {
  kahverengi('Kahverengi', 0xFF7A411F, 'school', isColorGroup: true),
  acikMavi('Açık Mavi', 0xFFBAE2F8, 'menu_book', isColorGroup: true),
  pembe('Pembe', 0xFFE52E8F, 'architecture', isColorGroup: true),
  turuncu('Turuncu', 0xFFF7941D, 'apartment', isColorGroup: true),
  kirmizi('Kırmızı', 0xFFED1C24, 'science', isColorGroup: true),
  sari('Sarı', 0xFFFFED00, 'flight', isColorGroup: true),
  yesil('Yeşil', 0xFF1FB25A, 'local_library', isColorGroup: true),
  lacivert('Lacivert', 0xFF0054A6, 'account_balance', isColorGroup: true),
  istasyon('Ring', 0xFF607D8B, 'directions_bus', isColorGroup: false),
  altyapi('Altyapı', 0xFF8D6E63, 'bolt', isColorGroup: false)
  ;

  const TileGroup(
    this.label,
    this.colorValue,
    this.iconName, {
    required this.isColorGroup,
  });

  /// Kullanıcıya gösterilecek grup adı.
  final String label;

  /// ARGB renk değeri (UI'da `Color(value)`).
  final int colorValue;

  /// UI'nın eşleyeceği Material ikon adı (renk körlüğü desteği).
  final String iconName;

  /// 8 ana renk grubundan biri mi? (Tekel/inşaat yalnızca bunlarda.)
  final bool isColorGroup;
}
