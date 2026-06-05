import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/brand_mark.dart';
import 'package:itupoly/widgets/primary_button.dart';

/// Ana Menü — logo, Yeni Oyun, Devam Et, Nasıl Oynanır.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSave = ref.watch(hasSaveProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpace.xl),
                    const BrandMark(size: 1.1),
                    const SizedBox(height: AppSpace.sm),
                    const Text(
                      'Kampüsü ele geçir, rakiplerini mezun etme.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    PrimaryButton(
                      label: 'Yeni Oyun',
                      icon: Icons.play_arrow_rounded,
                      expand: true,
                      onPressed: () => context.go('/kurulum'),
                    ),
                    const SizedBox(height: AppSpace.md),
                    hasSave.maybeWhen(
                      data: (has) => has
                          ? _MenuButton(
                              label: 'Devam Et',
                              icon: Icons.history_rounded,
                              onPressed: () async {
                                final ok = await ref
                                    .read(gameControllerProvider.notifier)
                                    .resume();
                                if (ok && context.mounted) {
                                  context.go('/oyun');
                                }
                              },
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpace.md),
                    _MenuButton(
                      label: 'Nasıl Oynanır',
                      icon: Icons.help_outline_rounded,
                      onPressed: () => context.go('/nasil-oynanir'),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    const Text(
                      'Pass & play • 2–6 oyuncu • bota karşı',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SecondaryButton(label: label, icon: icon, onPressed: onPressed),
    );
  }
}
