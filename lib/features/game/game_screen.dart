import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/features/game/board/game_board.dart';
import 'package:itupoly/features/game/fx/card_draw_overlay.dart';
import 'package:itupoly/features/game/fx/money_flow_overlay.dart';
import 'package:itupoly/features/game/fx/screen_shake.dart';
import 'package:itupoly/features/game/hud/center_board_overlay.dart';
import 'package:itupoly/features/game/hud/active_tile_panel.dart';
import 'package:itupoly/features/game/hud/player_strip.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly/features/game/sheets/property_sheet.dart';
import 'package:itupoly/widgets/app_background.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly/widgets/primary_button.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Ana oyun ekranı — responsive (telefon / tablet / desktop).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static bool disableIntro = false;

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
  bool _isAnimating = false;
  Timer? _animTimer;

  /// Sıra değişim ekranı için alanlar
  Timer? _turnOverlayTimer;
  bool _showTurnOverlay = false;
  int? _turnPlayerId;

  /// Kart overlay: piyon animasyonu bitene kadar bekletir.
  Timer? _pendingCardTimer;
  /// 3B'den 'idle' sinyali gelene kadar bekleyen şans/kampüs kartı.
  GameCard? _pendingCard;
  bool _cardShown = false;
  /// Şu an ekranda gösterilen kart (CardDrawOverlay için).
  GameCard? _activeCard;

  /// Para akışı animasyonu — aktif olan
  MoneyFlowEvent? _moneyFlowEvent;
  int _moneyFlowNonce = 0;
  /// Piyon animasyonu / kart overlay bitmesini bekleyen para efekti
  MoneyFlowEvent? _pendingMoneyFlow;

  /// Çift zar bannerı
  bool _showDoublesBanner = false;
  Timer? _doublesBannerTimer;

  /// Hapse gönderilme efekti
  bool _showJailFlash = false;
  bool _pendingJailFlash = false;

  /// İflas efekti
  bool _showBankruptcyFlash = false;
  bool _screenShaking = false;

  /// Piyon animasyonunun bitmesi beklenen mutlak zaman.
  DateTime? _animEndTime;

  /// Kart harekete neden olduğunda board3d'ye gönderilen geçici durum:
  /// piyonu kart karesinde tutar, kart kapatılınca gerçek son konum gönderilir.
  GameState? _boardDisplayOverride;

  void _startAnimTimer(int ms) {
    _animTimer?.cancel();
    _animEndTime = DateTime.now().add(Duration(milliseconds: ms));
    _animTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) _onAnimationComplete();
    });
  }

  @override
  void initState() {
    super.initState();
    if (!GameScreen.disableIntro) {
      _isAnimating = true;
      _startAnimTimer(2800);
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _turnOverlayTimer?.cancel();
    _pendingCardTimer?.cancel();
    _doublesBannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (next == null) return;
      if (next.state.phase == TurnPhase.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/sonuc');
        });
      }

      final current = next.state.currentPlayer;
      final isTurnChange = _lastSeenPlayerId != null && _lastSeenPlayerId != current.id;
      if (isTurnChange) {
        _triggerTurnOverlay(current.id);
      }

      _maybePrivacyCover(next);
      _maybeShowDice(next);
      _maybeShowCard(next);
      _maybeShowMoneyFlow(next);
      _maybeShowJailEffect(next);
      _maybeShowBankruptcyEffect(next);

      _lastSeenPlayerId = current.id;
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
      onAnimEvent: _onAnimEvent,
    );
    final cover =
        _coverPlayerId != null && _coverPlayerId == s.currentPlayer.id;

    return Scaffold(
      body: AppBackground(
        child: ScreenShake(
          shaking: _screenShaking,
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(turn: s.turnCount),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final isLandscape = c.maxWidth > c.maxHeight;
                          final wide = c.maxWidth >= AppBreakpoints.tablet || isLandscape;
                          if (wide) {
                            return _WideLayout(
                              session: session,
                              board: board,
                              isAnimating: _isAnimating,
                            );
                          }
                          return _NarrowLayout(
                            session: session,
                            board: board,
                            isAnimating: _isAnimating,
                          );
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
              if (!cover && _showTurnOverlay && _turnPlayerId != null)
                _TurnChangeOverlay(
                  name: s.playerById(_turnPlayerId!).name,
                  pawn: s.playerById(_turnPlayerId!).pawn,
                ),
              // --- Para akışı animasyonu (kira, satın alma, maaş, vb.) ---
              if (_moneyFlowEvent != null)
                MoneyFlowOverlay(
                  key: ValueKey(_moneyFlowNonce),
                  event: _moneyFlowEvent!,
                  onDone: () {
                    if (mounted) setState(() => _moneyFlowEvent = null);
                  },
                ),
              // --- Çift zar flash overlay (ekran ortası) ---
              if (_showDoublesBanner)
                const _DoublesFlashOverlay(),
              // --- Hapis efekti ---
              if (_showJailFlash)
                JailFlashOverlay(key: UniqueKey()),
              // --- İflas efekti ---
              if (_showBankruptcyFlash)
                BankruptcyFlashOverlay(key: UniqueKey()),
              // --- Monopoly tarzı kart overlay ---
              if (_activeCard != null)
                CardDrawOverlay(
                  key: ValueKey(_activeCard!.id * 100 + _activeCard!.deck.index),
                  card: _activeCard!,
                  onDone: () {
                    if (mounted) {
                      setState(() => _activeCard = null);
                      _flushPendingEffects();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerTurnOverlay(int playerId) {
    _turnOverlayTimer?.cancel();
    setState(() {
      _turnPlayerId = playerId;
      _showTurnOverlay = true;
    });
    _turnOverlayTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showTurnOverlay = false;
        });
      }
    });
  }

  void _maybeShowDice(GameSession next) {
    DiceRolled? rolled;
    for (final e in next.lastEvents) {
      if (e is DiceRolled) rolled = e;
    }
    if (rolled == null) return;
    final diceSum = rolled.d1 + rolled.d2;
    // Fallback zamanlayıcı (2B veya JS sinyali gelmezse):
    // Gerçek JS hızı ~278ms/kare + 0.8s hold + ~1s top-view tamponu.
    final pawnMs = diceSum * 280;
    final animMs = 1600 + pawnMs + 1200; // güvenli üst sınır
    setState(() {
      _diceD1 = rolled!.d1;
      _diceD2 = rolled.d2;
      _diceNonce++;
      _isAnimating = true;
      _pendingCard = null;
      _cardShown = false;
    });
    _startAnimTimer(animMs);
    // Not: çift banner, JS 'diceSettled' sinyali ile tetiklenir (_onAnimEvent).
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

    // Kartı sakla; 3B 'idle' sinyali veya fallback zamanlayıcı açacak.
    setState(() {
      _pendingCard = card;
      _cardShown = false;
    });

    // Fallback: JS sinyali gelmezse (2B/test veya gecikme) animEndTime + 500ms sonra aç.
    _pendingCardTimer?.cancel();
    final endTime = _animEndTime;
    final now = DateTime.now();
    final delay = endTime != null && endTime.isAfter(now)
        ? endTime.difference(now) + const Duration(milliseconds: 500)
        : const Duration(milliseconds: 800); // 2B'de makul minimum bekleme
    _pendingCardTimer = Timer(delay, () {
      _pendingCardTimer = null;
      _showPendingCardIfReady();
    });
  }

  void _showPendingCardIfReady() {
    if (!mounted) return;
    if (_cardShown) return;
    if (_coverPlayerId != null) return;
    final card = _pendingCard;
    if (card == null) return;
    setState(() {
      _cardShown = true;
      _pendingCard = null;
      _activeCard = card;
    });
  }

  /// 3B sahneden gelen animasyon sinyalleri.
  void _onAnimEvent(String kind) {
    if (!mounted) return;
    switch (kind) {
      case 'diceSettled':
        if ((_diceD1 ?? 0) == (_diceD2 ?? 0) && (_diceD1 ?? 0) > 0) {
          _doublesBannerTimer?.cancel();
          setState(() => _showDoublesBanner = true);
          _doublesBannerTimer = Timer(const Duration(milliseconds: 1800), () {
            if (mounted) setState(() => _showDoublesBanner = false);
          });
        }
      case 'idle':
        // JS sinyali geldi — fallback timer'ı iptal et, 650ms kamera tamponu bekle.
        _animTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          _onAnimationComplete();
        });
    }
  }

  /// Piyon + zar animasyonu tamamlandığında çağrılır (JS sinyali veya fallback).
  /// Bekleyen tüm efektleri sırayla gösterir.
  void _onAnimationComplete() {
    if (!_isAnimating) return; // çift çağrıya karşı guard
    setState(() => _isAnimating = false);

    _pendingCardTimer?.cancel();
    _showPendingCardIfReady();

    // Kart açıksa efektleri kart kapanınca göster (card onDone → _flushPendingEffects).
    if (_activeCard != null) return;

    _flushPendingEffects();
  }

  /// Kuyrukta bekleyen görsel efektleri sırayla gösterir.
  /// Hem animasyon bittikten hem de kart kapatıldıktan sonra çağrılır.
  void _flushPendingEffects() {
    if (_pendingJailFlash) {
      _pendingJailFlash = false;
      _triggerJailEffect();
    }
    if (_pendingMoneyFlow != null) {
      final flow = _pendingMoneyFlow!;
      _pendingMoneyFlow = null;
      setState(() {
        _moneyFlowEvent = flow;
        _moneyFlowNonce++;
      });
    }
  }

  void _maybeShowJailEffect(GameSession next) {
    final hasJail = next.lastEvents.any((e) => e is SentToDisiplin);
    if (!hasJail) return;
    // Karttan geliyorsa (kart overlay açıklanacak), jail flash gösterme.
    if (next.lastEvents.any((e) => e is CardDrawn)) return;
    // Piyon animasyonu sürüyorsa kuyruğa al.
    if (next.lastEvents.any((e) => e is DiceRolled)) {
      _pendingJailFlash = true;
    } else {
      _triggerJailEffect();
    }
  }

  void _triggerJailEffect() {
    setState(() {
      _showJailFlash = true;
      _screenShaking = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showJailFlash = false);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _screenShaking = false);
    });
  }

  void _maybeShowBankruptcyEffect(GameSession next) {
    final hasBankrupt = next.lastEvents.any((e) => e is PlayerBankrupted);
    if (!hasBankrupt) return;
    setState(() {
      _showBankruptcyFlash = true;
      _screenShaking = true;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showBankruptcyFlash = false);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _screenShaking = false);
    });
  }

  /// Para değişimi içeren event'leri tarayıp MoneyFlowOverlay'i tetikler.
  ///
  /// Kurallar:
  ///  • DiceRolled aynı batch'deyse → piyon animasyonu bitmesini bekle (kuyruğa al).
  ///  • CardDrawn aynı batch'deyse → kart overlay kapanmasını bekle (kuyruğa al).
  ///  • İkisi de yoksa (ör. mustLiquidate borcunu ödeme) → hemen göster.
  void _maybeShowMoneyFlow(GameSession next) {
    final players = next.state.players;

    String playerName(int id) {
      final p = players.where((p) => p.id == id);
      return p.isEmpty ? 'Oyuncu $id' : p.first.name;
    }

    MoneyFlowEvent? found;
    for (final e in next.lastEvents) {
      if (e is RentPaid) {
        found = MoneyFlowEvent(
          type: MoneyFlowType.rentPaid,
          amount: e.amount,
          fromName: playerName(e.fromId),
          toName: playerName(e.toId),
          tileName: boardTr[e.tileIndex].name,
        );
        break;
      }
      if (e is PropertyBought) {
        found = MoneyFlowEvent(
          type: MoneyFlowType.propertyBought,
          amount: e.price,
          fromName: playerName(e.playerId),
          tileName: boardTr[e.tileIndex].name,
        );
        break;
      }
      if (e is SalaryPaid) {
        found = MoneyFlowEvent(
          type: MoneyFlowType.salaryPaid,
          amount: e.amount,
          fromName: playerName(e.playerId),
        );
        break;
      }
      if (e is TaxPaid) {
        found = MoneyFlowEvent(
          type: MoneyFlowType.taxPaid,
          amount: e.amount,
          fromName: playerName(e.playerId),
        );
        break;
      }
      if (e is MoneyChanged) {
        if (e.reason == 'Disiplin cezası') break;
        found = MoneyFlowEvent(
          type: e.delta >= 0 ? MoneyFlowType.cardGain : MoneyFlowType.cardLoss,
          amount: e.delta.abs(),
          fromName: e.delta < 0 ? playerName(e.playerId) : null,
          toName: e.delta >= 0 ? playerName(e.playerId) : null,
        );
        break;
      }
      if (e is MoneyTransferred) {
        found = MoneyFlowEvent(
          type: MoneyFlowType.playerTransfer,
          amount: e.amount,
          fromName: playerName(e.fromId),
          toName: playerName(e.toId),
        );
        break;
      }
    }

    if (found == null) return;

    final needsQueue = next.lastEvents.any((e) => e is DiceRolled) ||
        next.lastEvents.any((e) => e is CardDrawn);

    if (needsQueue) {
      // Kuyruğa al; _flushPendingEffects (animasyon/kart bittikten sonra) gösterecek.
      _pendingMoneyFlow = found;
    } else {
      setState(() {
        _moneyFlowEvent = found;
        _moneyFlowNonce++;
      });
    }
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
  const _NarrowLayout({
    required this.session,
    required this.board,
    required this.isAnimating,
  });

  final GameSession session;
  final Widget board;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tahta tam alanı kaplar
        Positioned.fill(child: board),
        // Oyuncu bilgileri tahtanın üstüne floating bar olarak bindiriliyor
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _FloatingPlayerBar(state: session.state),
        ),
        // Merkez aksiyon butonları
        Center(
          child: CenterBoardOverlay(
            state: session.state,
            visible: !isAnimating,
          ),
        ),
      ],
    );
  }
}

