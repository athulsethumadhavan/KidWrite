// The letter tables. Pure Dart — no platform channels, so these run fast and
// are the ones worth gating a push on.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();

  group('languages', () {
    test('all eight sets are offered', () {
      final ids = ds.getLanguages().map((l) => l.id).toList();
      expect(ids, [
        LanguageId.lines,
        LanguageId.shapes,
        LanguageId.englishUpper,
        LanguageId.englishLower,
        LanguageId.numbers,
        LanguageId.malayalam,
        LanguageId.hindi,
        LanguageId.tamil,
      ]);
    });

    test('every language has characters behind it', () {
      for (final lang in ds.getLanguages()) {
        expect(
          ds.getCharacters(lang.id),
          isNotEmpty,
          reason: '${lang.id} has no characters',
        );
      }
    });
  });

  group('counts', () {
    test('English is 26 capitals and 26 small, in separate sets', () {
      expect(ds.getCharacters(LanguageId.englishUpper).length, 26);
      expect(ds.getCharacters(LanguageId.englishLower).length, 26);
    });

    test('numbers are 0-9', () {
      final nums = ds.getCharacters(LanguageId.numbers);
      expect(nums.length, 10);
      expect(nums.map((c) => c.symbol).toList(), [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ]);
    });

    test('Malayalam is 15 vowels and 36 consonants', () {
      final ml = ds.getCharacters(LanguageId.malayalam);
      expect(ml.where((c) => c.category == CharacterCategory.vowel).length, 15);
      expect(
        ml.where((c) => c.category == CharacterCategory.consonant).length,
        36,
      );
      expect(ml.length, 51);
    });
  });

  group('invariants that break the app when violated', () {
    test('character ids are unique within a language', () {
      for (final lang in ds.getLanguages()) {
        final ids = ds.getCharacters(lang.id).map((c) => c.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'duplicate id in ${lang.id}',
        );
      }
    });

    test('nothing has an empty symbol or pronunciation', () {
      // The pronunciation is spoken aloud and printed under the letter; an
      // empty one is silent and looks broken.
      for (final lang in ds.getLanguages()) {
        for (final c in ds.getCharacters(lang.id)) {
          expect(c.symbol, isNotEmpty, reason: '${c.id} has no symbol');
          expect(
            c.pronunciation,
            isNotEmpty,
            reason: '${c.id} has no pronunciation',
          );
        }
      }
    });

    test('orderIndex is strictly increasing — it drives the level map', () {
      for (final lang in ds.getLanguages()) {
        final chars = ds.getCharacters(lang.id);
        for (int i = 1; i < chars.length; i++) {
          expect(
            chars[i].orderIndex,
            greaterThan(chars[i - 1].orderIndex),
            reason: '${lang.id}: ${chars[i].id} is out of order',
          );
        }
      }
    });
  });

  group('release safety', () {
    test('sequential unlocking is on', () {
      // Flipped to true while testing the whole set; shipping it that way
      // hands every letter to the child at once.
      expect(
        AppConstants.unlockAllLetters,
        isFalse,
        reason: 'unlockAllLetters must be false before release',
      );
    });
  });
}
