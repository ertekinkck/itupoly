import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/glass_card.dart';

/// Onboarding — kısa kural rehberi.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  static const _sections = <({IconData icon, String title, String body})>[
    (
      icon: Icons.flag_rounded,
      title: 'Amaç',
      body:
          'Fakülteleri, yurtları ve kampüs binalarını satın al; üstüne '
          'derslik ve amfi inşa et; rakiplerinden kira topla. Son ayakta '
          'kalan kazanır — diğerlerini iflas ettir.',
    ),
    (
      icon: Icons.casino_rounded,
      title: 'Sıra akışı',
      body:
          'Zar at, piyonun ilerlesin. Boş bir kareye gelirsen satın '
          'alabilirsin (almazsan bankada kalır). Başkasının karesine '
          'gelirsen kira ödersin. Çift atarsan tekrar atarsın.',
    ),
    (
      icon: Icons.home_work_rounded,
      title: 'Tekel ve inşaat',
      body:
          'Bir renk grubunun tüm karelerine sahip olursan tekel kurarsın: '
          'boş arsada kira ikiye katlanır. Eşit inşaat kuralıyla derslik '
          '(1–4) ve amfi dikerek kirayı katlarsın.',
    ),
    (
      icon: Icons.account_balance_rounded,
      title: 'İpotek',
      body:
          'Nakit sıkışınca kareyi ipotek edip yarı fiyatını alırsın; geri '
          'almak %10 faizli. İpotekli karede kira işlemez. Önce gruptaki '
          'derslikleri satmalısın.',
    ),
    (
      icon: Icons.gavel_rounded,
      title: 'Disiplin Kurulu',
      body:
          'Disipline Sevk! köşesine gelince ya da üç kez üst üste çift '
          'atınca kurula gidersin. Çıkmak için: 50₭ ceza, çift zar (3 deneme) '
          'ya da Af Kartı.',
    ),
    (
      icon: Icons.emoji_events_rounded,
      title: 'Kazanma',
      body:
          'Borcunu ödeyemeyen oyuncu ipotek/satışla nakit yaratmalı; '
          'yapamazsa iflas eder ve varlıkları alacaklıya geçer. Tek kişi '
          'kalınca oyun biter.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.sm,
                      AppSpace.md,
                      AppSpace.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        const Text(
                          'Nasıl Oynanır',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      itemCount: _sections.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpace.md),
                      itemBuilder: (context, i) {
                        final s = _sections[i];
                        return GlassCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(s.icon, color: AppColors.accent),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xs),
                                    Text(
                                      s.body,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
