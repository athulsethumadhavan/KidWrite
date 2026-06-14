import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

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

  void _onLoad(WritingLoadCharacter event, Emitter<WritingState> emit) {
    emit(WritingState(character: event.character));
  }

  void _onStrokeStarted(
      WritingStrokeStarted event, Emitter<WritingState> emit) {
    emit(state.copyWith(
      currentStroke: [event.point],
      status: WritingStatus.drawing,
    ));
  }

  void _onStrokeUpdated(
      WritingStrokeUpdated event, Emitter<WritingState> emit) {
    final updated = List<Offset>.from(state.currentStroke)
      ..add(event.point);
    emit(state.copyWith(currentStroke: updated));
  }

  void _onStrokeEnded(
      WritingStrokeEnded event, Emitter<WritingState> emit) {
    if (state.currentStroke.isEmpty) return;
    final allStrokes = List<List<Offset>>.from(state.strokes)
      ..add(List.from(state.currentStroke));
    emit(state.copyWith(strokes: allStrokes, currentStroke: []));
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
    ));
  }

  void _onNext(WritingNextCharacter event, Emitter<WritingState> emit) {
    emit(WritingState(character: event.character));
  }

  // ---------------------------------------------------------------------------
  // Pixel-level accuracy
  //
  // 1. Render the guide character to a small (120×120) offscreen bitmap.
  // 2. Collect every pixel that belongs to the character (alpha > 30).
  // 3. For every point the kid drew, mark guide pixels within stroke-radius
  //    as "covered".
  // 4. accuracy = covered / total_guide_pixels.
  //
  // This correctly handles multi-stroke letters: every part of the character
  // must be traced for the coverage ratio to reach the success threshold.
  // ---------------------------------------------------------------------------
  static const int _res = 120; // offscreen render resolution

  Future<double> _pixelAccuracy({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    required Character character,
  }) async {
    // ── Quick minimum-length gate (saves the async render for scribbles) ──
    double totalPath = 0;
    for (final s in strokes) {
      for (int i = 1; i < s.length; i++) {
        totalPath += (s[i] - s[i - 1]).distance;
      }
    }
    if (totalPath < canvasSize.width * 0.10) return 0.05;

    // ── Render character to offscreen bitmap ──────────────────────────────
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

      final picture = recorder.endRecording();
      final image = await picture.toImage(_res, _res);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null) return _fallback(strokes, canvasSize);

      // ── Identify guide pixels (character pixels, alpha > 30) ─────────────
      final guidePixels = <int>{};
      for (int y = 0; y < _res; y++) {
        for (int x = 0; x < _res; x++) {
          final idx = (y * _res + x) * 4;
          final alpha = byteData.getUint8(idx + 3);
          if (alpha > 30) guidePixels.add(y * _res + x);
        }
      }

      if (guidePixels.isEmpty) return _fallback(strokes, canvasSize);

      // ── Map user strokes → reduced resolution, expand by stroke radius ───
      //
      // The kid's stroke is 10 px wide on canvasSize.  In the _res grid:
      //   strokeRadius_pixels = strokeWidth / canvasWidth * _res / 2
      final strokeR =
      (AppConstants.strokeWidth / canvasSize.width * _res / 2)
          .round()
          .clamp(5, 14);

      final covered = <int>{};
      for (final stroke in strokes) {
        for (final pt in stroke) {
          final rx = (pt.dx / canvasSize.width * _res).round();
          final ry = (pt.dy / canvasSize.height * _res).round();
          for (int dy = -strokeR; dy <= strokeR; dy++) {
            for (int dx = -strokeR; dx <= strokeR; dx++) {
              // Use a circular mask so corners aren't over-credited
              if (dx * dx + dy * dy > strokeR * strokeR) continue;
              final px = rx + dx;
              final py = ry + dy;
              if (px >= 0 && px < _res && py >= 0 && py < _res) {
                covered.add(py * _res + px);
              }
            }
          }
        }
      }

      final coverageRatio =
          guidePixels.intersection(covered).length / guidePixels.length;

      return coverageRatio.clamp(0.0, 1.0);
    } catch (_) {
      return _fallback(strokes, canvasSize);
    }
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
    };
    return map[languageId];
  }
}

