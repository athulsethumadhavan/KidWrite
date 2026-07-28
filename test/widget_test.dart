// Unit tests for KidWrite's data layer and tracing stroke data
// (pure Dart — no platform channels needed).

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/tracing/letter_strokes.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/data/models/progress_model.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  group('CharacterLocalDataSource', () {
    final ds = CharacterLocalDataSourceImpl();

    test('provides all five languages', () {
      final ids = ds.getLanguages().map((l) => l.id).toList();
      expect(ids,
          containsAll(['english', 'numbers', 'malayalam', 'hindi', 'tamil']));
      expect(ids.length, 5);
    });

    test('english has 26 uppercase + 26 lowercase letters', () {
      final chars = ds.getCharacters('english');
      expect(
        chars.where((c) => c.category == CharacterCategory.uppercase).length,
        26,
      );
      expect(
        chars.where((c) => c.category == CharacterCategory.lowercase).length,
        26,
      );
    });

    test('every language has characters with unique ids', () {
      for (final lang in ds.getLanguages()) {
        final chars = ds.getCharacters(lang.id);
        expect(chars, isNotEmpty, reason: '${lang.id} should have characters');
        expect(chars.map((c) => c.id).toSet().length, chars.length,
            reason: '${lang.id} has duplicate character ids');
      }
    });
  });

  group('ProgressModel', () {
    test('round-trips through toMap/fromMap', () {
      final original = ProgressModel(
        characterId: 'en_upper_A',
        languageId: 'english',
        attemptCount: 4,
        successCount: 3,
        lastPracticed: DateTime(2026, 7, 1, 10, 30),
        bestAccuracy: 0.82,
      );
      final restored = ProgressModel.fromMap(original.toMap());
      expect(restored, original); // equality now covers all fields
    });

    test('equality reflects successCount changes (star-update regression)',
            () {
          final a = ProgressModel(
            characterId: 'c',
            languageId: 'english',
            attemptCount: 1,
            successCount: 1,
            lastPracticed: DateTime(2026),
            bestAccuracy: 0.9,
          );
          final b = ProgressModel.fromEntity(a.copyWith(successCount: 2));
          // If these were equal, the bloc would suppress star updates.
          expect(a == b, isFalse);
        });
  });

  group('LetterStrokes (guided tracing data)', () {
    const symbols =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    test('defines valid strokes for all English letters and digits', () {
      for (final ch in symbols.split('')) {
        final strokes = LetterStrokes.of(ch);
        expect(strokes, isNotNull, reason: 'missing strokes for "$ch"');
        expect(strokes!, isNotEmpty);
        for (final s in strokes) {
          expect(s.length, greaterThanOrEqualTo(2),
              reason: '"$ch" has a degenerate stroke');
          for (final p in s) {
            expect(p.dx, inInclusiveRange(0, 1));
            expect(p.dy, inInclusiveRange(0, 1));
          }
        }
      }
    });

    test('U and u bowls bulge DOWN (screen coords regression)', () {
      // The bowl arc must reach low y values (y grows downward).
      for (final ch in ['U', 'u']) {
        final stroke = LetterStrokes.of(ch)!.first;
        final maxY =
        stroke.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
        expect(maxY, greaterThan(0.8),
            reason: '"$ch" bowl should dip toward the baseline');
      }
    });

    test('A is written with three strokes', () {
      expect(LetterStrokes.of('A')!.length, 3);
    });
  });
}
