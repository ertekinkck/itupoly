import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/theme.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Bakiyeyi animasyonlu sayan tabular kredi metni.
class AnimatedCredit extends StatelessWidget {
  const AnimatedCredit(
    this.amount, {
    this.size = 16,
    this.color,
    this.showSign = false,
    super.key,
  });

  final int amount;
  final double size;
  final Color? color;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: amount.toDouble(), end: amount.toDouble()),
      duration: AppDuration.med,
      builder: (context, value, _) {
        final v = value.round();
        final sign = showSign && v > 0 ? '+' : '';
        final c =
            color ??
            (showSign
                ? (v >= 0 ? AppColors.positive : AppColors.negative)
                : AppColors.textPrimary);
        return Text(
          '$sign$v$kCredit',
          style: creditStyle(context, size: size, color: c),
        );
      },
    );
  }
}

/// Önceki değerden yeni değere yumuşak geçişle sayan bakiye.
class RollingCredit extends StatefulWidget {
  const RollingCredit(this.amount, {this.size = 18, this.color, super.key});

  final int amount;
  final double size;
  final Color? color;

  @override
  State<RollingCredit> createState() => _RollingCreditState();
}

class _RollingCreditState extends State<RollingCredit> {
  late int _previous = widget.amount;

  @override
  void didUpdateWidget(RollingCredit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) _previous = oldWidget.amount;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previous.toDouble(), end: widget.amount.toDouble()),
      duration: AppDuration.slow,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '${value.round()}$kCredit',
        style: creditStyle(context, size: widget.size, color: widget.color),
      ),
    );
  }
}
