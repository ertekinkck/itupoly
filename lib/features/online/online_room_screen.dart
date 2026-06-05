import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/brand_mark.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/primary_button.dart';

/// `/oda/:kod` derin bağlantısı — online lobi (Faz 5 iskeleti).
///
/// Online çok oyunculu henüz aktif değil; bu ekran paylaşılan kodu gösterir ve
/// kullanıcıyı pass & play'e yönlendirir. Lockstep mimarisi hazır
/// (bkz. ONLINE.md + online_transport.dart).
class OnlineRoomScreen extends StatelessWidget {
  const OnlineRoomScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: AppSpace.xl),
                    GlassCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.wifi_tethering_rounded,
                            color: AppColors.accent,
                            size: 32,
                          ),
                          const SizedBox(height: AppSpace.sm),
                          const Text(
                            'Online yakında',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            'Oda kodu: $code\n\nCanlı çok oyunculu mod '
                            'hazırlanıyor. Şimdilik aynı cihazda pass & play '
                            'oynayabilirsin.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    PrimaryButton(
                      label: 'Pass & Play Başlat',
                      icon: Icons.sports_esports_rounded,
                      expand: true,
                      onPressed: () => context.go('/kurulum'),
                    ),
                    const SizedBox(height: AppSpace.md),
                    SecondaryButton(
                      label: 'Ana Menü',
                      onPressed: () => context.go('/'),
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
