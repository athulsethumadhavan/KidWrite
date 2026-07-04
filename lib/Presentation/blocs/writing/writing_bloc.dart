import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/tracing/letter_strokes.dart';

import '../../../domain/entities/character.dart';

part 'writing_event.dart';
part 'writing_state.dart';

class WritingBloc extends Bloc<WritingEvent, WritingState> {
  WritingBloc() : super(const WritingState()) {
    on<WritingLoadCharacter>(_onLoad);
    on<WritingStrokeStarted>(_onStrokeStarted);
    on<WritingStrokeUpdated>(_onStrokeUpdated);
    on<WritingStrokeEnded>(_onStrokeEnded);
    on<WritingCheckAccuracy>(_onCheckAccuracy);
    on<WritingClear>(_onClear);
    on<WritingNextCharacter>(_onNext);
  }

  Future<void> _onLoad(
      WritingLoadCharacter event, Emitter<WritingState> emit) async {
    emit(WritingState(character: event.character));
    final guide = _guideStrokesFor(event.character);
    if (guide.isNotEmpty) {
      _buildMaskFromStrokes(guide);
      emit(state.copyWith(
        guideStrokes: guide,
        targetStrokeIndex: 0,
        glyphStrokeWidth: _craftedBodyWidth,
      ));
      return;
    }
    final thickness = await _buildMask(event.character);
    if (state.character?.id == event.character.id && thickness > 0) {
      emit(state.copyWith(glyphStrokeWidth: thickness));
    }
  }

  /// Guide strokes for English & numbers: the clean hand-crafted school
  /// letterforms, used directly. The displayed letter, the dots, the hand
  /// and the ink mask are ALL built from this same geometry, so nothing can
  /// ever mismatch. (The bundled font is only used for Indic free-tracing.)
  List<List<Offset>> _guideStrokesFor(Character character) {
    if (character.languageId != 'english' &&
        character.languageId != 'numbers') {
      return const [];
    }
    final crafted = LetterStrokes.of(character.symbol);
    if (crafted == null) return const [];
    // Scale the letter down around the canvas centre.
    const center = Offset(0.5, 0.5);
    return [
      for (final s in crafted)
        _densifyPts(
          [for (final p in s) center + (p - center) * _craftedScale],
          2.0 / _res,
        ),
    ];
  }

  /// Overall letter size (1.0 = original crafted size).
  static const double _craftedScale = 0.8;

  /// Uniform path thickness of the crafted letters (fraction of canvas),
  /// scaled along with the letter size.
  static const double _craftedBodyWidth = 0.10 * _craftedScale;

