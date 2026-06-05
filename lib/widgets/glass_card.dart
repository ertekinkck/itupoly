import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// Bulanık (blur) cam yüzey — premium hissin temel kabı.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.radius = AppRadius.card,
    this.blur = 20,
    this.fill = AppColors.glassFill,
    this.border = AppColors.glassBorder,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color fill;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: fill,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: border),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
