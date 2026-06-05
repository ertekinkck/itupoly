import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itupoly/app/theme/theme.dart';
import 'package:itupoly/features/game/game_screen.dart';
import 'package:itupoly/features/game/providers/game_providers.dart';
import 'package:itupoly_engine/itupoly_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('controller: oyun başlat ve zar at akışı', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.startNew(const [
      PlayerSetup(name: 'Ali', pawn: PawnType.ari),
      PlayerSetup(name: 'Veli', pawn: PawnType.pergel),
    ]);
    expect(
      container.read(gameControllerProvider)!.state.phase,
      TurnPhase.awaitRoll,
    );

    ctrl.dispatch(const RollDice());
    final session = container.read(gameControllerProvider)!;
    expect(session.state.lastDie1, greaterThan(0));
    expect(session.lastEvents, isNotEmpty);
  });

  testWidgets('GameScreen tahtayı ve aksiyon barını çizer', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameControllerProvider.notifier).startNew(const [
      PlayerSetup(name: 'Ali', pawn: PawnType.ari),
      PlayerSetup(name: 'Veli', pawn: PawnType.pergel),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const GameScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Zar At'), findsOneWidget);
    expect(find.text('Ali'), findsWidgets);
  });
}
