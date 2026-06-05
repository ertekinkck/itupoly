import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Kart çekme modalı — 3B flip animasyonlu.
Future<void> showCardModal(BuildContext context, GameCard card) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'kart',
    barrierColor: Colors.black54,
    transitionDuration: AppDuration.med,
    pageBuilder: (_, __, ___) => _CardDialog(card: card),
    transitionBuilder: (context, anim, _, child) {
      final turns = (1 - anim.value) * 0.5;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(turns * 3.14159),
        child: Opacity(opacity: anim.value.clamp(0, 1), child: child),
      );
    },
  );
}

class _CardDialog extends StatelessWidget {
  const _CardDialog({required this.card});
  final GameCard card;

  @override
  Widget build(BuildContext context) {
    final isSans = card.deck == DeckType.sans;
    final accent = isSans ? AppColors.accent : AppColors.positive;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSans ? Icons.help_rounded : Icons.inventory_2_rounded,
                color: accent,
                size: 44,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                isSans ? 'ŞANS' : 'KAMPÜS KARTI',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                card.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.4),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Tamam',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
