import 'package:itupoly_engine/src/actions/actions.dart';
import 'package:itupoly_engine/src/data/board_tr.dart';
import 'package:itupoly_engine/src/engine.dart';
import 'package:itupoly_engine/src/models/enums.dart';
import 'package:itupoly_engine/src/models/game_state.dart';
import 'package:itupoly_engine/src/models/tile.dart';
import 'package:itupoly_engine/src/models/tile_group.dart';
import 'package:itupoly_engine/src/rules/bankruptcy.dart';
import 'package:itupoly_engine/src/rules/mortgage.dart';
import 'package:itupoly_engine/src/rules/rent.dart';

/// Kurallı greedy bot (v0) + opsiyonel heuristik iyileştirme (v1).
///
/// Saf karar fonksiyonu: state + engine → tek bir yasal [PlayerAction]. Sürücü
/// (CLI/UI), sıra botta olduğu sürece [decide]'ı tekrar tekrar uygular.
class Bot {
  const Bot({this.minCash = 150, this.heuristic = true});

  /// Korunacak nakit tamponu.
  final int minCash;

  /// v1 heuristikleri (grup trafiği, tamamlama bonusu) açık mı?
  final bool heuristic;

  /// Yüksek trafikli gruplar (turuncu/kırmızı en çok basılan bölge).
  static const _groupWeight = <TileGroup, double>{
    TileGroup.turuncu: 1.5,
    TileGroup.kirmizi: 1.4,
    TileGroup.sari: 1.25,
    TileGroup.pembe: 1.2,
    TileGroup.yesil: 1.1,
    TileGroup.acikMavi: 1.0,
    TileGroup.lacivert: 1.0,
    TileGroup.kahverengi: 0.9,
    TileGroup.istasyon: 1.15,
    TileGroup.altyapi: 0.7,
  };

  PlayerAction decide(GameEngine engine, GameState s) {
    switch (s.phase) {
      case TurnPhase.awaitRoll:
        // Tur başında önce getirisi yüksek inşaatları yap, sonra zar at.
        final preRollBuild = _bestBuild(engine, s);
        if (preRollBuild != null) return preRollBuild;
        return const RollDice();
      case TurnPhase.inDisiplin:
        return _decideJail(engine, s);
      case TurnPhase.awaitBuyDecision:
        return _decideBuy(s);
      case TurnPhase.mustLiquidate:
        return _decideLiquidation(engine, s);
      case TurnPhase.endTurn:
        final build = _bestBuild(engine, s);
        if (build != null) return build;
        final unmort = _bestUnmortgage(engine, s);
        if (unmort != null) return unmort;
        return const EndTurn();
      case TurnPhase.gameOver:
        throw StateError('Oyun bitti; bot karar veremez');
    }
  }

  PlayerAction _decideJail(GameEngine engine, GameState s) {
    final legal = engine.legalActions(s);
    final p = s.currentPlayer;
    // Af Kartı bedava çıkış: hemen kullan.
    if (legal.any((a) => a is UseAfKarti)) return const UseAfKarti();
    // Erken oyunda dışarı çıkmak değerli (arsa kapma); geç oyunda beklemek
    // güvenli. Basit ölçüt: yeterli nakit varsa cezayı öde, yoksa zar dene.
    final owned = s.propertiesOf(p.id).length;
    final earlyGame = owned < 8;
    if (earlyGame &&
        legal.any((a) => a is PayDisiplinFine) &&
        p.cash > minCash + disiplinFine) {
      return const PayDisiplinFine();
    }
    return const RollDice();
  }

