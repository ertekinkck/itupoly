import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

void main() {
  group('board_tr', () {
    test('tam olarak 40 kare', () {
      expect(boardTr.length, 40);
    });

    test('indeksler 0..39 sıralı', () {
      for (var i = 0; i < boardTr.length; i++) {
        expect(boardTr[i].index, i);
      }
    });

    test('köşeler doğru yerde', () {
      expect(boardTr[0], isA<CornerTile>());
      expect((boardTr[0] as CornerTile).type, CornerType.basla);
      expect((boardTr[10] as CornerTile).type, CornerType.disiplinZiyaret);
      expect((boardTr[20] as CornerTile).type, CornerType.cimAmfi);
      expect((boardTr[30] as CornerTile).type, CornerType.disiplineSevk);
    });

    test('4 ring, 2 şirket, 2 vergi, 6 kart, 22 arsa', () {
      expect(boardTr.whereType<RingTile>().length, 4);
      expect(boardTr.whereType<UtilityTile>().length, 2);
      expect(boardTr.whereType<TaxTile>().length, 2);
      expect(boardTr.whereType<CardTile>().length, 6);
      expect(boardTr.whereType<PropertyTile>().length, 22);
    });

    test('her arsa için 6 elemanlı kira merdiveni ve artan kira', () {
      for (final t in boardTr.whereType<PropertyTile>()) {
        expect(t.rents.length, 6, reason: t.name);
        for (var i = 1; i < t.rents.length; i++) {
          expect(t.rents[i], greaterThan(t.rents[i - 1]), reason: t.name);
        }
      }
    });

    test('inşaat maliyetleri gruba göre (50/100/150/200)', () {
      int hc(TileGroup g) => boardTr
          .whereType<PropertyTile>()
          .firstWhere((t) => t.group == g)
          .houseCost;
      expect(hc(TileGroup.kahverengi), 50);
      expect(hc(TileGroup.acikMavi), 50);
      expect(hc(TileGroup.pembe), 100);
      expect(hc(TileGroup.turuncu), 100);
      expect(hc(TileGroup.kirmizi), 150);
      expect(hc(TileGroup.sari), 150);
      expect(hc(TileGroup.yesil), 200);
      expect(hc(TileGroup.lacivert), 200);
    });

    test('fiyatlar plana uygun', () {
      expect((boardTr[1] as PropertyTile).price, 60);
      expect((boardTr[39] as PropertyTile).price, 400);
      expect((boardTr[37] as PropertyTile).price, 350);
      expect((boardTr[5] as RingTile).price, 200);
      expect((boardTr[12] as UtilityTile).price, 150);
      expect((boardTr[4] as TaxTile).amount, 200);
      expect((boardTr[38] as TaxTile).amount, 100);
    });

    test('her renk grubunda doğru sayıda kare', () {
      expect(tilesInGroup(TileGroup.kahverengi).length, 2);
      expect(tilesInGroup(TileGroup.lacivert).length, 2);
      expect(tilesInGroup(TileGroup.acikMavi).length, 3);
      expect(tilesInGroup(TileGroup.turuncu).length, 3);
      expect(ringIndices.length, 4);
      expect(utilityIndices.length, 2);
    });
  });

  group('cards_tr', () {
    test('her deste 16 kart, id 0..15', () {
      expect(sansCards.length, 16);
      expect(kampusCards.length, 16);
      for (var i = 0; i < 16; i++) {
        expect(sansCards[i].id, i);
        expect(kampusCards[i].id, i);
      }
    });

    test('her destede tam bir Af Kartı var', () {
      expect(sansCards.where((c) => c.action is GetAfKarti).length, 1);
      expect(kampusCards.where((c) => c.action is GetAfKarti).length, 1);
    });

    test('MoveTo hedefleri tahta sınırında', () {
      for (final c in [...sansCards, ...kampusCards]) {
        if (c.action case MoveTo(:final tileIndex)) {
          expect(tileIndex, inInclusiveRange(0, 39));
        }
      }
    });
  });
}
