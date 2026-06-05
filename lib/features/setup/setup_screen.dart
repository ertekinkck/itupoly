import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/glass_card.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

class _Slot {
  _Slot(this.name, this.pawn, this.isBot);
  String name;
  PawnType pawn;
  bool isBot;
}

/// Oyun Kurulumu — oyuncu sayısı, isim, piyon, bot ayarı.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final List<_Slot> _slots = [
    _Slot('Sen', PawnType.ari, false),
    _Slot('Bot Pergel', PawnType.pergel, true),
  ];

  PawnType _firstFreePawn() {
    final taken = _slots.map((s) => s.pawn).toSet();
    return PawnType.values.firstWhere((p) => !taken.contains(p));
  }

  void _add() {
    if (_slots.length >= 6) return;
    setState(() {
      final pawn = _firstFreePawn();
      _slots.add(_Slot('Bot ${PawnVisuals.labelOf(pawn)}', pawn, true));
    });
  }

  void _remove(int i) {
    if (_slots.length <= 2) return;
    setState(() => _slots.removeAt(i));
  }

  Future<void> _pickPawn(int i) async {
    final taken = {
      for (var k = 0; k < _slots.length; k++)
        if (k != i) _slots[k].pawn,
    };
    final picked = await showDialog<PawnType>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.bgElevated,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Piyon seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final p in PawnType.values)
                    Opacity(
                      opacity: taken.contains(p) ? 0.25 : 1,
                      child: IgnorePointer(
                        ignoring: taken.contains(p),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context, p),
                              borderRadius: BorderRadius.circular(40),
                              child: PawnIcon(
                                p,
                                size: 52,
                                selected: _slots[i].pawn == p,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: Text(
                                PawnVisuals.labelOf(p),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _slots[i].pawn = picked);
  }

  void _start() {
    final setups = [
      for (final s in _slots)
        PlayerSetup(
          name: s.name.trim().isEmpty ? 'Oyuncu' : s.name.trim(),
          pawn: s.pawn,
          isBot: s.isBot,
        ),
    ];
    ref.read(gameControllerProvider.notifier).startNew(setups);
    context.go('/oyun');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  _Header(onBack: () => context.go('/')),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _slots.length; i++) ...[
                            _PlayerRow(
                              slot: _slots[i],
                              index: i,
                              canRemove: _slots.length > 2,
                              onPickPawn: () => _pickPawn(i),
                              onRemove: () => _remove(i),
                              onNameChanged: (v) => _slots[i].name = v,
                              onBotChanged: (v) =>
                                  setState(() => _slots[i].isBot = v),
                            ),
                            const SizedBox(height: AppSpace.md),
                          ],
                          const SizedBox(height: AppSpace.sm),
                          SizedBox(
                            width: double.infinity,
                            child: SecondaryButton(
                              label: 'Oyuncu ekle',
                              icon: Icons.add_rounded,
                              onPressed: _slots.length < 6 ? _add : null,
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          PrimaryButton(
                            label: 'Oyunu Başlat',
                            icon: Icons.sports_esports_rounded,
                            expand: true,
                            onPressed: _start,
                          ),
                        ],
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.md,
        AppSpace.lg,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpace.sm),
          const Text(
            'Oyun Kurulumu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.slot,
    required this.index,
    required this.canRemove,
    required this.onPickPawn,
    required this.onRemove,
    required this.onNameChanged,
    required this.onBotChanged,
  });

  final _Slot slot;
  final int index;
  final bool canRemove;
  final VoidCallback onPickPawn;
  final VoidCallback onRemove;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onBotChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          InkWell(
            onTap: onPickPawn,
            borderRadius: BorderRadius.circular(30),
            child: PawnIcon(slot.pawn, size: 46),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: TextFormField(
              initialValue: slot.name,
              onChanged: onNameChanged,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'İsim',
              ),
            ),
          ),
          Column(
            children: [
              Text(
                slot.isBot ? 'Bot' : 'İnsan',
                style: TextStyle(
                  fontSize: 11,
                  color: slot.isBot
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
              Switch(
                value: slot.isBot,
                activeThumbColor: AppColors.accent,
                onChanged: onBotChanged,
              ),
            ],
          ),
          IconButton(
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textFaint,
          ),
        ],
      ),
    );
  }
}
