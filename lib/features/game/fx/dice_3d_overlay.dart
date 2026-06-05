import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Ekran ortasında 3B zar atma animasyonu (non-blocking overlay).
///
/// Atış sırasında zarlar yuvarlanır (eksenlerde döner, yüzler değişir), sonra
/// sonuca oturur ve toplam belirir. [onDone] bittiğinde çağrılır.
class Dice3DOverlay extends StatefulWidget {
  const Dice3DOverlay({
    required this.d1,
    required this.d2,
    required this.onDone,
    super.key,
  });

  final int d1;
  final int d2;
  final VoidCallback onDone;

  @override
  State<Dice3DOverlay> createState() => _Dice3DOverlayState();
}

class _Dice3DOverlayState extends State<Dice3DOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDouble = widget.d1 == widget.d2;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final scrim = t < 0.85 ? 0.45 : 0.45 * (1 - (t - 0.85) / 0.15);
          final settled = t > 0.72;
          final totalOpacity =
              ((t - 0.7) / 0.2).clamp(0.0, 1.0) *
              (t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15));
          return Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: scrim.clamp(0.0, 1.0)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Die(value: widget.d1, t: t, axis: 1),
                        const SizedBox(width: 24),
                        _Die(value: widget.d2, t: t, axis: -1),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: totalOpacity,
                      child: Column(
                        children: [
                          Text(
                            '${widget.d1 + widget.d2}',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                          if (isDouble && settled)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.accent),
                              ),
                              child: const Text(
                                'ÇİFT! Tekrar at',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Die extends StatelessWidget {
  const _Die({required this.value, required this.t, required this.axis});

  final int value;
  final double t;

  /// Dönüş yönü çeşitliliği (+1 / -1).
  final int axis;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    // Yuvarlanma: hızlı başlar, yavaşlayarak dinlenme açısına oturur.
    final spinT = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final remain = 1 - spinT;
    const restRx = -0.5;
    final restRy = 0.45 * axis;
    final rx = restRx + remain * (2 * math.pi * 2.6) * axis;
    final ry = restRy + remain * (2 * math.pi * 1.7);

    // Atış sırasında yüz titrer; oturunca gerçek değer.
    final settled = t > 0.72;
    final shownFace = settled ? value : ((t * 30 + axis).floor() % 6) + 1;

    // Pop: easeOutBack ile büyür, hafif sekme.
    final scale =
        0.55 +
        0.5 *
            Curves.easeOutBack.transform(
              (t * 1.6).clamp(0.0, 1.0),
            );

    return Transform.scale(
      scale: scale,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateX(rx)
          ..rotateY(ry),
        child: _DieFace(value: shownFace, size: size, glow: settled),
      ),
    );
  }
}

class _DieFace extends StatelessWidget {
  const _DieFace({
    required this.value,
    required this.size,
    required this.glow,
  });

  final int value;
  final double size;
  final bool glow;

  static const _pips = <int, List<Offset>>{
    1: [Offset(.5, .5)],
    2: [Offset(.28, .28), Offset(.72, .72)],
    3: [Offset(.28, .28), Offset(.5, .5), Offset(.72, .72)],
    4: [Offset(.3, .3), Offset(.7, .3), Offset(.3, .7), Offset(.7, .7)],
    5: [
      Offset(.28, .28),
      Offset(.72, .28),
      Offset(.5, .5),
      Offset(.28, .72),
      Offset(.72, .72),
    ],
    6: [
      Offset(.3, .26),
      Offset(.7, .26),
      Offset(.3, .5),
      Offset(.7, .5),
      Offset(.3, .74),
      Offset(.7, .74),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.15;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6D27A), AppColors.accent, Color(0xFFB07E1E)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFFFFE9B0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
          if (glow)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 24,
            ),
        ],
      ),
      child: Stack(
        children: [
          for (final p in _pips[value] ?? const <Offset>[])
            Positioned(
              left: p.dx * size - dot / 2,
              top: p.dy * size - dot / 2,
              child: Container(
                width: dot,
                height: dot,
                decoration: const BoxDecoration(
                  color: Color(0xFF20140A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
