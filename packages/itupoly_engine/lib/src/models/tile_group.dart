/// Kare grupları. 8 renk grubu + istasyon (ring) + altyapı (şirket).
///
/// Renk körlüğü için her grupta **renk + ikon** birlikte verilir (UI bunu
/// kullanır). Motor saf Dart'tır; renk/ikon yalnızca veridir, çizim yapmaz.
enum TileGroup {
  kahverengi('Kahverengi', 0xFF8D6E63, 'school', isColorGroup: true),
  acikMavi('Açık Mavi', 0xFF4FC3F7, 'menu_book', isColorGroup: true),
  pembe('Pembe', 0xFFF06292, 'architecture', isColorGroup: true),
  turuncu('Turuncu', 0xFFFFB74D, 'apartment', isColorGroup: true),
  kirmizi('Kırmızı', 0xFFE57373, 'science', isColorGroup: true),
  sari('Sarı', 0xFFFFD54F, 'flight', isColorGroup: true),
  yesil('Yeşil', 0xFF81C784, 'local_library', isColorGroup: true),
  lacivert('Lacivert', 0xFF5C6BC0, 'account_balance', isColorGroup: true),
  istasyon('Ring', 0xFFB0BEC5, 'directions_bus', isColorGroup: false),
  altyapi('Altyapı', 0xFF90A4AE, 'bolt', isColorGroup: false)
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
