import 'package:flutter/material.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/character.dart';
import 'tracing_hand.dart';

class DrawingCanvas extends StatelessWidget {
  final Character character;
  final double canvasSize;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final bool isSuccess;
  final Color accentColor;
  final void Function(Offset) onStrokeStart;
  final void Function(Offset) onStrokeUpdate;
  final void Function() onStrokeEnd;

  /// Width of the child's ink (canvas px). Sized to a fraction of the
  /// letter's own path thickness so the ink fills the letter nicely.
  final double strokeWidth;

  /// Guided tracing (English & numbers): strokes in school writing order,
  /// normalized 0..1 and aligned to the glyph. Empty → free tracing.
  final List<List<Offset>> guideStrokes;
  final int targetStrokeIndex;

  /// Show the animated pointing-hand demo for the current stroke.
  final bool showHand;

  /// Show the dotted guide line for the current stroke (off in the
  /// third-star "from memory" attempt).
  final bool showGuideDots;

  const DrawingCanvas({
    super.key,
    required this.character,
    required this.canvasSize,
    required this.strokes,
    required this.currentStroke,
    required this.isSuccess,
    required this.accentColor,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    this.strokeWidth = AppConstants.strokeWidth,
    this.guideStrokes = const [],
    this.targetStrokeIndex = 0,
    this.showHand = false,
    this.showGuideDots = true,
  });

  bool get _hasTarget =>
      guideStrokes.isNotEmpty && targetStrokeIndex < guideStrokes.length;

