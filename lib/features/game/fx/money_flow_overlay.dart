import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Para akışı türü — ekran tasarımını belirler.
enum MoneyFlowType {
  rentPaid,
  propertyBought,
  salaryPaid,
  taxPaid,
  cardGain,
  cardLoss,
  playerTransfer,
}

/// Para akışı veri nesnesi — overlay'e iletilir.
class MoneyFlowEvent {
  const MoneyFlowEvent({
    required this.type,
    required this.amount,
    this.fromName,
    this.toName,
    this.tileName,
  });

  final MoneyFlowType type;
  final int amount;
  final String? fromName;
  final String? toName;
  final String? tileName;
}

// ---------------------------------------------------------------------------
// Tasarım yardımcıları
// ---------------------------------------------------------------------------

class _EventStyle {
  const _EventStyle({
    required this.bannerText,
    required this.bannerColor,
    required this.bannerTextColor,
    required this.emoji,
    required this.accentColor,
    required this.messageBuilder,
  });

  final String bannerText;
  final Color bannerColor;
  final Color bannerTextColor;
  final String emoji;
  final Color accentColor;
  final String Function(MoneyFlowEvent) messageBuilder;
}

_EventStyle _styleFor(MoneyFlowEvent e) {
  switch (e.type) {
    case MoneyFlowType.rentPaid:
      return _EventStyle(
        bannerText: 'KİRA ÖDEMESİ',
        bannerColor: const Color(0xFFE8195A),
        bannerTextColor: Colors.white,
        emoji: '🏠',
        accentColor: const Color(0xFFE8195A),
        messageBuilder: (e) {
          final tile = e.tileName != null ? '\n${e.tileName}' : '';
          return '${e.fromName ?? "?"} → ${e.toName ?? "?"}\n${e.amount}₭ kira$tile';
        },
      );
    case MoneyFlowType.propertyBought:
      return _EventStyle(
        bannerText: 'SATIN ALINDI!',
        bannerColor: const Color(0xFF1976D2),
        bannerTextColor: Colors.white,
        emoji: '🏢',
        accentColor: const Color(0xFF1976D2),
        messageBuilder: (e) =>
            '${e.fromName ?? "?"}\n${e.tileName ?? "mülk"} aldı\n${e.amount}₭',
      );
    case MoneyFlowType.salaryPaid:
      return _EventStyle(
        bannerText: 'BURS!',
        bannerColor: const Color(0xFF2E7D32),
        bannerTextColor: Colors.white,
        emoji: '🎓',
        accentColor: const Color(0xFF2E7D32),
        messageBuilder: (e) =>
            "${e.fromName ?? "?"}\nBAŞLA'dan geçti!\n+${e.amount}₭",
      );
    case MoneyFlowType.taxPaid:
      return _EventStyle(
        bannerText: 'VERGİ!',
        bannerColor: const Color(0xFFB71C1C),
        bannerTextColor: Colors.white,
        emoji: '💸',
        accentColor: const Color(0xFFB71C1C),
        messageBuilder: (e) =>
            '${e.fromName ?? "?"}\nvergi ödedi\n${e.amount}₭',
      );
    case MoneyFlowType.cardGain:
      return _EventStyle(
        bannerText: 'KART KAZANCI!',
        bannerColor: const Color(0xFF388E3C),
        bannerTextColor: Colors.white,
        emoji: '🃏',
        accentColor: const Color(0xFF388E3C),
        messageBuilder: (e) =>
            '${e.toName ?? "?"}\n+${e.amount}₭ kazandı!',
      );
    case MoneyFlowType.cardLoss:
      return _EventStyle(
        bannerText: 'KART KAYBI',
        bannerColor: const Color(0xFFD32F2F),
        bannerTextColor: Colors.white,
        emoji: '🃏',
        accentColor: const Color(0xFFD32F2F),
        messageBuilder: (e) =>
            '${e.fromName ?? "?"}\n${e.amount}₭ ödedi',
      );
    case MoneyFlowType.playerTransfer:
      return _EventStyle(
        bannerText: 'TRANSFER',
        bannerColor: const Color(0xFF7B1FA2),
        bannerTextColor: Colors.white,
        emoji: '🔄',
        accentColor: const Color(0xFF7B1FA2),
        messageBuilder: (e) =>
            '${e.fromName ?? "?"} → ${e.toName ?? "?"}\n${e.amount}₭',
      );
  }
}

