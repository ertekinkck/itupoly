import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itupoly/app/theme/tokens.dart';

/// İTÜpoly marka kimliği — altın arı amblemi + kelime markası.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 1, this.vertical = true, super.key});

  /// Ölçek çarpanı.
  final double size;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final emblem = Container(
      width: 84 * size,
      height: 84 * size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * size),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 28 * size,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * size),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFFB07E1E)],
              ),
            ),
            child: Icon(
              Icons.hive_rounded,
              size: 44 * size,
              color: AppColors.bg,
            ),
          ),
        ),
      ),
    );

    final wordmark = RichText(
      text: TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 34 * size,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.textPrimary,
        ),
        children: const [
          TextSpan(text: 'İTÜ'),
          TextSpan(
            text: 'poly',
            style: TextStyle(color: AppColors.accent),
          ),
        ],
      ),
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblem,
          SizedBox(height: AppSpace.md * size),
          wordmark,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        SizedBox(width: AppSpace.md * size),
        wordmark,
      ],
    );
  }
}
