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

const _viewType = 'itupoly-3d-board';
bool _registered = false;

/// viewId → host elemanı (factory ile onPlatformViewCreated arasında köprü).
final _hostElements = <int, web.HTMLDivElement>{};

/// Gerçek 3B tahta (three.js) — Flutter platform view içine gömülür.
class Board3DView extends StatefulWidget {
  const Board3DView({required this.state, required this.onTapTile, super.key});

  final GameState state;
  final void Function(int index) onTapTile;

  @override
  State<Board3DView> createState() => _Board3DViewState();
}

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
    _attach(host);
    _ready = true;
    _push();
  }

  @override
  void didUpdateWidget(Board3DView old) {
    super.didUpdateWidget(old);
    if (_ready) _push();
  }

  void _push() => _setState(_encodeState(widget.state));

  @override
  void dispose() {
    _onTapTile = (() {}).toJS;
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
String _encodeState(GameState s) {
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
      'ic': _tileEmoji(tile),
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
        'c': PawnVisuals.colorOf(p.pawn).toARGB32() & 0xFFFFFF,
        'b': p.bankrupt,
      },
  ];
  return jsonEncode({
    'tiles': tiles,
    'players': players,
    'current': s.currentPlayer.position,
    'cur': s.currentPlayer.id,
  });
}

/// Kare türü/grubuna göre 3B doku ikonu (emoji).
String _tileEmoji(Tile tile) {
  switch (tile) {
    case PropertyTile(:final group):
      return switch (group) {
        TileGroup.kahverengi => '🏫',
        TileGroup.acikMavi => '📘',
        TileGroup.pembe => '📐',
        TileGroup.turuncu => '🏢',
        TileGroup.kirmizi => '🧪',
        TileGroup.sari => '✈️',
        TileGroup.yesil => '📚',
        TileGroup.lacivert => '🏛️',
        _ => '🏠',
      };
    case RingTile():
      return '🚌';
    case UtilityTile():
      return '⚡';
    case TaxTile():
      return '💸';
    case CardTile(:final deck):
      return deck == DeckType.sans ? '❓' : '🎴';
    case CornerTile(:final type):
      return switch (type) {
        CornerType.basla => '🏁',
        CornerType.disiplinZiyaret => '⚖️',
        CornerType.cimAmfi => '🌳',
        CornerType.disiplineSevk => '🚨',
      };
  }
}