// ---------------------------------------------------------------------------
// Ana Overlay Widget
// ---------------------------------------------------------------------------

/// Monopoly Go tarzı para akışı overlay'i.
///
/// • Üstte ribbon/şerit banner ("KİRA ÖDEMESİ", "SATIN ALINDI!" vb.)
/// • Ortada büyük tutar ve mesaj balonu
/// • Uçan altın para parçacıkları
class MoneyFlowOverlay extends StatefulWidget {
  const MoneyFlowOverlay({
    required this.event,
    required this.onDone,
    super.key,
  });

  final MoneyFlowEvent event;
  final VoidCallback onDone;

  @override
  State<MoneyFlowOverlay> createState() => _MoneyFlowOverlayState();
}

class _MoneyFlowOverlayState extends State<MoneyFlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Faz aralıkları:
  // 0.0–0.15 → giriş (banner + kart aşağıdan yukarıya)
  // 0.15–0.75 → bekleme (görünür)
  // 0.75–1.0 → çıkış (yukarı uçar + solar)
  late final Animation<double> _enterAnim;
  late final Animation<double> _exitAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _particleAnim;

  static const _durationMs = 2800;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );

    _enterAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack),
    );

    _exitAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.78, 1.0, curve: Curves.easeIn),
    );

    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
    );

    _particleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _ctrl
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.event);
    final screenW = MediaQuery.of(context).size.width;
    final topPad = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final enterT = _enterAnim.value;
        final exitT = _exitAnim.value;

        // Giriş: aşağıdan yukarıya, çıkış: yukarıya doğru uçar
        final slideY = (1 - enterT) * 80 - exitT * 60;
        // Opaklık: giriş/çıkış
        final opacity = (enterT * (1 - exitT)).clamp(0.0, 1.0);
        final scale = 0.6 + 0.4 * _scaleAnim.value;

        return IgnorePointer(
          child: Stack(
            children: [
              // Hafif arka plan karartma
              Positioned.fill(
                child: Opacity(
                  opacity: (opacity * 0.45).clamp(0.0, 1.0),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Uçan para parçacıkları
              _ParticleLayer(
                progress: _particleAnim.value,
                accentColor: style.accentColor,
              ),

              // Ana içerik
              Positioned(
                top: topPad + 60,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, slideY),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: _MoneyFlowCard(
                        event: widget.event,
                        style: style,
                        screenW: screenW,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ana Kart Bileşeni
// ---------------------------------------------------------------------------

class _MoneyFlowCard extends StatelessWidget {
  const _MoneyFlowCard({
    required this.event,
    required this.style,
    required this.screenW,
  });

  final MoneyFlowEvent event;
  final _EventStyle style;
  final double screenW;

  @override
  Widget build(BuildContext context) {
    final cardW = screenW.clamp(280.0, 420.0);

    return Center(
      child: SizedBox(
        width: cardW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- Ribbon Banner ----
            _RibbonBanner(style: style),
            const SizedBox(height: 4),
            // ---- Mesaj Kartı ----
            _MessageCard(event: event, style: style),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ribbon Banner — "Rent due" tarzı şerit
// ---------------------------------------------------------------------------

class _RibbonBanner extends StatelessWidget {
  const _RibbonBanner({required this.style});
  final _EventStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sol üçgen kulak
        Positioned(
          left: 0,
          child: CustomPaint(
            painter: _RibbonEarPainter(
              color: style.bannerColor.withValues(alpha: 0.65),
              isLeft: true,
            ),
            size: const Size(20, 48),
          ),
        ),
        // Sağ üçgen kulak
        Positioned(
          right: 0,
          child: CustomPaint(
            painter: _RibbonEarPainter(
              color: style.bannerColor.withValues(alpha: 0.65),
              isLeft: false,
            ),
            size: const Size(20, 48),
          ),
        ),
        // Ana şerit gövdesi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                style.bannerColor,
                style.bannerColor.withValues(alpha: 0.85),
                style.bannerColor,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: style.bannerColor.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                style.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                style.bannerText,
                style: TextStyle(
                  color: style.bannerTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                style.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RibbonEarPainter extends CustomPainter {
  const _RibbonEarPainter({required this.color, required this.isLeft});
  final Color color;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RibbonEarPainter old) => false;
}

// ---------------------------------------------------------------------------
// Mesaj Kartı — büyük tutar + kiracı/ev sahibi bilgisi
// ---------------------------------------------------------------------------

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.event, required this.style});
  final MoneyFlowEvent event;
  final _EventStyle style;

  @override
  Widget build(BuildContext context) {
    // Para değişiminin "yönü" — kira/satın alma eksi, maaş/kart kazancı artı
    final isPositive = event.type == MoneyFlowType.salaryPaid ||
        event.type == MoneyFlowType.cardGain;
    final amountColor =
        isPositive ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    final amountSign = isPositive ? '+' : '-';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: style.accentColor.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: style.accentColor.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Büyük tutar satırı
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    amountSign,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${event.amount}',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '₭',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ayraç
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      style.accentColor.withValues(alpha: 0.4),
                      style.accentColor,
                      style.accentColor.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Detay satırları
              _buildDetail(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    switch (event.type) {
      case MoneyFlowType.rentPaid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFFE8195A),
              label: 'Ödeyen',
              value: event.fromName ?? '?',
            ),
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFF2E7D32),
              label: 'Alan',
              value: event.toName ?? '?',
            ),
            if (event.tileName != null) ...[
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.accent,
                label: 'Kare',
                value: event.tileName!,
              ),
            ],
          ],
        );

      case MoneyFlowType.propertyBought:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF1976D2),
              label: 'Satın Alan',
              value: event.fromName ?? '?',
            ),
            if (event.tileName != null) ...[
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.home_work_rounded,
                iconColor: AppColors.accent,
                label: 'Mülk',
                value: event.tileName!,
              ),
            ],
          ],
        );

      case MoneyFlowType.salaryPaid:
        return _DetailRow(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF2E7D32),
          label: 'Oyuncu',
          value: event.fromName ?? '?',
        );

      case MoneyFlowType.taxPaid:
        return _DetailRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFFB71C1C),
          label: 'Ödeyen',
          value: event.fromName ?? '?',
        );

      case MoneyFlowType.cardGain:
        return _DetailRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF388E3C),
          label: 'Kazanan',
          value: event.toName ?? '?',
        );

      case MoneyFlowType.cardLoss:
        return _DetailRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFFD32F2F),
          label: 'Ödeyen',
          value: event.fromName ?? '?',
        );

      case MoneyFlowType.playerTransfer:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFF7B1FA2),
              label: 'Gönderen',
              value: event.fromName ?? '?',
            ),
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFF2E7D32),
              label: 'Alan',
              value: event.toName ?? '?',
            ),
          ],
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Uçan Altın Para Parçacıkları
// ---------------------------------------------------------------------------

