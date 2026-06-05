import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly/widgets/pawn_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:web/web.dart' as web;

@JS('Itupoly3D.attach')
external void _attach(web.HTMLElement host);

@JS('Itupoly3D.setState')
external void _setState(String json);

@JS('Itupoly3D.dispose')
external void _disposeScene();

@JS('itupolyOnTapTile')
external set _onTapTile(JSFunction f);

@JS('itupolyOnAnimEvent')
external set _onAnimEvent(JSFunction f);

const _viewType = 'itupoly-3d-board';
bool _registered = false;

/// viewId → host elemanı (factory ile onPlatformViewCreated arasında köprü).
final _hostElements = <int, web.HTMLDivElement>{};

/// Gerçek 3B tahta (three.js) — Flutter platform view içine gömülür.
class Board3DView extends StatefulWidget {
  const Board3DView({
    required this.state,
    required this.onTapTile,
    this.onAnimEvent,
    super.key,
  });

  final GameState state;
  final void Function(int index) onTapTile;
  /// 'diceSettled' veya 'idle' sinyali — zamanlama köprüsü.
  final void Function(String kind)? onAnimEvent;

  @override
  State<Board3DView> createState() => _Board3DViewState();
}

int _globalRollNonce = 0;

class _Board3DViewState extends State<Board3DView> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
        final div = web.HTMLDivElement()
          ..id = 'itupoly3d-$id'
          ..style.width = '100%'
          ..style.height = '100%';
        _hostElements[id] = div;
        return div;
      });
    }
  }

  void _onCreated(int id) {
    final host = _hostElements[id];
    if (host == null) return;
    _onTapTile = ((JSNumber i) => widget.onTapTile(i.toDartInt)).toJS;
    _onAnimEvent = ((JSString k) => widget.onAnimEvent?.call(k.toDart)).toJS;
    _attach(host);
    _ready = true;
    _push();
  }

  @override
  void didUpdateWidget(Board3DView old) {
    super.didUpdateWidget(old);
    final oldState = old.state;
    final newState = widget.state;
    
    // Detect new roll
    final rolled = (oldState.phase == TurnPhase.awaitRoll && newState.phase != TurnPhase.awaitRoll) ||
        (oldState.phase == TurnPhase.inDisiplin && newState.phase != TurnPhase.inDisiplin) ||
        (oldState.lastDie1 != newState.lastDie1 && newState.lastDie1 > 0) ||
        (oldState.lastDie2 != newState.lastDie2 && newState.lastDie2 > 0);
        
    if (rolled) {
      _globalRollNonce++;
    }
    
    if (_ready) _push();
  }

  void _push() => _setState(_encodeState(widget.state, _globalRollNonce));

  @override
  void dispose() {
    _onTapTile = ((JSNumber _) {}).toJS;
    _onAnimEvent = ((JSString _) {}).toJS;
    _disposeScene();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
      onPlatformViewCreated: _onCreated,
    );
  }
}

/// GameState'i 3B sahnenin beklediği kompakt JSON'a çevirir.
String _encodeState(GameState s, int rollNonce) {
  final tiles = <Map<String, dynamic>>[];
  for (var i = 0; i < boardSize; i++) {
    final tile = boardTr[i];
    final ts = s.tileStateAt(i);
    int? group;
    if (tile is PropertyTile) {
      group = groupColor(tile.group).toARGB32() & 0xFFFFFF;
    }
    final owner = ts.ownerId != null
        ? PawnVisuals.colorOf(s.playerById(ts.ownerId!).pawn).toARGB32() &
              0xFFFFFF
        : null;
    tiles.add({
      'k': tile.kindTag,
      'n': tile.name,
      'p': tile.purchasePrice,
      'ic': _tileIcon(tile),
      'g': group,
      'o': owner,
      'h': ts.houses,
      'm': ts.mortgaged,
    });
  }
  final players = [
    for (final p in s.players)
      {
        'id': p.id,
        'pos': p.position,
        't': p.pawn.name,
        'c': PawnVisuals.colorOf(p.pawn).toARGB32() & 0xFFFFFF,
        'b': p.bankrupt,
        'j': p.inJail,
      },
  ];
  return jsonEncode({
    'tiles': tiles,
    'players': players,
    'current': s.currentPlayer.position,
    'cur': s.currentPlayer.id,
    'd1': s.lastDie1,
    'd2': s.lastDie2,
    'rn': rollNonce,
    'phase': s.phase.name,
  });
}

/// Kare türü/grubuna göre 3B doku ikonu (Material Icon unicode).
String _tileIcon(Tile tile) {
  switch (tile) {
    case PropertyTile(:final group):
      return switch (group) {
        TileGroup.kahverengi => '\uE80C',      // school
        TileGroup.acikMavi => '\uEA19',        // menu_book
        TileGroup.pembe => '\uEA3F',           // architecture
        TileGroup.turuncu => '\uEA40',         // apartment
        TileGroup.kirmizi => '\uEA4B',         // science
        TileGroup.sari => '\uE539',            // flight
        TileGroup.yesil => '\uE54B',           // local_library
        TileGroup.lacivert => '\uE800',        // account_balance
        _ => '\uE88A',                         // home
      };
    case RingTile():
      return '\uE530';                         // directions_bus
    case UtilityTile():
      return '\uEA0B';                         // bolt
    case TaxTile():
      return '\uEEF0';                         // receipt_long
    case CardTile(:final deck):
      return deck == DeckType.sans ? '\uE887' : '\uE41D'; // help vs style
    case CornerTile(:final type):
      return switch (type) {
        CornerType.basla => '\uE153',          // flag
        CornerType.disiplinZiyaret => '\uE8E6', // gavel
        CornerType.cimAmfi => '\uEA63',        // park
        CornerType.disiplineSevk => '\uE7F7',   // notifications_active
      };
  }
}
