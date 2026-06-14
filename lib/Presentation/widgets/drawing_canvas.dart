import 'package:flutter/material.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/character.dart';

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
  });

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
          child: CustomPaint(
            size: Size(canvasSize, canvasSize),
            painter: _CanvasPainter(
              character: character,
              strokes: strokes,
              currentStroke: currentStroke,
              isSuccess: isSuccess,
              accentColor: accentColor,
            ),
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

  _CanvasPainter({
    required this.character,
    required this.strokes,
    required this.currentStroke,
    required this.isSuccess,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGuide(canvas, size);
    _drawStrokes(canvas, size);
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
  void _drawStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSuccess ? AppColors.successColor : AppColors.strokeColor
      ..strokeWidth = AppConstants.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> points) {
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

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  String? _fontFamily() {
    const map = {
      'malayalam': 'NotoSansMalayalam',
      'hindi': 'NotoSansDevanagari',
      'tamil': 'NotoSansTamil',
    };
    return map[character.languageId];
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes != strokes ||
          old.currentStroke != currentStroke ||
          old.isSuccess != isSuccess;
}
