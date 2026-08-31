// The picture-word table behind the reward card.
//
// These catch the two mistakes that actually happened while building it: a
// Malayalam letter with no word, and asset filenames that collide on a
// case-insensitive filesystem.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/data/letter_words.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();

  const covered = [
    LanguageId.englishUpper,
    LanguageId.englishLower,
    LanguageId.numbers,
    LanguageId.malayalam,
  ];

  group('coverage', () {
    for (final lang in covered) {
      test('$lang: every character has a word', () {
        for (final c in ds.getCharacters(lang)) {
          expect(
            LetterWords.of(c),
            isNotNull,
            reason: 'no word for ${c.symbol} (${c.id})',
          );
        }
      });
    }

    test('scripts without a word list return null rather than throwing', () {
      for (final lang in [
        LanguageId.lines,
        LanguageId.shapes,
        LanguageId.hindi,
        LanguageId.tamil,
      ]) {
        for (final c in ds.getCharacters(lang)) {
          expect(LetterWords.of(c), isNull);
        }
      }
    });
  });

  group('content', () {
    test('words and pictures are never blank', () {
      for (final lang in covered) {
        for (final c in ds.getCharacters(lang)) {
          final w = LetterWords.of(c)!;
          expect(w.word.trim(), isNotEmpty, reason: '${c.id} word');
          expect(w.emoji.trim(), isNotEmpty, reason: '${c.id} emoji');
          expect(w.spoken.trim(), isNotEmpty, reason: '${c.id} spoken');
        }
      }
    });

    test('Malayalam carries a roman spelling, English does not need one', () {
      for (final c in ds.getCharacters(LanguageId.malayalam)) {
        expect(LetterWords.of(c)!.roman, isNotNull, reason: c.id);
      }
      for (final c in ds.getCharacters(LanguageId.englishUpper)) {
        expect(LetterWords.of(c)!.roman, isNull, reason: c.id);
      }
    });

    test('Malayalam is spoken as letter then word', () {
      for (final c in ds.getCharacters(LanguageId.malayalam)) {
        final w = LetterWords.of(c)!;
        expect(
          w.spoken,
          startsWith(c.symbol),
          reason: '${c.id} should say the letter first',
        );
        expect(w.spoken, contains(w.word));
      }
    });

    test('the roman fallback mirrors it — sound, then word', () {
      for (final c in ds.getCharacters(LanguageId.malayalam)) {
        final w = LetterWords.of(c)!;
        final roman = LetterWords.romanSpoken(c, w);
        expect(roman, '${c.pronunciation} ${w.roman}', reason: c.id);
      }
    });

    test('number pictures show the quantity', () {
      for (final c in ds.getCharacters(LanguageId.numbers)) {
        final n = int.parse(c.symbol);
        if (n == 0) continue; // an empty basket, nothing to count
        final w = LetterWords.of(c)!;
        // Emoji are multi-code-unit, so count runes rather than characters.
        expect(
          w.emoji.runes.length,
          n,
          reason: '$n should show $n things, got "${w.emoji}"',
        );
      }
    });
  });

  group('asset filenames', () {
    test('are unique even ignoring case', () {
      // en_lower_A and en_lower_a are the *same file* on macOS and Windows;
      // one silently overwrote the other before fileStem existed.
      final stems = <String>[];
      for (final lang in covered) {
        for (final c in ds.getCharacters(lang)) {
          stems.add(LetterWords.fileStem(c).toLowerCase());
        }
      }
      expect(
        stems.toSet().length,
        stems.length,
        reason: 'two characters would share an asset filename',
      );
    });

    test('capitals are namespaced away from small letters', () {
      final upperA = ds
          .getCharacters(LanguageId.englishUpper)
          .firstWhere((c) => c.symbol == 'A');
      final lowerA = ds
          .getCharacters(LanguageId.englishLower)
          .firstWhere((c) => c.symbol == 'a');
      expect(LetterWords.fileStem(upperA), 'en_upper_A');
      expect(
        LetterWords.fileStem(lowerA).toLowerCase(),
        isNot(LetterWords.fileStem(upperA).toLowerCase()),
      );
    });
  });
}
