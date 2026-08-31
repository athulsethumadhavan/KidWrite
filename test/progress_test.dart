// The Progress entity.
//
// Progress is Equatable, and a bloc suppresses a state change when the new
// state compares equal to the old one. That makes `props` load-bearing: a
// mutable field left out of it is invisible to the UI. successCount was
// missing once and stars stopped updating on the second attempt — the app
// looked broken and nothing had thrown.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/domain/entities/progress.dart';

void main() {
  final when = DateTime(2026, 8, 31, 10, 0);

  Progress make({
    int attempts = 0,
    int successes = 0,
    double accuracy = 0,
    DateTime? at,
  }) => Progress(
    characterId: 'ml_vowel_0',
    languageId: 'malayalam',
    attemptCount: attempts,
    successCount: successes,
    lastPracticed: at ?? when,
    bestAccuracy: accuracy,
  );

  group('equality', () {
    test('two identical records are equal', () {
      expect(make(attempts: 1, successes: 1), make(attempts: 1, successes: 1));
    });

    // One test per mutable field. If a field is added to the class and not to
    // props, the matching case here fails rather than the bug reaching a child.
    test('a change to any field makes it unequal', () {
      final base = make(attempts: 2, successes: 1, accuracy: 0.5);

      expect(base, isNot(base.copyWith(attemptCount: 3)));
      expect(base, isNot(base.copyWith(successCount: 2)));
      expect(base, isNot(base.copyWith(bestAccuracy: 0.6)));
      expect(
        base,
        isNot(base.copyWith(lastPracticed: when.add(const Duration(days: 1)))),
      );
    });

    test('props covers every field the constructor takes', () {
      // Six fields on the class, six entries in props. A seventh field added
      // without updating props trips this.
      expect(make().props.length, 6);
    });
  });

  group('mastery', () {
    test('needs three successes and 80% accuracy', () {
      expect(make(successes: 3, accuracy: 0.8).isMastered, isTrue);
      expect(make(successes: 3, accuracy: 0.79).isMastered, isFalse);
      expect(make(successes: 2, accuracy: 1.0).isMastered, isFalse);
    });

    test('extra successes stay mastered', () {
      expect(make(successes: 9, accuracy: 0.95).isMastered, isTrue);
    });
  });

  group('successRate', () {
    test('is zero rather than NaN before the first attempt', () {
      // 0/0 would be NaN, which formats as "NaN%" on the progress screen.
      expect(make().successRate, 0);
    });

    test('is successes over attempts', () {
      expect(make(attempts: 4, successes: 1).successRate, 0.25);
      expect(make(attempts: 3, successes: 3).successRate, 1.0);
    });
  });

  group('copyWith', () {
    test('leaves the identity fields alone', () {
      final c = make().copyWith(attemptCount: 5);
      expect(c.characterId, 'ml_vowel_0');
      expect(c.languageId, 'malayalam');
    });

    test('an empty copy equals the original', () {
      final base = make(attempts: 2, successes: 1, accuracy: 0.4);
      expect(base.copyWith(), base);
    });
  });
}