class _Coin {
  _Coin(math.Random rng)
      : x = 0.1 + rng.nextDouble() * 0.8,
        y = 0.35 + rng.nextDouble() * 0.45,
        vx = (rng.nextDouble() - 0.5) * 0.6,
        vy = -(0.35 + rng.nextDouble() * 0.6),
        size = 14.0 + rng.nextDouble() * 14.0,
        delay = rng.nextDouble() * 0.3,
        spin = (rng.nextDouble() - 0.5) * 12,
        symbol = _symbols[rng.nextInt(_symbols.length)];

  static const _symbols = ['💰', '✨', '💵', '⭐'];

  final double x, y, vx, vy, size, delay, spin;
  final String symbol;
}

class _ParticleLayer extends StatefulWidget {
  const _ParticleLayer({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  State<_ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<_ParticleLayer> {
  late final List<_Coin> _coins;

  @override
  void initState() {
    super.initState();
    _coins = List.generate(18, (_) => _Coin(math.Random()));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CoinPainter(
          coins: _coins,
          progress: widget.progress,
        ),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({required this.coins, required this.progress});

  final List<_Coin> coins;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final c in coins) {
      final localT = ((progress - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final eased = Curves.easeOutCubic.transform(localT);
      final x = (c.x + c.vx * eased) * size.width;
      // Parabolik: yukarı çıkar, yerçekimi
      final y = (c.y + c.vy * eased + 0.45 * eased * eased) * size.height;

      // Opaklık: giriş 0→0.3, çıkış 0.6→1
      final opacity = localT < 0.3
          ? localT / 0.3
          : localT > 0.6
              ? 1.0 - (localT - 0.6) / 0.4
              : 1.0;
      if (opacity <= 0) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.spin * eased);
      canvas.scale(opacity.clamp(0.0, 1.0));

      tp
        ..text = TextSpan(
          text: c.symbol,
          style: TextStyle(fontSize: c.size),
        )
        ..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.progress != progress;
}
