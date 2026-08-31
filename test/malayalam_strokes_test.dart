// The hand-authored Malayalam stroke paths.
//
// Every rule here corresponds to something that went visibly wrong at some
// point: a letter with no path, a point outside the canvas, two points close
// enough to make the demo hand flick backwards, or a straight chord jumping
// across the letter because two arcs didn't share an endpoint.

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/tracing/malayalam_strokes.dart';
import 'package:kid_write/data/datasources/character_local_datasource.dart';

void main() {
  final ds = CharacterLocalDataSourceImpl();
  final malayalam = ds.getCharacters(LanguageId.malayalam);

  test('all 51 characters are guided', () {
    for (final c in malayalam) {
      expect(
        MalayalamStrokes.of(c.symbol),
        isNotNull,
        reason: 'no guide path for ${c.symbol}',
      );
      expect(
        MalayalamStrokes.shapeOf(c.symbol),
        isNotNull,
        reason: 'no shape path for ${c.symbol}',
      );
      expect(
        MalayalamStrokes.bodyWidth(c.symbol),
        isNotNull,
        reason: 'no pen width for ${c.symbol}',
      );
    }
  });

  test('paths are normalised to the canvas', () {
    for (final c in malayalam) {
      for (final stroke in MalayalamStrokes.of(c.symbol)!) {
        for (final p in stroke) {
          expect(p.dx, inInclusiveRange(0, 1), reason: '${c.symbol} x');
          expect(p.dy, inInclusiveRange(0, 1), reason: '${c.symbol} y');
        }
      }
    }
  });

  test('no stroke is degenerate', () {
    for (final c in malayalam) {
      for (final stroke in MalayalamStrokes.of(c.symbol)!) {
        expect(
          stroke.length,
          greaterThanOrEqualTo(2),
          reason: '${c.symbol} has a stroke with fewer than 2 points',
        );
      }
    }
  });

  test('consecutive points are far enough apart to give a direction', () {
    // Two points a fraction of a pixel apart produce a meaningless direction
    // vector, and the demo hand flicks backwards on that frame. The generator
    // enforces a minimum spacing of 0.009.
    const minGap = 0.008;
    for (final c in malayalam) {
      for (final stroke in MalayalamStrokes.of(c.symbol)!) {
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
    // A single constant is wrong — wide letters shrink to fit and need a
    // thinner pen — but a width outside this range means the ink mask is
    // either invisible or far fatter than the letter.
    for (final c in malayalam) {
      final w = MalayalamStrokes.bodyWidth(c.symbol)!;
      expect(w, inInclusiveRange(0.02, 0.2), reason: '${c.symbol} width $w');
    }
  });

  test('the shape covers at least as much as the guide', () {
    // The guide may cut a retraced stretch; the shape never may, or the drawn
    // letter comes out with holes in it.
    for (final c in malayalam) {
      final guide = MalayalamStrokes.of(c.symbol)!;
      final shape = MalayalamStrokes.shapeOf(c.symbol)!;
      final guidePoints = guide.fold<int>(0, (n, s) => n + s.length);
      final shapePoints = shape.fold<int>(0, (n, s) => n + s.length);
      expect(
        shapePoints,
        greaterThanOrEqualTo(guidePoints),
        reason: '${c.symbol}: shape is shorter than the guide',
      );
    }
  });
}
