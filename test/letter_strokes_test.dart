// The Latin / number / shape / line stroke paths.
//
// These are the five languages WritingBloc treats as guided via LetterStrokes.
// A character with no path silently falls back to free tracing over the font —
// the hand and the dotted trail just don't appear, and nothing errors. Only a
// test catches that.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/tracing/letter_strokes.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();

  // Mirrors WritingBloc._latinLanguages. If that set changes, this should too.
  const guided = [
    LanguageId.englishUpper,
    LanguageId.englishLower,
    LanguageId.numbers,
    LanguageId.shapes,
    LanguageId.lines,
  ];

  group('coverage', () {
    for (final lang in guided) {
      test('$lang: every character has a path', () {
        for (final c in ds.getCharacters(lang)) {
          expect(
            LetterStrokes.of(c.symbol),
            isNotNull,
            reason: '${c.symbol} (${c.id}) would fall back to free tracing',
          );
        }
      });
    }
  });

  group('the paths are usable', () {
    Iterable<Character> everyCharacter() sync* {
      for (final lang in guided) {
        yield* ds.getCharacters(lang);
      }
    }

    test('normalised to the canvas', () {
      for (final c in everyCharacter()) {
        for (final stroke in LetterStrokes.of(c.symbol)!) {
          for (final p in stroke) {
            expect(p.dx, inInclusiveRange(0, 1), reason: '${c.symbol} x');
            expect(p.dy, inInclusiveRange(0, 1), reason: '${c.symbol} y');
          }
        }
      }
    });

    test('no stroke has fewer than two points', () {
      // A single point has no direction, so the demo hand has nothing to
      // follow and the ink mask is empty.
      for (final c in everyCharacter()) {
        for (final stroke in LetterStrokes.of(c.symbol)!) {
          expect(
            stroke.length,
            greaterThanOrEqualTo(2),
            reason: '${c.symbol} has a degenerate stroke',
          );
        }
      }
    });

    test('no character is an empty list of strokes', () {
      for (final c in everyCharacter()) {
        expect(LetterStrokes.of(c.symbol)!, isNotEmpty, reason: c.symbol);
      }
    });

    test(
      'a path actually spans the canvas rather than sitting in a corner',
      () {
        // A letter squeezed into a fraction of the box is almost always a
        // generator bug. Lines are exempt — a horizontal line is 1 unit wide
        // and 0 tall by design.
        for (final lang in guided) {
          if (lang == LanguageId.lines) continue;
          for (final c in ds.getCharacters(lang)) {
            final pts = LetterStrokes.of(c.symbol)!.expand((s) => s);
            final xs = pts.map((p) => p.dx);
            final ys = pts.map((p) => p.dy);
            final w =
                xs.reduce((a, b) => a > b ? a : b) -
                xs.reduce((a, b) => a < b ? a : b);
            final h =
                ys.reduce((a, b) => a > b ? a : b) -
                ys.reduce((a, b) => a < b ? a : b);
            expect(
              w > 0.2 || h > 0.2,
              isTrue,
              reason: '${c.symbol} only spans ${w}x$h of the canvas',
            );
          }
        }
      },
    );
  });

  group('scripts without crafted paths', () {
    test('Hindi and Tamil are not in this table', () {
      // Hindi is guided, but from HindiStrokes — see hindi_strokes_test.dart.
      // Nothing Indic belongs in LetterStrokes, which is Latin, numbers,
      // shapes and lines only.
      var found = 0;
      for (final lang in [LanguageId.hindi, LanguageId.tamil]) {
        for (final c in ds.getCharacters(lang)) {
          if (LetterStrokes.of(c.symbol) != null) found++;
        }
      }
      expect(found, 0);
    });
  });
}