  PlayerAction _decideBuy(GameState s) {
    final p = s.currentPlayer;
    final index = p.position;
    final tile = boardTr[index];
    final price = tile.purchasePrice;
    if (p.cash < price) return const DeclineBuy();

    final remaining = p.cash - price;
    final completes = _completesGroup(s, index, p.id);

    if (completes && remaining >= 0) return const BuyProperty();
    if (remaining >= minCash) return const BuyProperty();

    // Heuristik: yüksek trafikli / değerli kareler için tamponu biraz delebilir.
    if (heuristic) {
      final weight = _weightOf(tile);
      if (weight >= 1.3 && remaining >= 0) return const BuyProperty();
    }
    return const DeclineBuy();
  }

  PlayerAction _decideLiquidation(GameEngine engine, GameState s) {
    final p = s.currentPlayer;
    final debt = s.pendingDebt;
    // Tasfiyeyle borç kapanamıyorsa hemen iflas.
    if (debt != null && maxRaisableCash(s, p.id) < debt.amount) {
      return const DeclareBankruptcy();
    }
    final legal = engine.legalActions(s);
    // Önce inşaatları sat (en yüksek inşaatlı kareden — eşit kural).
    final sells = legal.whereType<SellHouse>().toList();
    // Sonra en düşük değerli kareyi ipotek et (büyük varlıkları koru).
    final mortgages = legal.whereType<MortgageTile>().toList()
      ..sort(
        (a, b) =>
            mortgageValue(a.tileIndex).compareTo(mortgageValue(b.tileIndex)),
      );
    if (mortgages.isNotEmpty) return mortgages.first;
    if (sells.isNotEmpty) return sells.first;
    return const DeclareBankruptcy();
  }

  BuildHouse? _bestBuild(GameEngine engine, GameState s) {
    final p = s.currentPlayer;
    final builds = engine.legalActions(s).whereType<BuildHouse>().where((b) {
      final tile = boardTr[b.tileIndex] as PropertyTile;
      return p.cash - tile.houseCost >= minCash;
    }).toList();
    if (builds.isEmpty) return null;
    builds.sort((a, b) => _buildScore(b).compareTo(_buildScore(a)));
    return builds.first;
  }

  double _buildScore(BuildHouse b) {
    final tile = boardTr[b.tileIndex] as PropertyTile;
    // 1 derslikteki kira artışı / inşaat maliyeti = yatırım getirisi.
    final roi = tile.rents[1] / tile.houseCost;
    final weight = heuristic ? (_groupWeight[tile.group] ?? 1.0) : 1.0;
    return roi * weight;
  }

  UnmortgageTile? _bestUnmortgage(GameEngine engine, GameState s) {
    final p = s.currentPlayer;
    final options = engine
        .legalActions(s)
        .whereType<UnmortgageTile>()
        .where((u) => p.cash - unmortgageCost(u.tileIndex) >= minCash)
        .toList();
    if (options.isEmpty) return null;
    // Tekel parçası olan kareleri öncelikle kurtar.
    options.sort((a, b) {
      final aMono = _inOwnedGroup(s, a.tileIndex, p.id) ? 1 : 0;
      final bMono = _inOwnedGroup(s, b.tileIndex, p.id) ? 1 : 0;
      return bMono.compareTo(aMono);
    });
    return options.first;
  }

  bool _completesGroup(GameState s, int index, int playerId) {
    final tile = boardTr[index];
    final group = _groupOf(tile);
    if (group == null) return false;
    return tilesInGroup(group).every(
      (i) => i == index || s.tileStateAt(i).ownerId == playerId,
    );
  }

  bool _inOwnedGroup(GameState s, int index, int playerId) {
    final group = _groupOf(boardTr[index]);
    if (group == null) return false;
    return ownsFullGroup(s, group, playerId);
  }

  double _weightOf(Tile tile) {
    final group = _groupOf(tile);
    return group == null ? 1.0 : (_groupWeight[group] ?? 1.0);
  }

  TileGroup? _groupOf(Tile tile) => switch (tile) {
    PropertyTile(:final group) => group,
    RingTile() => TileGroup.istasyon,
    UtilityTile() => TileGroup.altyapi,
    _ => null,
  };
}
