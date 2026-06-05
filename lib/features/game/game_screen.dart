import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/board/game_board.dart';
import 'package:itupoly/features/game/fx/dice_3d_overlay.dart';
import 'package:itupoly/features/game/hud/action_bar.dart';
import 'package:itupoly/features/game/hud/event_log_panel.dart';
import 'package:itupoly/features/game/hud/player_strip.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/features/game/sheets/card_modal.dart';
import 'package:itupoly/features/game/sheets/property_sheet.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Ana oyun ekranı — responsive (telefon / tablet / desktop).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Sıra perdesi gösterilen oyuncu (pass-and-play gizliliği).
  int? _coverPlayerId;

  /// Sıra değişimini saptamak için son görülen oyuncu.
  int? _lastSeenPlayerId;

  /// Son atılan zar (3B overlay için) + her atışta artan anahtar.
  int? _diceD1;
  int? _diceD2;
  int _diceNonce = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (next == null) return;
      if (next.state.phase == TurnPhase.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/sonuc');
        });
      }
      _maybePrivacyCover(next);
      _maybeShowDice(next);
      _maybeShowCard(next);
    });

    final session = ref.watch(gameControllerProvider);
    if (session == null) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ana Menü'),
            ),
          ),
        ),
      );
    }

    final s = session.state;
    final board = GameBoard(
      state: s,
      onTapTile: (i) => showPropertySheet(context, i),
    );
    final cover =
        _coverPlayerId != null && _coverPlayerId == s.currentPlayer.id;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(turn: s.turnCount),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final wide = c.maxWidth >= AppBreakpoints.tablet;
                        if (wide) {
                          return _WideLayout(session: session, board: board);
                        }
                        return _NarrowLayout(session: session, board: board);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (cover)
              _PrivacyCover(
                name: s.currentPlayer.name,
                pawn: s.currentPlayer.pawn,
                onReady: () => setState(() => _coverPlayerId = null),
              ),
            if (_diceD1 != null && _diceD2 != null)
              Dice3DOverlay(
                key: ValueKey(_diceNonce),
                d1: _diceD1!,
                d2: _diceD2!,
                onDone: () {
                  if (mounted) setState(() => _diceD1 = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _maybeShowDice(GameSession next) {
    DiceRolled? rolled;
    for (final e in next.lastEvents) {
      if (e is DiceRolled) rolled = e;
    }
    if (rolled == null) return;
    setState(() {
      _diceD1 = rolled!.d1;
      _diceD2 = rolled.d2;
      _diceNonce++;
    });
  }

  /// İki+ insan oyunda, sıra yeni bir insana geçince "telefonu ver" perdesi.
  void _maybePrivacyCover(GameSession next) {
    final s = next.state;
    final current = s.currentPlayer;
    final humans = s.players.where((p) => !p.isBot).length;
    if (_lastSeenPlayerId != null &&
        _lastSeenPlayerId != current.id &&
        !current.isBot &&
        humans >= 2 &&
        s.phase != TurnPhase.gameOver) {
      setState(() => _coverPlayerId = current.id);
    }
    _lastSeenPlayerId = current.id;
  }

  void _maybeShowCard(GameSession next) {
    CardDrawn? drawn;
    for (final e in next.lastEvents) {
      if (e is CardDrawn) drawn = e;
    }
    if (drawn == null) return;
    final drawer = next.state.playerById(drawn.playerId);
    if (drawer.isBot) return; // botlar için modal gösterme
    if (_coverPlayerId != null) return; // perde açıkken kartı erteleme
    final card = cardOf(drawn.deck, drawn.cardId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showCardModal(context, card);
    });
  }
}

/// Pass-and-play gizlilik perdesi — "Telefonu X'e ver".
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover({
    required this.name,
    required this.pawn,
    required this.onReady,
  });

  final String name;
  final PawnType pawn;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PawnIcon(pawn, size: 72, selected: true),
                const SizedBox(height: AppSpace.lg),
                Text(
                  "Telefonu $name'e ver",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  'Sıra sende. Hazır olduğunda başla.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpace.xl),
                PrimaryButton(
                  label: 'Hazırım',
                  icon: Icons.visibility_rounded,
                  onPressed: onReady,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.turn});
  final int turn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _confirmExit(context),
            icon: const Icon(Icons.menu_rounded),
          ),
          const Spacer(),
          Text(
            'İTÜpoly',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text('Tur $turn', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Ana menüye dön?'),
        content: const Text(
          'Oyun otomatik kaydedildi; daha sonra devam '
          'edebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.session, required this.board});
  final GameSession session;
  final Widget board;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: PlayerStrip(state: session.state),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: board,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(AppSpace.md),
          child: ActionBar(),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.session, required this.board});
  final GameSession session;
  final Widget board;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: board,
          ),
        ),
        SizedBox(
          width: 340,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              children: [
                PlayerStrip(state: session.state, vertical: true),
                const SizedBox(height: AppSpace.md),
                Expanded(child: EventLogPanel(log: session.log)),
                const SizedBox(height: AppSpace.md),
                const ActionBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
