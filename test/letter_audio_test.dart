// The letter clips that play when a child opens a character.
//
// These are files on disk named by index — ml_vowel_6.mp3, hi_vowel_7.mp3 —
// so inserting a letter into the middle of a table silently renumbers every
// clip after it. That is exactly what happened when ഋ and ऋ were added: six of
// twelve Malayalam clips and four of ten Hindi ones went on playing the letter
// that used to hold their index, and nothing failed. The generator now writes
// a manifest of which letter each clip was made for, and this compares it with
// the table the app actually shows.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/data/letter_words.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();
  final manifestFile = File('assets/audio/letters/manifest.json');

  Map<String, String> readManifest() =>
      (jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      );

  test('a manifest exists — without it the clips cannot be checked', () {
    expect(
      manifestFile.existsSync(),
      isTrue,
      reason: 'run: python3 scripts/generate_pronunciations.py',
    );
  });

  test('every clip is still filed under the letter it was recorded for', () {
    if (!manifestFile.existsSync()) return;
    final manifest = readManifest();

    final wrong = <String>[];
    for (final lang in ds.getLanguages()) {
      for (final c in ds.getCharacters(lang.id)) {
        final stem = LetterWords.fileStem(c);
        final recorded = manifest[stem];
        if (recorded != null && recorded != c.symbol) {
          wrong.add('$stem holds "$recorded" but now shows "${c.symbol}"');
        }
      }
    }
    expect(
      wrong,
      isEmpty,
      reason:
          'the character table moved under the audio.\n${wrong.join('\n')}\n'
          'run: python3 scripts/generate_pronunciations.py',
    );
  });

  test('no character is left without a clip in the manifest', () {
    if (!manifestFile.existsSync()) return;
    final manifest = readManifest();

    final missing = <String>[];
    for (final lang in ds.getLanguages()) {
      for (final c in ds.getCharacters(lang.id)) {
        final stem = LetterWords.fileStem(c);
        if (!manifest.containsKey(stem)) missing.add('$stem (${c.symbol})');
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'these characters were added after the last audio run:\n'
          '${missing.join('\n')}',
    );
  });

  test('file stems are unique across every language', () {
    // Two characters sharing a stem means one clip silently overwrites the
    // other. This is how the English pair collided before fileStem existed.
    final seen = <String, String>{};
    for (final lang in ds.getLanguages()) {
      for (final c in ds.getCharacters(lang.id)) {
        final stem = LetterWords.fileStem(c).toLowerCase();
        expect(
          seen.containsKey(stem),
          isFalse,
          reason: '$stem is used by both ${seen[stem]} and ${c.symbol}',
        );
        seen[stem] = c.symbol;
      }
    }
  });
}
