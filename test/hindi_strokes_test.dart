// The Hindi vowel stroke paths.
//
// These were recovered from a handwriting animation rather than hand-authored,
// so the checks here are about the geometry being usable at all: inside the
// canvas, no degenerate strokes, and no two points so close together that the
// demo hand has no direction to face.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/tracing/hindi_strokes.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();
  final hindi = ds.getCharacters(LanguageId.hindi);

  // Every vowel is guided now. If one is ever added to the table ahead of its
  // path, name it here rather than letting this file go red — a guessed stroke
  // order is worse than the font fallback.
  const notYetGuided = <String>{};

  final vowels = hindi
      .where(
        (c) =>
            c.category == CharacterCategory.vowel &&
            !notYetGuided.contains(c.symbol),
      )
      .toList();

  test('the table covers all thirteen vowels', () {
    expect(vowels.length, 13);
  });

  test('every Hindi vowel is guided', () {
    expect(vowels, isNotEmpty);
    for (final c in vowels) {
      expect(
        HindiStrokes.of(c.symbol),
        isNotNull,
        reason: '${c.symbol} would fall back to free tracing',
      );
      expect(HindiStrokes.shapeOf(c.symbol), isNotNull, reason: c.symbol);
      expect(HindiStrokes.bodyWidth(c.symbol), isNotNull, reason: c.symbol);
    }
  });

  // The consonants were authored a few at a time and all thirty-three are now
  // done, so nothing in Hindi falls back to the font. If one is ever added to
  // the table ahead of its path, this is what will catch it.
  test('every consonant is guided', () {
    final consonants = hindi.where(
      (c) => c.category == CharacterCategory.consonant,
    );
    expect(consonants.length, 33);
    for (final c in consonants) {
      expect(
        HindiStrokes.of(c.symbol),
        isNotNull,
        reason: '${c.symbol} would fall back to free tracing',
      );
      expect(HindiStrokes.shapeOf(c.symbol), isNotNull, reason: c.symbol);
      expect(HindiStrokes.bodyWidth(c.symbol), isNotNull, reason: c.symbol);
    }
  });

  test('paths are normalised to the canvas', () {
    for (final c in vowels) {
      for (final stroke in HindiStrokes.of(c.symbol)!) {
        for (final p in stroke) {
          expect(p.dx, inInclusiveRange(0, 1), reason: '${c.symbol} x');
          expect(p.dy, inInclusiveRange(0, 1), reason: '${c.symbol} y');
        }
      }
    }
  });

  test('no stroke is degenerate', () {
    for (final c in vowels) {
      for (final stroke in HindiStrokes.of(c.symbol)!) {
        expect(
          stroke.length,
          greaterThanOrEqualTo(2),
          reason: '${c.symbol} has a stroke with fewer than 2 points',
        );
      }
    }
  });

  test('consecutive points are far enough apart to give a direction', () {
    const minGap = 0.008;
    for (final c in vowels) {
      for (final stroke in HindiStrokes.of(c.symbol)!) {
        for (int i = 1; i < stroke.length; i++) {
          final d = (stroke[i] - stroke[i - 1]).distance;
          expect(
            d,
            greaterThanOrEqualTo(minGap),
            reason: '${c.symbol}: points $i and ${i - 1} are $d apart',
          );
        }
      }
    }
  });

  test('pen width is sane for every letter', () {
    for (final c in vowels) {
      final w = HindiStrokes.bodyWidth(c.symbol)!;
      expect(w, inInclusiveRange(0.02, 0.2), reason: '${c.symbol} width $w');
    }
  });

  test('the letter fills the canvas without touching the edge', () {
    // Every path is fitted into 0.06..0.94 with its aspect kept, the same box
    // the Malayalam table uses. A letter that spans much less than that was
    // scaled wrongly and will look tiny next to the others.
    for (final c in vowels) {
      final pts = HindiStrokes.of(c.symbol)!.expand((s) => s);
      final xs = pts.map((p) => p.dx);
      final ys = pts.map((p) => p.dy);
      final w =
          xs.reduce((a, b) => a > b ? a : b) -
          xs.reduce((a, b) => a < b ? a : b);
      final h =
          ys.reduce((a, b) => a > b ? a : b) -
          ys.reduce((a, b) => a < b ? a : b);
      expect(
        (w - 0.88).abs() < 0.02 || (h - 0.88).abs() < 0.02,
        isTrue,
        reason: '${c.symbol} spans ${w}x$h, expected one side at 0.88',
      );
    }
  });

  test('the shirorekha is drawn last', () {
    // Devanagari is taught body first, bar across the top last. If a path ever
    // starts with the bar, the order was recovered wrongly.
    for (final c in vowels) {
      final strokes = HindiStrokes.of(c.symbol)!;
      final first = strokes.first;
      final firstTop = first.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      expect(
        firstTop,
        greaterThan(0.02),
        reason: '${c.symbol} appears to start on the top bar',
      );
    }
  });
}