/// Mobil için oyuncu şeridini yarı saydam cam bar içine sarar.
class _FloatingPlayerBar extends StatelessWidget {
  const _FloatingPlayerBar({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          height: 64,
          color: Colors.black.withValues(alpha: 0.50),
          child: PlayerStrip(state: state),
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.session,
    required this.board,
    required this.isAnimating,
  });

  final GameSession session;
  final Widget board;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: board),
                CenterBoardOverlay(
                  state: session.state,
                  visible: !isAnimating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width < 720 ? 240 : 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlayerStrip(state: session.state, vertical: true),
                const SizedBox(height: AppSpace.md),
                ActiveTilePanel(state: session.state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TurnChangeOverlay extends StatelessWidget {
  const _TurnChangeOverlay({
    required this.name,
    required this.pawn,
  });

  final String name;
  final PawnType pawn;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PawnIcon(pawn, size: 80, selected: true),
                const SizedBox(height: AppSpace.lg),
                const Text(
                  'SIRA KİMDE?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ekran ortasında büyük çift zar flash'ı — zarlar durduktan sonra gösterilir.
class _DoublesFlashOverlay extends StatefulWidget {
  const _DoublesFlashOverlay();

  @override
  State<_DoublesFlashOverlay> createState() => _DoublesFlashOverlayState();
}

class _DoublesFlashOverlayState extends State<_DoublesFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFCC0025), Color(0xFFFF1744), Color(0xFFFF5C7A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAACC0025),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎲', style: TextStyle(fontSize: 40)),
                        SizedBox(width: 12),
                        Text(
                          'ÇİFT!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('🎲', style: TextStyle(fontSize: 40)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'TEKRAR AT',
                      style: TextStyle(
                        color: Color(0xFFFFE0E6),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
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
