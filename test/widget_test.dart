import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itupoly/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Ana menü "Yeni Oyun" gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ItupolyApp()));
    await tester.pump();
    expect(find.text('Yeni Oyun'), findsOneWidget);
    expect(find.text('Nasıl Oynanır'), findsOneWidget);
  });
}
