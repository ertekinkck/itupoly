import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

// ---------------------------------------------------------------------------
// Renk / stil sabitler
// ---------------------------------------------------------------------------

const _chanceOrange = Color(0xFFE65100);
const _chestBlue = Color(0xFF1565C0);

_CardTheme _themeFor(DeckType deck) {
  if (deck == DeckType.sans) {
    return const _CardTheme(
      headerColor: _chanceOrange,
      headerText: 'ŞANS',
      symbol: '?',
      symbolColor: Colors.white,
      borderColor: _chanceOrange,
    );
  }
  return const _CardTheme(
    headerColor: _chestBlue,
    headerText: 'KAMPÜS FONU',
    symbol: '📦',
    symbolColor: Colors.white,
    borderColor: _chestBlue,
  );
}

class _CardTheme {
  const _CardTheme({
    required this.headerColor,
    required this.headerText,
    required this.symbol,
    required this.symbolColor,
    required this.borderColor,
  });

  final Color headerColor;
  final String headerText;
  final String symbol;
  final Color symbolColor;
  final Color borderColor;
}

// ---------------------------------------------------------------------------
// Para etki hesabı
// ---------------------------------------------------------------------------

_AmountBadge? _badgeFor(GameCard card) {
  final a = card.action;
  if (a is GainMoney) return _AmountBadge('+${a.amount}₭', const Color(0xFF2E7D32));
  if (a is PayMoney) return _AmountBadge('-${a.amount}₭', const Color(0xFFC62828));
  if (a is CollectFromEach) return _AmountBadge('+${a.amount}₭ × oyuncu', const Color(0xFF2E7D32));
  if (a is PayEach) return _AmountBadge('-${a.amount}₭ × oyuncu', const Color(0xFFC62828));
  if (a is GetAfKarti) return const _AmountBadge('AF KARTI 🎓', Color(0xFF6A1B9A));
  if (a is GoToDisiplin) return const _AmountBadge('DİSİPLİN KURULU ⚖️', Color(0xFFB71C1C));
  if (a is MoveTo) return const _AmountBadge('HAREKET ➡️', Color(0xFF0277BD));
  if (a is MoveBack) return const _AmountBadge('GERİ GİT ⬅️', Color(0xFF4E342E));
  return null;
}

class _AmountBadge {
  const _AmountBadge(this.label, this.color);
  final String label;
  final Color color;
}

// ---------------------------------------------------------------------------
// Ana overlay widget — Stack içine doğrudan eklenir (dialog değil)
// ---------------------------------------------------------------------------

/// Piyon kareye varınca tetiklenen Monopoly tarzı kart gösterimi.
///
/// Kartı Stack üzerinde gösterir; [onDone] çağrılınca kaldırılır.
class CardDrawOverlay extends StatefulWidget {
  const CardDrawOverlay({
    required this.card,
    required this.onDone,
    super.key,
  });

  final GameCard card;
  final VoidCallback onDone;

  @override
  State<CardDrawOverlay> createState() => _CardDrawOverlayState();
}

class _CardDrawOverlayState extends State<CardDrawOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _flipAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    // Kart aşağıdan yukarıya süzülür
    _slideAnim = Tween<double>(begin: 120, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    // Y-ekseni flip: 1.0→0.0 (180°→0°, yani arka yüzden ön yüze)
    _flipAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(widget.card.deck);
    final badge = _badgeFor(widget.card);

    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Stack(
              children: [
                // Arka plan blur + karartma
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),

                // Kart
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_flipAnim.value * 3.14159),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          child: _MonopolyCard(
            card: widget.card,
            theme: theme,
            badge: badge,
            onTap: _dismiss,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monopoly fiziksel kart görünümü
// ---------------------------------------------------------------------------

class _MonopolyCard extends StatelessWidget {
  const _MonopolyCard({
    required this.card,
    required this.theme,
    required this.badge,
    required this.onTap,
  });

  final GameCard card;
  final _CardTheme theme;
  final _AmountBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final cardW = sw.clamp(260.0, 340.0);

    return Container(
      width: cardW,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: theme.headerColor.withValues(alpha: 0.4),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bandı ──────────────────────────────
            _CardHeader(theme: theme),

            // ── Kart gövdesi ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kart metni
                  Text(
                    card.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (badge != null) ...[
                    const SizedBox(height: 16),
                    // Etki badge'i
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: badge!.color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: badge!.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        badge!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Tamam butonu
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.headerColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'TAMAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Alt dekoratif çizgi ────────────────────────
            Container(height: 6, color: theme.headerColor),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header bandı
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.theme});
  final _CardTheme theme;

  @override
  Widget build(BuildContext context) {
    final isSans = theme.headerText == 'ŞANS';

    return Container(
      color: theme.headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSans) ...[
            // Şans: büyük "?" solda + sağda
            _HeaderSymbol(symbol: '?', size: 28),
            const SizedBox(width: 10),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                theme.headerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isSans)
                const Text(
                  'KARTI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
            ],
          ),
          if (isSans) ...[
            const SizedBox(width: 10),
            _HeaderSymbol(symbol: '?', size: 28),
          ] else ...[
            const SizedBox(width: 10),
            const Text('📦', style: TextStyle(fontSize: 28)),
          ],
        ],
      ),
    );
  }
}

class _HeaderSymbol extends StatelessWidget {
  const _HeaderSymbol({required this.symbol, required this.size});
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
