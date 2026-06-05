import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:test/test.dart';

import '_support/helpers.dart';

void main() {
  group('arsa kirası', () {
    test('tek arsa: temel kira', () {
      // Tuzla (1) kahverengi, temel kira 2. Sahibi tek karesi var.
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {1: const TileState(ownerId: 0)},
      );
      expect(rentFor(s, 1), 2);
    });

    test('tekel (grup tam, inşaat yok): temel kira ×2', () {
      // Kahverengi grup: 1 ve 3. İkisi de oyuncu 0'da.
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {
          1: const TileState(ownerId: 0),
          3: const TileState(ownerId: 0),
        },
      );
      expect(rentFor(s, 1), 2 * 2);
      expect(rentFor(s, 3), 4 * 2);
    });

    test('1–4 derslik ve amfi kira merdiveni', () {
      final base = {
        1: const TileState(ownerId: 0),
        3: const TileState(ownerId: 0),
      };
      for (var h = 1; h <= 5; h++) {
        final s = gameWith(
          players: [player(0), player(1)],
          tiles: {
            ...base,
            1: TileState(ownerId: 0, houses: h),
          },
        );
        expect(rentFor(s, 1), (boardTr[1] as PropertyTile).rents[h]);
      }
    });

    test('ipotekli arsada kira 0', () {
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {1: const TileState(ownerId: 0, mortgaged: true)},
      );
      expect(rentFor(s, 1), 0);
    });

    test('sahipsiz karede kira 0', () {
      final s = gameWith(players: [player(0), player(1)]);
      expect(rentFor(s, 1), 0);
    });
  });

  group('ring kirası', () {
    test('1–4 ring sahipliğine göre 25/50/100/200', () {
      final rings = ringIndices;
      for (var owned = 1; owned <= 4; owned++) {
        final tiles = {
          for (var i = 0; i < owned; i++) rings[i]: const TileState(ownerId: 0),
        };
        final s = gameWith(players: [player(0), player(1)], tiles: tiles);
        expect(rentFor(s, rings[0]), [0, 25, 50, 100, 200][owned]);
      }
    });

    test('ipotekli ring sayılmaz', () {
      final rings = ringIndices;
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {
          rings[0]: const TileState(ownerId: 0),
          rings[1]: const TileState(ownerId: 0, mortgaged: true),
        },
      );
      expect(rentFor(s, rings[0]), 25);
    });
  });

  group('şirket kirası', () {
    test('1 şirket → zar×4', () {
      final u = utilityIndices;
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {u[0]: const TileState(ownerId: 0)},
      );
      expect(rentFor(s, u[0], diceTotal: 9), 9 * 4);
    });

    test('2 şirket → zar×10', () {
      final u = utilityIndices;
      final s = gameWith(
        players: [player(0), player(1)],
        tiles: {
          u[0]: const TileState(ownerId: 0),
          u[1]: const TileState(ownerId: 0),
        },
      );
      expect(rentFor(s, u[0], diceTotal: 7), 7 * 10);
    });
  });
}
