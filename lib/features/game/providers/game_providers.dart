import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI'nın izlediği oturum: motor state'i + son event'ler (FX) + olay günlüğü.
class GameSession {
  const GameSession({
    required this.state,
    this.lastEvents = const [],
    this.log = const [],
  });

  final GameState state;

  /// Son submit'in ürettiği event'ler (zar overlay, kart modalı, para uçuşu).
  final List<GameEvent> lastEvents;

  /// İnsan-okunur olay günlüğü (desktop paneli).
  final List<String> log;

  GameSession copyWith({
    GameState? state,
    List<GameEvent>? lastEvents,
    List<String>? log,
  }) => GameSession(
    state: state ?? this.state,
    lastEvents: lastEvents ?? this.lastEvents,
    log: log ?? this.log,
  );
}

const _saveKey = 'itupoly_save_v1';
const _botStepDelay = Duration(milliseconds: 750);

/// Oyun denetleyicisi — engine ile UI arasındaki tek köprü.
class GameController extends Notifier<GameSession?> {
  GameEngine? _engine;
  List<bool> _isBot = const [];
  List<PlayerSetup> _setups = const [];
  final List<PlayerAction> _history = [];
  int _seed = 0;
  bool _disposed = false;
  Timer? _botTimer;
  static const _bot = Bot();

  @override
  GameSession? build() {
    ref.onDispose(() {
      _disposed = true;
      _botTimer?.cancel();
    });
    return null;
  }

  bool get currentIsBot {
    final s = state;
    return s != null &&
        s.state.phase != TurnPhase.gameOver &&
        _isBot[s.state.currentPlayerIndex];
  }

  GameEngine get engine {
    final e = _engine;
    if (e == null) {
      throw StateError(
        'Oyun başlatılmadı; önce startNew() veya resume() çağır.',
      );
    }
    return e;
  }

  /// Yeni oyun başlat.
  void startNew(List<PlayerSetup> setups, {int? seed}) {
    _seed = seed ?? Random().nextInt(0x7FFFFFFF);
    _engine = GameEngine(Random(_seed));
    _setups = setups;
    _isBot = setups.map((s) => s.isBot).toList();
    _history.clear();
    final init = _engine!.newGame(setups);
    state = GameSession(state: init);
    unawaited(_persist());
    _scheduleBotIfNeeded();
  }

  /// İnsan oyuncunun aksiyonunu uygula.
  void dispatch(PlayerAction action) {
    final sess = state;
    final engine = _engine;
    if (sess == null || engine == null) return;
    if (sess.state.phase == TurnPhase.gameOver) return;

    // İnsan oyuncunun kendi aksiyonunda haptik (destekleyen tarayıcılarda).
    if (!sess.state.currentPlayer.isBot) {
      if (action is RollDice) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }

    final (next, events) = engine.submit(sess.state, action);
    _history.add(action);

    final merged = [
      ...sess.log,
      ...events.map((e) => e.describe(next.players)),
    ];
    final trimmed = merged.length > 120
        ? merged.sublist(merged.length - 120)
        : merged;

    state = sess.copyWith(state: next, lastEvents: events, log: trimmed);
    unawaited(_persist());
    _scheduleBotIfNeeded();
  }

  void _scheduleBotIfNeeded() {
    _botTimer?.cancel();
    if (!currentIsBot) return;
    _botTimer = Timer(_botStepDelay, () {
      if (_disposed) return;
      if (!currentIsBot) return;
      final sess = state;
      final eng = _engine;
      if (sess == null || eng == null) return;
      dispatch(_bot.decide(eng, sess.state));
    });
  }

  // --------------------------------------------------------------------------
  // Kayıt / devam
  // --------------------------------------------------------------------------

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'seed': _seed,
      'setups': [
        for (final s in _setups)
          {'name': s.name, 'pawn': s.pawn.name, 'isBot': s.isBot},
      ],
      'actions': _history.map((a) => a.toJson()).toList(),
    };
    if (state?.state.phase == TurnPhase.gameOver) {
      await prefs.remove(_saveKey);
    } else {
      await prefs.setString(_saveKey, jsonEncode(data));
    }
  }

  /// Kayıtlı oyun var mı?
  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  /// Kayıttan devam et (seed + aksiyonları replay ederek).
  Future<bool> resume() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      _seed = data['seed'] as int;
      _setups = [
        for (final s in (data['setups'] as List).cast<Map<String, dynamic>>())
          PlayerSetup(
            name: s['name'] as String,
            pawn: PawnType.values.byName(s['pawn'] as String),
            isBot: s['isBot'] as bool,
          ),
      ];
      _isBot = _setups.map((s) => s.isBot).toList();
      final engine = GameEngine(Random(_seed));
      _engine = engine;

      var s = engine.newGame(_setups);
      final log = <String>[];
      _history.clear();
      for (final aj in (data['actions'] as List).cast<Map<String, dynamic>>()) {
        final action = PlayerAction.fromJson(aj);
        final (next, events) = engine.submit(s, action);
        log.addAll(events.map((e) => e.describe(next.players)));
        s = next;
        _history.add(action);
      }
      final trimmed = log.length > 120 ? log.sublist(log.length - 120) : log;
      state = GameSession(state: s, log: trimmed);
      _scheduleBotIfNeeded();
      return true;
    } on Exception catch (_) {
      // Bozuk / eski sürüm kaydı: temizle, taze başlat.
      await prefs.remove(_saveKey);
      _engine = null;
      return false;
    }
  }

  Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}

/// Oyun oturumu sağlayıcısı (uygulama boyunca yaşar).
final gameControllerProvider = NotifierProvider<GameController, GameSession?>(
  GameController.new,
);

/// Kayıtlı oyun var mı? (Ana menüde "Devam Et" için.)
final hasSaveProvider = FutureProvider<bool>((ref) => GameController.hasSave());