  /// Ink-confinement mask stamped directly from the guide strokes.
  void _buildMaskFromStrokes(List<List<Offset>> strokes) {
    final mask = List<bool>.filled(_res * _res, false);
    final r = ((_craftedBodyWidth / 2 + 0.03) * _res).round();
    for (final s in strokes) {
      for (final pt in s) {
        final cx = (pt.dx * _res).round(), cy = (pt.dy * _res).round();
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            if (dx * dx + dy * dy > r * r) continue;
            final x = cx + dx, y = cy + dy;
            if (x >= 0 && x < _res && y >= 0 && y < _res) {
              mask[y * _res + x] = true;
            }
          }
        }
      }
    }
    _glyphMask = mask;
  }

  /// Interpolates points along a polyline at ~[step] spacing.
  List<Offset> _densifyPts(List<Offset> pts, double step) {
    if (pts.length < 2) return pts;
    final out = <Offset>[pts.first];
    for (int i = 1; i < pts.length; i++) {
      final d = (pts[i] - pts[i - 1]).distance;
      final n = math.max(1, (d / step).ceil());
      for (int s = 1; s <= n; s++) {
        out.add(Offset.lerp(pts[i - 1], pts[i], s / n)!);
      }
    }
    return out;
  }

  void _onStrokeStarted(
      WritingStrokeStarted event, Emitter<WritingState> emit) {
    // Self-heal: rebuild the mask if it's missing (e.g. after hot reload).
    if (_glyphMask == null && state.character != null && !_maskBuilding) {
      if (state.isGuided) {
        _buildMaskFromStrokes(state.guideStrokes);
      } else {
        _maskBuilding = true;
        _buildMask(state.character!)
            .whenComplete(() => _maskBuilding = false);
      }
    }
    // Ink only registers inside the letter shape.
    if (!_insideGlyph(event.point, event.canvasSize)) return;
    emit(state.copyWith(
      currentStroke: [event.point],
      status: WritingStatus.drawing,
      strokeMissed: false,
    ));
  }

  void _onStrokeUpdated(
      WritingStrokeUpdated event, Emitter<WritingState> emit) {
    final inside = _insideGlyph(event.point, event.canvasSize);

    // Finger started outside the letter and just entered it.
    if (state.currentStroke.isEmpty) {
      if (inside) {
        emit(state.copyWith(
          currentStroke: [event.point],
          status: WritingStatus.drawing,
        ));
      }
      return;
    }

    // Outside the letter: don't record (pen "skips" outside the shape).
    if (!inside) return;

    // Re-entering after a hop across an outside region — break the stroke so
    // no line is drawn through the gap.
    final last = state.currentStroke.last;
    if ((event.point - last).distance > event.canvasSize * 0.08) {
      final allStrokes = List<List<Offset>>.from(state.strokes)
        ..add(List.from(state.currentStroke));
      emit(state.copyWith(
        strokes: allStrokes,
        currentStroke: [event.point],
      ));
      return;
    }

    final updated = List<Offset>.from(state.currentStroke)
      ..add(event.point);
    emit(state.copyWith(currentStroke: updated));
  }

  void _onStrokeEnded(
      WritingStrokeEnded event, Emitter<WritingState> emit) {
    if (state.currentStroke.isEmpty) return;

    // ── Guided mode (English & numbers): validate against the stroke the
    // hand just demonstrated; advance stroke-by-stroke. ──
    if (state.isGuided &&
        state.targetStrokeIndex < state.guideStrokes.length &&
        state.status != WritingStatus.success) {
      final size = event.canvasSize.width;
      final target = state.guideStrokes[state.targetStrokeIndex]
          .map((p) => Offset(p.dx * size, p.dy * size))
          .toList();

      final match = _guidedMatch(state.currentStroke, target, size);
      if (match >= 0.55) {
        final allStrokes = List<List<Offset>>.from(state.strokes)
          ..add(List.from(state.currentStroke));
        final nextIndex = state.targetStrokeIndex + 1;
        final newAccuracy =
            (state.accuracy * state.targetStrokeIndex + match) / nextIndex;
        final finished = nextIndex >= state.guideStrokes.length;
        emit(state.copyWith(
          strokes: allStrokes,
          currentStroke: [],
          targetStrokeIndex: nextIndex,
          accuracy: newAccuracy,
          status: finished ? WritingStatus.success : WritingStatus.idle,
          attemptCount:
          finished ? state.attemptCount + 1 : state.attemptCount,
        ));
      } else {
        // Didn't follow the demonstrated line — discard and replay demo.
        emit(state.copyWith(
          currentStroke: [],
          status: WritingStatus.idle,
          strokeMissed: true,
        ));
      }
      return;
    }

    // ── Free mode (Indic scripts): record; Done button checks accuracy. ──
    final allStrokes = List<List<Offset>>.from(state.strokes)
      ..add(List.from(state.currentStroke));
    emit(state.copyWith(strokes: allStrokes, currentStroke: []));
  }

  /// How well [drawn] traces [target] (both canvas coords), 0..1.
  /// Coverage in both directions: the drawn ink must lie on the target line
  /// AND the target line must be covered end-to-end.
  double _guidedMatch(List<Offset> drawn, List<Offset> target, double size) {
    if (drawn.isEmpty || target.isEmpty) return 0;
    final tol = size * 0.09;

    // Densify (fast swipes leave sparse points; a single tap stays a
    // single point — enough to cover a dot like the one on i / j).
    final dense = <Offset>[drawn.first];
    for (int i = 1; i < drawn.length; i++) {
      final d = (drawn[i] - drawn[i - 1]).distance;
      final steps = math.max(1, (d / (tol / 2)).ceil());
      for (int s = 1; s <= steps; s++) {
        dense.add(Offset.lerp(drawn[i - 1], drawn[i], s / steps)!);
      }
    }

    int drawnNear = 0;
    for (final p in dense) {
      for (final g in target) {
        if ((g - p).distance <= tol) {
          drawnNear++;
          break;
        }
      }
    }
    int targetCovered = 0;
    for (final g in target) {
      for (final p in dense) {
        if ((p - g).distance <= tol) {
          targetCovered++;
          break;
        }
      }
    }
    final precision = drawnNear / dense.length;
    final recall = targetCovered / target.length;
    if (precision < 0.5 || recall < 0.5) return math.min(precision, recall);
    return (precision + recall) / 2;
  }

  Future<void> _onCheckAccuracy(
      WritingCheckAccuracy event, Emitter<WritingState> emit) async {
    // Finalise any in-progress stroke (finger still down when Done! tapped)
    var strokes = state.strokes;
    if (state.currentStroke.isNotEmpty) {
      strokes = [...strokes, List.from(state.currentStroke)];
    }
    if (strokes.isEmpty) return;
    if (state.character == null) return;

    // Show a "checking" spinner while pixel comparison runs
    emit(state.copyWith(status: WritingStatus.checking));

    final accuracy = await _pixelAccuracy(
      strokes: strokes,
      canvasSize: event.canvasSize,
      character: state.character!,
    );

    final isSuccess = accuracy >= AppConstants.successThreshold;
    emit(state.copyWith(
      strokes: strokes,
      currentStroke: [],
      status: isSuccess ? WritingStatus.success : WritingStatus.failure,
      accuracy: accuracy,
      attemptCount: state.attemptCount + 1,
    ));
  }

  void _onClear(WritingClear event, Emitter<WritingState> emit) {
    emit(state.copyWith(
      strokes: [],
      currentStroke: [],
      status: WritingStatus.idle,
      accuracy: 0,
      targetStrokeIndex: 0,
      strokeMissed: false,
    ));
  }

  Future<void> _onNext(
      WritingNextCharacter event, Emitter<WritingState> emit) async {
    emit(WritingState(character: event.character));
    final guide = _guideStrokesFor(event.character);
    if (guide.isNotEmpty) {
      _buildMaskFromStrokes(guide);
      emit(state.copyWith(
        guideStrokes: guide,
        targetStrokeIndex: 0,
        glyphStrokeWidth: _craftedBodyWidth,
      ));
      return;
    }
    final thickness = await _buildMask(event.character);
    if (state.character?.id == event.character.id && thickness > 0) {
      emit(state.copyWith(glyphStrokeWidth: thickness));
    }
  }

  // ---------------------------------------------------------------------------
  // Glyph mask — confines ink to the letter shape.
  //
  // The character is rendered offscreen once per load; a dilated boolean mask
  // marks "inside the letter (plus a small tolerance)". Touch points outside
  // the mask are ignored, so scribbling across the canvas puts down no ink —
  // and therefore can no longer reach the success threshold.
  // ---------------------------------------------------------------------------
  List<bool>? _glyphMask;
  bool _maskBuilding = false;

  /// Builds the ink-confinement mask and returns the letter's average path
  /// thickness as a fraction of the canvas side (ink area ÷ skeleton
  /// length), or 0 on failure.
  Future<double> _buildMask(Character character) async {
    _glyphMask = null;
    try {
      final recorder = ui.PictureRecorder();
      final offCanvas = Canvas(recorder);
      final tp = TextPainter(
        text: TextSpan(
          text: character.symbol,
          style: TextStyle(
            fontSize: _res * 0.72,
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontFamily: _fontFamily(character.languageId),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _res.toDouble());
      tp.paint(
        offCanvas,
        Offset((_res - tp.width) / 2, (_res - tp.height) / 2),
      );
      final image = await recorder.endRecording().toImage(_res, _res);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (byteData == null) return 0;

      final base = List<bool>.filled(_res * _res, false);
      int inkCount = 0;
      for (int i = 0; i < _res * _res; i++) {
        if (byteData.getUint8(i * 4 + 3) > 30) {
          base[i] = true;
          inkCount++;
        }
      }
      if (inkCount == 0) return 0;

      // Dilate by ~4% of the canvas so little fingers get a fair margin.
      const r = 5;
      final dilated = List<bool>.of(base);
      for (int y = 0; y < _res; y++) {
        for (int x = 0; x < _res; x++) {
          if (!base[y * _res + x]) continue;
          for (int dy = -r; dy <= r; dy++) {
            for (int dx = -r; dx <= r; dx++) {
              if (dx * dx + dy * dy > r * r) continue;
              final px = x + dx, py = y + dy;
              if (px >= 0 && px < _res && py >= 0 && py < _res) {
                dilated[py * _res + px] = true;
              }
            }
          }
        }
      }
      _glyphMask = dilated;

      // Mean path thickness ≈ ink area / centerline (skeleton) length —
      // used for the adaptive ink width in free-tracing mode.
      final skelCount = _thin(base, _res, _res).where((v) => v).length;
      if (skelCount == 0) return 0;
      return (inkCount / skelCount) / _res;
    } catch (_) {
      _glyphMask = null; // fail open: accept all ink
      return 0;
    }
  }

  List<Offset> _resamplePoints(List<Offset> pts, double step) {
    if (pts.length < 2) return pts;
    final out = <Offset>[pts.first];
    double acc = 0;
    for (int i = 1; i < pts.length; i++) {
      acc += (pts[i] - pts[i - 1]).distance;
      if (acc >= step) {
        out.add(pts[i]);
        acc = 0;
      }
    }
    if (out.last != pts.last) out.add(pts.last);
    return out;
  }

  bool _insideGlyph(Offset p, double canvasSize) {
    final mask = _glyphMask;
    if (mask == null || canvasSize <= 0) return true;
    final x = (p.dx / canvasSize * _res).round();
    final y = (p.dy / canvasSize * _res).round();
    if (x < 0 || x >= _res || y < 0 || y >= _res) return false;
    return mask[y * _res + x];
  }

  // ---------------------------------------------------------------------------
  // Direction-aligned tracing accuracy
  //
  // Coverage alone can't tell tracing from scribbling — a dense doodle also
  // covers the letter. Real tracing has one more property: the ink runs
  // ALONG the letter's strokes. So:
  //
  // 1. Render the character offscreen and thin it to a 1-px skeleton.
  // 2. Compute the local tangent direction at every skeleton pixel.
  // 3. Sample the child's ink as (position, direction) segments.
  // 4. recall    = fraction of skeleton pixels whose nearby ink runs, on
  //                average, parallel to the letter (mean |cos| ≥ 0.7).
  //    precision = fraction of ink that lies on the skeleton and is aligned.
  //    accuracy  = recall × precision.
  //
  // Tuned by simulation: loopy doodles, jagged scribbles and zigzag filling
  // all score ≤ 0.55, while honest traces (even ±20 px drift) score ≥ 0.8.
  // ---------------------------------------------------------------------------
  static const int _res = 120; // offscreen render resolution

  Future<double> _pixelAccuracy({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    required Character character,
  }) async {
    double strokeLen(List<Offset> s) {
      double d = 0;
      for (int i = 1; i < s.length; i++) {
        d += (s[i] - s[i - 1]).distance;
      }
      return d;
    }

    // Ignore accidental short fragments (the glyph mask chops scribbles
    // into these each time they cross the letter).
    strokes = strokes
        .where((s) => strokeLen(s) >= canvasSize.width * 0.15)
        .toList();
    if (strokes.isEmpty) return 0.05;

    try {
      // ── Render character to offscreen bitmap ────────────────────────────
      final recorder = ui.PictureRecorder();
      final offCanvas = Canvas(recorder);

      final tp = TextPainter(
        text: TextSpan(
          text: character.symbol,
          style: TextStyle(
            fontSize: _res * 0.72,
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontFamily: _fontFamily(character.languageId),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _res.toDouble());

      tp.paint(
        offCanvas,
        Offset((_res - tp.width) / 2, (_res - tp.height) / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(_res, _res);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null) return _fallback(strokes, canvasSize);

      final glyph = List<bool>.filled(_res * _res, false);
      bool any = false;
      for (int i = 0; i < _res * _res; i++) {
        if (byteData.getUint8(i * 4 + 3) > 30) {
          glyph[i] = true;
          any = true;
        }
      }
      if (!any) return _fallback(strokes, canvasSize);

      // ── Skeleton + tangents ──────────────────────────────────────────────
      final skeleton = _thin(glyph, _res, _res);
      final tangents = _skeletonTangents(skeleton, _res, _res);
      if (tangents.isEmpty) return _fallback(strokes, canvasSize);

      // ── Ink samples: midpoint + unit direction, ~5 grid px apart ────────
      final samples = <List<double>>[]; // [x, y, dx, dy] in grid coords
      for (final s in strokes) {
        final grid = s
            .map((p) => Offset(
          p.dx / canvasSize.width * _res,
          p.dy / canvasSize.height * _res,
        ))
            .toList();
        final r = _resamplePoints(grid, 5.0);
        for (int i = 1; i < r.length; i++) {
          final v = r[i] - r[i - 1];
          final d = v.distance;
          if (d == 0) continue;
          samples.add([
            (r[i].dx + r[i - 1].dx) / 2,
            (r[i].dy + r[i - 1].dy) / 2,
            v.dx / d,
            v.dy / d,
          ]);
        }
      }
      if (samples.isEmpty) return 0.05;

      const tol = 8.0;
      const tol2 = tol * tol;

      // recall: skeleton pixels whose nearby ink is, on average, parallel.
      // Also remember per-pixel results for the branch-completeness check.
      final okByIdx = <int, bool>{};
      int okSkel = 0;
      for (final t in tangents) {
        double sum = 0;
        int n = 0;
        for (final s in samples) {
          final dx = s[0] - t[0], dy = s[1] - t[1];
          if (dx * dx + dy * dy <= tol2) {
            sum += (s[2] * t[2] + s[3] * t[3]).abs();
            n++;
          }
        }
        final ok = n > 0 && sum / n >= 0.7;
        okByIdx[t[1].toInt() * _res + t[0].toInt()] = ok;
        if (ok) okSkel++;
      }
      final recall = okSkel / tangents.length;

      // precision: ink that sits on the skeleton and follows its direction.
      int okInk = 0;
      for (final s in samples) {
        double bestD2 = double.infinity;
        List<double>? nearest;
        for (final t in tangents) {
          final dx = s[0] - t[0], dy = s[1] - t[1];
          final d2 = dx * dx + dy * dy;
          if (d2 < bestD2) {
            bestD2 = d2;
            nearest = t;
          }
        }
        if (nearest != null &&
            bestD2 <= tol2 &&
            (s[2] * nearest[2] + s[3] * nearest[3]).abs() >= 0.55) {
          okInk++;
        }
      }
      final precision = okInk / samples.length;
      double score = (recall * precision).clamp(0.0, 1.0);

      // ── Completeness: EVERY part of the letter must be traced ────────────
      // The skeleton is decomposed into branches (e.g. A = two legs + the
      // crossbar). Leaving out any significant branch caps the score below
      // the success threshold — an incomplete letter never celebrates.
      final branches = _skeletonBranches(skeleton, _res, _res);
      double totalLen = 0;
      for (final b in branches) {
        totalLen += b.length.toDouble();
      }
      for (final b in branches) {
        if (b.length < math.max(6.0, 0.05 * totalLen)) continue; // noise
        int okCount = 0;
        for (final idx in b) {
          if (okByIdx[idx] ?? false) okCount++;
        }
        if (okCount / b.length < 0.55) {
          score = score < 0.5 ? score : 0.5;
        }
      }

      return score;
    } catch (_) {
      return _fallback(strokes, canvasSize);
    }
  }

  /// Zhang–Suen thinning: glyph → 1-px skeleton.
  List<bool> _thin(List<bool> src, int w, int h) {
    final grid = List<bool>.of(src);
    bool at(int x, int y) =>
        x >= 0 && x < w && y >= 0 && y < h && grid[y * w + x];

    bool changed = true;
    while (changed) {
      changed = false;
      for (int step = 0; step < 2; step++) {
        final toRemove = <int>[];
        for (int y = 1; y < h - 1; y++) {
          for (int x = 1; x < w - 1; x++) {
            if (!grid[y * w + x]) continue;
            final p2 = at(x, y - 1);
            final p3 = at(x + 1, y - 1);
            final p4 = at(x + 1, y);
            final p5 = at(x + 1, y + 1);
            final p6 = at(x, y + 1);
            final p7 = at(x - 1, y + 1);
            final p8 = at(x - 1, y);
            final p9 = at(x - 1, y - 1);
            final n = [p2, p3, p4, p5, p6, p7, p8, p9];

            final b = n.where((v) => v).length;
            if (b < 2 || b > 6) continue;

            int a = 0;
            for (int i = 0; i < 8; i++) {
              if (!n[i] && n[(i + 1) % 8]) a++;
            }
            if (a != 1) continue;

            if (step == 0) {
              if ((p2 && p4 && p6) || (p4 && p6 && p8)) continue;
            } else {
              if ((p2 && p4 && p8) || (p2 && p6 && p8)) continue;
            }
            toRemove.add(y * w + x);
          }
        }
        if (toRemove.isNotEmpty) {
          changed = true;
          for (final i in toRemove) {
            grid[i] = false;
          }
        }
      }
    }
    return grid;
  }

  /// Decomposes the skeleton into branches: pixel chains between endpoints
  /// and junctions (pixels whose neighbour count != 2), plus closed loops.
  /// Returns each branch as a list of pixel indices (y * w + x).
  List<List<int>> _skeletonBranches(List<bool> skel, int w, int h) {
    bool on(int x, int y) =>
        x >= 0 && x < w && y >= 0 && y < h && skel[y * w + x];
    const neigh = [
      [0, -1], [1, -1], [1, 0], [1, 1],
      [0, 1], [-1, 1], [-1, 0], [-1, -1],
    ];
    List<int> nbrs(int x, int y) => [
      for (final o in neigh)
        if (on(x + o[0], y + o[1])) (y + o[1]) * w + (x + o[0]),
    ];

    final degree = <int, int>{};
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (on(x, y)) degree[y * w + x] = nbrs(x, y).length;
      }
    }
    final nodes = <int>{
      for (final e in degree.entries)
        if (e.value != 2) e.key,
    };

    final usedSteps = <int>{};
    int stepKey(int from, int to) => from * (w * h) + to;
    final branches = <List<int>>[];

    List<int> walk(int start, int first) {
      final path = <int>[start, first];
      usedSteps.add(stepKey(start, first));
      usedSteps.add(stepKey(first, start));
      var prev = start;
      var cur = first;
      while (!nodes.contains(cur)) {
        int? next;
        for (final nb in nbrs(cur % w, cur ~/ w)) {
          if (nb != prev && !usedSteps.contains(stepKey(cur, nb))) {
            next = nb;
            break;
          }
        }
        if (next == null) break;
        usedSteps.add(stepKey(cur, next));
        usedSteps.add(stepKey(next, cur));
        path.add(next);
        prev = cur;
        cur = next;
      }
      return path;
    }

    final nodeList = nodes.toList()..sort();
    for (final n in nodeList) {
      for (final nb in nbrs(n % w, n ~/ w)) {
        if (!usedSteps.contains(stepKey(n, nb))) {
          branches.add(walk(n, nb));
        }
      }
    }

    // Pure loops (rings with no endpoints/junctions, e.g. O).
    final inBranches = <int>{
      for (final b in branches) ...b,
    };
    for (final entry in degree.entries) {
      if (entry.value != 2 || inBranches.contains(entry.key)) continue;
      final start = entry.key;
      final path = <int>[start];
      int? prev;
      var cur = start;
      while (true) {
        int? next;
        for (final nb in nbrs(cur % w, cur ~/ w)) {
          if (nb != prev) {
            next = nb;
            break;
          }
        }
        if (next == null || next == start) break;
        path.add(next);
        prev = cur;
        cur = next;
        if (path.length > w * h) break;
      }
      inBranches.addAll(path);
      if (path.length > 1) branches.add(path);
    }
    return branches;
  }

  /// For each skeleton pixel: [x, y, tx, ty] where (tx, ty) is the local
  /// tangent — the direction between the two farthest skeleton pixels in a
  /// 9×9 window.
  List<List<double>> _skeletonTangents(List<bool> skel, int w, int h) {
    final pts = <int>[];
    for (int i = 0; i < w * h; i++) {
      if (skel[i]) pts.add(i);
    }
    final out = <List<double>>[];
    for (final i in pts) {
      final x = i % w, y = i ~/ w;
      final nb = <int>[];
      for (int py = y - 4; py <= y + 4; py++) {
        for (int px = x - 4; px <= x + 4; px++) {
          if (px < 0 || px >= w || py < 0 || py >= h) continue;
          if ((px == x && py == y) || !skel[py * w + px]) continue;
          nb.add(py * w + px);
        }
      }
      if (nb.length < 2) continue;
      int bestA = nb.first, bestB = nb.last;
      double bestD = -1;
      for (int a = 0; a < nb.length; a++) {
        for (int b = a + 1; b < nb.length; b++) {
          final ax = nb[a] % w, ay = nb[a] ~/ w;
          final bx = nb[b] % w, by = nb[b] ~/ w;
          final d = ((ax - bx) * (ax - bx) + (ay - by) * (ay - by))
              .toDouble();
          if (d > bestD) {
            bestD = d;
            bestA = nb[a];
            bestB = nb[b];
          }
        }
      }
      final dx = (bestA % w - bestB % w).toDouble();
      final dy = (bestA ~/ w - bestB ~/ w).toDouble();
      final d = math.sqrt(dx * dx + dy * dy);
      if (d == 0) continue;
      out.add([x.toDouble(), y.toDouble(), dx / d, dy / d]);
    }
    return out;
  }

  /// Simple geometric fallback used if offscreen rendering fails.
  double _fallback(List<List<Offset>> strokes, Size canvasSize) {
    final pts = strokes.expand((s) => s).toList();
    if (pts.length < 20) return 0.05;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    final coverage = (maxX - minX) * (maxY - minY) /
        (canvasSize.width * canvasSize.height);
    return (coverage * 0.6).clamp(0.0, 0.80);
  }

  String? _fontFamily(String languageId) {
    const map = {
      'malayalam': 'NotoSansMalayalam',
      'hindi': 'NotoSansDevanagari',
      'tamil': 'NotoSansTamil',
      // School-style print letterforms for beginners (single-story a, g).
      'english': 'Andika',
      'numbers': 'Andika',
    };
    return map[languageId];
  }
}

