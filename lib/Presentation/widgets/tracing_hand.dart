import 'package:flutter/material.dart';

/// Animated demo overlay: a cartoon pointing hand travels along the current
/// target stroke, "drawing" it as it goes, then pauses and repeats — showing
/// the child exactly how to trace the line.
///
/// Wrapped in [IgnorePointer] so it never blocks the child's touches.
class TracingHand extends StatefulWidget {
  /// Target stroke in canvas coordinates.
  final List<Offset> stroke;
  final Color color;
  final double handSize;

  const TracingHand({
    super.key,
    required this.stroke,
    required this.color,
    this.handSize = 52,
  });

  @override
  State<TracingHand> createState() => _TracingHandState();
}

class _TracingHandState extends State<TracingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progress;

  /// Demo duration scales with stroke length so long continuous lines
  /// (Malayalam!) are demonstrated at a followable pace.
  Duration _durationFor(List<Offset> stroke) {
    double len = 0;
    for (int i = 1; i < stroke.length; i++) {
      len += (stroke[i] - stroke[i - 1]).distance;
    }
    final ms = (900 + len * 6).clamp(1200.0, 6500.0);
    return Duration(milliseconds: ms.round());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.stroke),
    )..repeat();
    // Trace for 75% of the cycle, hold at the end for 25% (breathing room).
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TracingHand old) {
    super.didUpdateWidget(old);
    if (!identical(old.stroke, widget.stroke)) {
      _controller
        ..duration = _durationFor(widget.stroke)
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Point at fraction [t] (0..1) along the stroke's arc length.
  Offset _pointAt(double t) {
    final pts = widget.stroke;
    if (pts.isEmpty) return Offset.zero;
    if (pts.length == 1 || t <= 0) return pts.first;

    double total = 0;
    final lengths = <double>[];
    for (int i = 1; i < pts.length; i++) {
      final d = (pts[i] - pts[i - 1]).distance;
      lengths.add(d);
      total += d;
    }
    if (total == 0) return pts.first;

    double target = total * t.clamp(0.0, 1.0);
    for (int i = 0; i < lengths.length; i++) {
      if (target <= lengths[i]) {
        final f = lengths[i] == 0 ? 0.0 : target / lengths[i];
        return Offset.lerp(pts[i], pts[i + 1], f)!;
      }
      target -= lengths[i];
    }
    return pts.last;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stroke.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _progress.value;
          final pos = _pointAt(t);
          final hs = widget.handSize;

          return Stack(
            children: [
              // Cartoon pointing hand, fingertip anchored on the path.
              // (No painted trail — the white dotted guide shows the line.)
              Positioned(
                left: pos.dx - hs * 0.38,
                top: pos.dy - hs * 0.04,
                child: CustomPaint(
                  size: Size(hs, hs * 1.1),
                  painter: _PointingHandPainter(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cartoon pointing hand (yellow, black outline, index finger up) drawn in a
/// 100×110 design space and scaled to the widget size.
class _PointingHandPainter extends CustomPainter {
  static const _fill = Color(0xFFFFC61A);
  static const _shade = Color(0xFFF0B307);
  static const _outlineColor = Color(0xFF1A1A1A);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 110;
    canvas.scale(sx, sy);

    final fill = Paint()..color = _fill;
    final shade = Paint()..color = _shade;
    final outline = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Palm + wrist blob (with thumb wedge on the left).
    final palm = Path()
      ..moveTo(30, 48)
      ..lineTo(14, 60)
      ..quadraticBezierTo(8, 65, 13, 72)
      ..quadraticBezierTo(28, 92, 45, 101)
      ..quadraticBezierTo(66, 109, 80, 98)
      ..quadraticBezierTo(90, 89, 90, 72)
      ..lineTo(90, 58)
      ..quadraticBezierTo(78, 52, 66, 55)
      ..lineTo(38, 55)
      ..close();
    canvas.drawPath(palm, fill);
    // Simple shading along the lower edge of the palm.
    final shadePath = Path()
      ..moveTo(22, 78)
      ..quadraticBezierTo(38, 96, 52, 100)
      ..quadraticBezierTo(68, 104, 80, 96)
      ..quadraticBezierTo(72, 104, 58, 104)
      ..quadraticBezierTo(38, 102, 22, 78)
      ..close();
    canvas.drawPath(shadePath, shade);

    // Index finger — extended, pointing up.
    final index = RRect.fromLTRBR(
      30, 4, 46, 60, const Radius.circular(8));
    canvas.drawRRect(index, fill);

    // Folded fingers, stepping down to the right.
    final f2 = RRect.fromLTRBR(48, 28, 62, 60, const Radius.circular(7));
    final f3 = RRect.fromLTRBR(64, 34, 77, 60, const Radius.circular(6));
    final f4 = RRect.fromLTRBR(79, 40, 90, 62, const Radius.circular(5));
    canvas.drawRRect(f2, fill);
    canvas.drawRRect(f3, fill);
    canvas.drawRRect(f4, fill);

    // Outlines (drawn after fills so finger separations stay visible).
    canvas.drawPath(palm, outline);
    canvas.drawRRect(index, outline);
    canvas.drawRRect(f2, outline);
    canvas.drawRRect(f3, outline);
    canvas.drawRRect(f4, outline);
  }

  @override
  bool shouldRepaint(_PointingHandPainter old) => false;
}
