// The Tamil stroke paths.
//
// Only the vowels are authored so far. The letterforms come from the bundled
// Noto glyph — there is no handwriting to trace for Tamil — so these checks
// are about the geometry being usable at all: inside the canvas, no degenerate
// strokes, and no two points so close together that the demo hand has no
// direction to face.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/tracing/tamil_strokes.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';
import 'package:kid_write/domain/entities/character.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();
  final tamil = ds.getCharacters(LanguageId.tamil);
  final vowels = tamil
      .where((c) => c.category == CharacterCategory.vowel)
      .toList();

  test('the table covers all twelve vowels', () {
    expect(vowels.length, 12);
  });

  test('every Tamil vowel is guided', () {
    for (final c in vowels) {
      expect(
        TamilStrokes.of(c.symbol),
        isNotNull,
        reason: '${c.symbol} would fall back to free tracing',
      );
      expect(TamilStrokes.shapeOf(c.symbol), isNotNull, reason: c.symbol);
      expect(TamilStrokes.bodyWidth(c.symbol), isNotNull, reason: c.symbol);
    }
  });

  // All twenty-two are done now, so nothing in Tamil falls back to the font.
  // If one is ever added to the table ahead of its path, this catches it.
  test('every consonant is guided', () {
    final consonants = tamil.where(
      (c) => c.category == CharacterCategory.consonant,
    );
    expect(consonants.length, 22);
    for (final c in consonants) {
      expect(
        TamilStrokes.of(c.symbol),
        isNotNull,
        reason: '${c.symbol} would fall back to free tracing',
      );
      expect(TamilStrokes.shapeOf(c.symbol), isNotNull, reason: c.symbol);
      expect(TamilStrokes.bodyWidth(c.symbol), isNotNull, reason: c.symbol);
    }
  });

  test('paths are normalised to the canvas', () {
    for (final c in vowels) {
      for (final stroke in TamilStrokes.of(c.symbol)!) {
        for (final p in stroke) {
          expect(p.dx, inInclusiveRange(0, 1), reason: '${c.symbol} x');
          expect(p.dy, inInclusiveRange(0, 1), reason: '${c.symbol} y');
        }
      }
    }
  });

  test('no stroke is degenerate', () {
    for (final c in vowels) {
      for (final stroke in TamilStrokes.of(c.symbol)!) {
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
      for (final stroke in TamilStrokes.of(c.symbol)!) {
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
      final w = TamilStrokes.bodyWidth(c.symbol)!;
      expect(w, inInclusiveRange(0.02, 0.2), reason: '${c.symbol} width $w');
    }
  });

  test('the letter fills the canvas without touching the edge', () {
    // Every path is fitted into 0.06..0.94 with its aspect kept, the same box
    // the Malayalam and Hindi tables use. A letter that spans much less than
    // that was scaled wrongly and will look tiny next to the others.
    for (final c in vowels) {
      final pts = TamilStrokes.of(c.symbol)!.expand((s) => s);
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
}
