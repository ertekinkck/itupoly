import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/glass_card.dart';

/// Olay günlüğü paneli (desktop) — event-sourced mimarinin bedava çıktısı.
class EventLogPanel extends StatelessWidget {
  const EventLogPanel({required this.log, super.key});

  final List<String> log;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.article_rounded, size: 16, color: AppColors.accent),
              SizedBox(width: AppSpace.sm),
              Text(
                'Olay Günlüğü',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const Divider(color: AppColors.glassBorder, height: 1),
          Expanded(
            child: log.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz olay yok',
                      style: TextStyle(color: AppColors.textFaint),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    itemCount: log.length,
                    itemBuilder: (context, i) {
                      final line = log[log.length - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