  List<Offset> _scaledTarget() => guideStrokes[targetStrokeIndex]
      .map((p) => Offset(p.dx * canvasSize, p.dy * canvasSize))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: canvasSize,
      height: canvasSize,
      decoration: BoxDecoration(
        color: AppColors.canvasBg,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isSuccess
              ? AppColors.successColor
              : accentColor.withValues(alpha: 0.3),
          width: isSuccess ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: GestureDetector(
          onPanStart: (d) => onStrokeStart(d.localPosition),
          onPanUpdate: (d) => onStrokeUpdate(d.localPosition),
          onPanEnd: (_) => onStrokeEnd(),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(canvasSize, canvasSize),
                painter: _CanvasPainter(
                  character: character,
                  strokes: strokes,
                  currentStroke: currentStroke,
                  isSuccess: isSuccess,
                  accentColor: accentColor,
                  strokeWidth: strokeWidth,
                  guideStrokes: guideStrokes,
                  targetStrokeIndex: targetStrokeIndex,
                  showGuideDots: showGuideDots,
                ),
              ),
              if (showHand && _hasTarget)
                TracingHand(
                  stroke: _scaledTarget(),
                  color: accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final Character character;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final bool isSuccess;
  final Color accentColor;
  final double strokeWidth;
  final List<List<Offset>> guideStrokes;
  final int targetStrokeIndex;
  final bool showGuideDots;

  _CanvasPainter({
    required this.character,
    required this.strokes,
    required this.currentStroke,
    required this.isSuccess,
    required this.accentColor,
    required this.strokeWidth,
    required this.guideStrokes,
    required this.targetStrokeIndex,
    required this.showGuideDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (guideStrokes.isNotEmpty) {
      // Guided mode: the letter body is drawn FROM the guide paths
      // themselves, so the letter and the traced path always match exactly.
      _drawLetterFromStrokes(canvas, size);
    } else {
      _drawGuide(canvas, size);
    }
    _drawTargetHint(canvas, size);
    _drawStrokes(canvas, size);
  }

  /// Chunky rounded letter built from the guide strokes — same geometry the
  /// dots and the hand follow, inflated to the letter's path thickness.
  void _drawLetterFromStrokes(Canvas canvas, Size size) {
    final bodyWidth = strokeWidth / AppConstants.inkWidthFactor;

    Path pathOf(List<Offset> stroke) {
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * size.width, stroke[i].dy * size.height);
      }
      return path;
    }

    Paint bodyPaint(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Offset scaled(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    // Outline pass first, fill pass second, so overlapping strokes merge
    // into one clean letter body. Single-point strokes (the dot on i / j)
    // become circles.
    final outlineWidth = bodyWidth + AppConstants.guideStrokeWidth * 2;
    final outline = bodyPaint(AppColors.guideStroke, outlineWidth);
    for (final s in guideStrokes) {
      if (s.length >= 2) {
        canvas.drawPath(pathOf(s), outline);
      } else if (s.isNotEmpty) {
        canvas.drawCircle(scaled(s.first), outlineWidth / 2,
            Paint()..color = AppColors.guideStroke);
      }
    }
    final fill = bodyPaint(AppColors.guideColor, bodyWidth);
    for (final s in guideStrokes) {
      if (s.length >= 2) {
        canvas.drawPath(pathOf(s), fill);
      } else if (s.isNotEmpty) {
        canvas.drawCircle(scaled(s.first), bodyWidth / 2,
            Paint()..color = AppColors.guideColor);
      }
    }
  }

  /// Shows the stroke the child should draw now as a dotted guide line
  /// along the path (classic tracing-book style).
  void _drawTargetHint(Canvas canvas, Size size) {
    if (!showGuideDots ||
        guideStrokes.isEmpty ||
        targetStrokeIndex >= guideStrokes.length ||
        isSuccess) {
      return;
    }
    final pts = guideStrokes[targetStrokeIndex]
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    if (pts.length < 2) return;

    final dotRadius = strokeWidth * 0.18;
    final spacing = dotRadius * 3.2;
    final dotFill = Paint()..color = Colors.white;
    final dotEdge = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotRadius * 0.35;

    void dot(Offset c) {
      canvas.drawCircle(c, dotRadius, dotFill);
      canvas.drawCircle(c, dotRadius, dotEdge);
    }

    // Evenly spaced dots along the path's arc length.
    dot(pts.first);
    double carry = 0;
    for (int i = 1; i < pts.length; i++) {
      final seg = pts[i] - pts[i - 1];
      final segLen = seg.distance;
      if (segLen == 0) continue;
      double d = spacing - carry;
      while (d <= segLen) {
        dot(pts[i - 1] + seg * (d / segLen));
        d += spacing;
      }
      carry = segLen - (d - spacing);
    }
  }

  // ── Guide character (faded background) ──────────────────────────────────
  void _drawGuide(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: character.symbol,
        style: TextStyle(
          fontSize: size.width * 0.72,
          color: AppColors.guideColor,
          fontWeight: FontWeight.w900,
          fontFamily: _fontFamily(),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final offset = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );
    tp.paint(canvas, offset);

    // Dotted outline by painting text in stroke mode
    final borderPainter = TextPainter(
      text: TextSpan(
        text: character.symbol,
        style: TextStyle(
          fontSize: size.width * 0.72,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppConstants.guideStrokeWidth
            ..color = AppColors.guideStroke,
          fontWeight: FontWeight.w900,
          fontFamily: _fontFamily(),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    borderPainter.paint(canvas, offset);
  }

  // ── Drawn strokes ─────────────────────────────────────────────────────────

  /// Fun crayon palette — each stroke gets its own colour.
  static const _crayons = [
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFB8C00), // orange
    Color(0xFF8E24AA), // purple
    Color(0xFF00ACC1), // teal
    Color(0xFFD81B60), // pink
  ];

  Color _strokeColor(int strokeIndex) {
    // Seed by character so each letter starts on a different colour —
    // feels random, but stays stable across repaints.
    final seed = character.symbol.hashCode & 0x7fffffff;
    return _crayons[(seed + strokeIndex) % _crayons.length];
  }

  void _drawStrokes(Canvas canvas, Size size) {
    Paint paintFor(int strokeIndex) => Paint()
      ..color = _strokeColor(strokeIndex)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> points, Paint paint) {
      if (points.isEmpty) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        if (i < points.length - 1) {
          final mid = Offset(
            (points[i].dx + points[i + 1].dx) / 2,
            (points[i].dy + points[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(
              points[i].dx, points[i].dy, mid.dx, mid.dy);
        } else {
          path.lineTo(points[i].dx, points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < strokes.length; i++) {
      drawStroke(strokes[i], paintFor(i));
    }
    drawStroke(currentStroke, paintFor(strokes.length));
  }

  String? _fontFamily() {
    const map = {
      'malayalam': 'NotoSansMalayalam',
      'hindi': 'NotoSansDevanagari',
      'tamil': 'NotoSansTamil',
      // School-style print letterforms for beginners (single-story a, g).
      'english': 'Andika',
      'numbers': 'Andika',
    };
    return map[character.languageId];
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes != strokes ||
          old.currentStroke != currentStroke ||
          old.isSuccess != isSuccess ||
          old.strokeWidth != strokeWidth ||
          old.guideStrokes != guideStrokes ||
          old.targetStrokeIndex != targetStrokeIndex ||
          old.showGuideDots != showGuideDots;
}
