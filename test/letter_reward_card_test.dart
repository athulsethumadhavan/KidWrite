// Widget test for the reward card — the thing a child sees on every success.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/data/letter_words.dart';
import 'package:kid_write/Presentation/widgets/letter_reward_card.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();

  Future<void> show(
    WidgetTester tester,
    Character c, {
    VoidCallback? onDismiss,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              LetterRewardCard(
                character: c,
                entry: LetterWords.of(c)!,
                accentColor: Colors.purple,
                onDismiss: onDismiss ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
    // The entrance animation is one-shot, so this settles.
    await tester.pumpAndSettle();
  }

  testWidgets('English shows the letter, the picture and the word', (
    tester,
  ) async {
    final a = ds
        .getCharacters(LanguageId.englishUpper)
        .firstWhere((c) => c.symbol == 'A');

    await show(tester, a);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('🍎'), findsOneWidget);
  });

  testWidgets('Malayalam also shows the roman spelling', (tester) async {
    final amma = ds.getCharacters(LanguageId.malayalam).first; // അ

    await show(tester, amma);

    expect(find.text('അ'), findsOneWidget);
    expect(find.text('അമ്മ'), findsOneWidget);
    expect(find.text('amma'), findsOneWidget);
  });

  testWidgets('a number shows one picture per unit', (tester) async {
    final three = ds
        .getCharacters(LanguageId.numbers)
        .firstWhere((c) => c.symbol == '3');

    await show(tester, three);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('three balloons'), findsOneWidget);
    expect(find.text('🎈🎈🎈'), findsOneWidget);
  });

  testWidgets('tapping anywhere dismisses it', (tester) async {
    var dismissed = false;
    final a = ds
        .getCharacters(LanguageId.englishUpper)
        .firstWhere((c) => c.symbol == 'A');

    await show(tester, a, onDismiss: () => dismissed = true);

    // Not on the card itself — the scrim behind it counts too, so a child
    // who misses still gets out.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
