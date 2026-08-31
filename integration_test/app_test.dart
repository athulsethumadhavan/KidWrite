// End-to-end smoke test on a real device or emulator.
//
//   flutter test integration_test/app_test.dart
//
// Deliberately shallow: it walks the paths a child takes in the first minute
// and asserts the app is still standing. Anything deeper belongs in a widget
// test, which runs in a second and doesn't need hardware.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kid_write/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('first run', () {
    testWidgets('home lists the language cards', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Onboarding may be in the way on a clean install — step through it.
      await _dismissOnboarding(tester);

      expect(find.text('Lines'), findsOneWidget);
      expect(find.text('Shapes'), findsOneWidget);
      expect(find.text('Malayalam'), findsOneWidget);
    });

    testWidgets('a language opens its letter map, and back returns home',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await _dismissOnboarding(tester);

      await tester.tap(find.text('Lines'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Lines ✏️'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Shapes'), findsOneWidget);
    });

    testWidgets('the first letter opens the practice screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await _dismissOnboarding(tester);

      await tester.tap(find.text('Lines'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The first bubble on the map is always unlocked.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Trace & Write'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}

/// Taps through the first-run guide if it is showing. Harmless when it isn't.
Future<void> _dismissOnboarding(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    final next = find.textContaining(
      RegExp('next|start|got it|continue', caseSensitive: false),
    );
    if (next.evaluate().isEmpty) return;
    await tester.tap(next.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
