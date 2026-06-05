import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ekran sarsıntısı widget'ı — hapis/iflas animasyonları için.
///
/// [child] içeriği [shaking] true iken X ekseninde sallanır.
class ScreenShake extends StatefulWidget {
  const ScreenShake({
    required this.child,
    required this.shaking,
    this.intensity = 4.0,
    this.durationMs = 500,
    super.key,
  });

  final Widget child;
  final bool shaking;
  final double intensity;
  final int durationMs;

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _shakeX;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _shakeX = _buildShakeAnim();
  }

  Animation<double> _buildShakeAnim() {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: widget.intensity), weight: 1),
      TweenSequenceItem(tween: Tween(begin: widget.intensity, end: -widget.intensity), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -widget.intensity, end: widget.intensity), weight: 2),
      TweenSequenceItem(tween: Tween(begin: widget.intensity, end: -widget.intensity), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -widget.intensity, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ScreenShake old) {
    super.didUpdateWidget(old);
    if (widget.shaking && !old.shaking) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeX,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeX.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Hapishane flash overlay — kırmızı/mavi polis çakırı efekti.
class JailFlashOverlay extends StatefulWidget {
  const JailFlashOverlay({super.key});

  @override
  State<JailFlashOverlay> createState() => _JailFlashOverlayState();
}

class _JailFlashOverlayState extends State<JailFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // 4 faz: kırmızı → mavi → kırmızı → solar
        final t = _ctrl.value;
        Color color;
        double opacity;
        if (t < 0.25) {
          color = const Color(0xFFFF1744);
          opacity = (t / 0.25) * 0.35;
        } else if (t < 0.5) {
          color = const Color(0xFF2979FF);
          opacity = 0.35;
        } else if (t < 0.75) {
          color = const Color(0xFFFF1744);
          opacity = 0.35;
        } else {
          color = const Color(0xFF2979FF);
          opacity = (1 - (t - 0.75) / 0.25) * 0.35;
        }
        return Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: color.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

/// İflas flash overlay — kırmızı titreme efekti.
class BankruptcyFlashOverlay extends StatefulWidget {
  const BankruptcyFlashOverlay({super.key});

  @override
  State<BankruptcyFlashOverlay> createState() => _BankruptcyFlashOverlayState();
}

class _BankruptcyFlashOverlayState extends State<BankruptcyFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Sinüs dalgası ile kırmızı titreme
        final sinVal = math.sin(_ctrl.value * math.pi * 4).abs();
        final opacity = sinVal * (1 - _ctrl.value) * 0.4;
        return Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: const Color(0xFFD32F2F).withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}
