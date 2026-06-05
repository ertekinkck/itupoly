import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Tüm ekranların ortak premium karanlık zemini — hafif radyal altın parıltı.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.7),
          radius: 1.3,
          colors: [Color(0xFF15203A), AppColors.bg],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: AppColors.accent.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: AppColors.positive.withValues(alpha: 0.06)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
