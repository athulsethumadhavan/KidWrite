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

  /// Cumulative, curvature-weighted position of each point along the stroke,
  /// normalized 0..1. Sharp turns are given extra weight so the hand eases
  /// into them and out again instead of whipping round — a direction change
  /// then reads as deliberate rather than as a glitch.
  late List<double> _cum;

  /// The stroke resampled into short, evenly spaced steps along a smooth
  /// curve. Interpolating on this is what makes the hand glide: the raw path
  /// is simplified, so lerping between its points shows visible corners, and
  /// sampling a spline by its parameter moves at an uneven rate.
  late List<Offset> _dense;

  /// True where the path doubles back over ink it has already laid down — the
  /// return up the stem of അ, for example. The letter really is written that
  /// way, but showing it looks like the hand is drawing backwards, so the demo
  /// crosses those stretches in almost no time: the hand jumps to where new
  /// ink resumes.
  late List<bool> _retrace;

  void _markRetrace() {
    final pts = _dense;
    _retrace = List<bool>.filled(pts.length, false);
    final near = widget.handSize * 0.16;
    final nearSq = near * near;
    // Skip enough neighbours that the samples just behind on the same run are
    // never mistaken for a retrace of themselves.
    final skip = (near / 2.0).ceil() + 2;

    Offset dir(int k) {
      final a = pts[k - 1 < 0 ? 0 : k - 1];
      final b = pts[k + 1 >= pts.length ? pts.length - 1 : k + 1];
      final d = b - a;
      final n = d.distance;
      return n < 0.001 ? Offset.zero : d / n;
    }

    for (int i = 1; i < pts.length; i++) {
      for (int j = 0; j < i - skip; j++) {
        if ((pts[i] - pts[j]).distanceSquared < nearSq) {
          // Proximity alone is not enough: the closing arc of a loop (the
          // circle of അ) and arcs that merely run close beside earlier ink
          // would be flagged too, making the hand dart around inside small
          // features. A genuine retrace travels back ALONG the earlier pass,
          // so require the directions to be roughly opposite.
          final di = dir(i);
          final dj = dir(j);
          final dot = di.dx * dj.dx + di.dy * dj.dy;
          if (dot < -0.4) {
            _retrace[i] = true;
          }
          break;
        }
      }
    }
  }

  void _densify() {
    final raw = widget.stroke;
    if (raw.length < 3) {
      _dense = List<Offset>.of(raw);
      return;
    }
    const step = 2.0; // logical pixels between samples
    final out = <Offset>[raw.first];
    for (int i = 1; i < raw.length; i++) {
      final p0 = raw[i - 2 < 0 ? 0 : i - 2];
      final p1 = raw[i - 1];
      final p2 = raw[i];
      final p3 = raw[i + 1 >= raw.length ? raw.length - 1 : i + 1];
      final n = ((p2 - p1).distance / step).ceil().clamp(1, 60);
      for (int k = 1; k <= n; k++) {
        out.add(_spline(p0, p1, p2, p3, k / n));
      }
    }
    _dense = out;
  }

  void _buildProfile() {
    _densify();
    _markRetrace();
    final pts = _dense;
    _cum = List<double>.filled(pts.length, 0);
    if (pts.length < 2) return;

    // Per-segment time weight.
    final weights = List<double>.filled(pts.length, 1);
    for (int i = 1; i < pts.length; i++) {
      // How sharply does the path turn here? 0 = straight on, 1 = doubles back.
      double sharpness = 0;
      if (i > 1) {
        final a = pts[i - 1] - pts[i - 2];
        final b = pts[i] - pts[i - 1];
        final na = a.distance, nb = b.distance;
        if (na > 0.01 && nb > 0.01) {
          final cos = ((a.dx * b.dx + a.dy * b.dy) / (na * nb)).clamp(
            -1.0,
            1.0,
          );
          sharpness = (1 - cos) / 2;
        }
      }
      // A hairpin costs ~4x the time of a straight run of the same length.
      weights[i] = 1 + 3.0 * sharpness * sharpness;
    }

    // Blur the weights so speed ramps up and down instead of stepping between
    // neighbouring segments — a sudden change of pace reads as a stutter.
    // Samples are ~2px apart, so this ramps over roughly 40px of travel.
    final smoothed = List<double>.filled(pts.length, 1);
    const span = 20;
    for (int i = 1; i < pts.length; i++) {
      double sum = 0;
      int n = 0;
      for (int k = i - span; k <= i + span; k++) {
        if (k < 1 || k >= pts.length) continue;
        sum += weights[k];
        n++;
      }
      smoothed[i] = n == 0 ? weights[i] : sum / n;
    }

    // Applied AFTER the blur so the crossing stays quick instead of being
    // smeared out across it. Each retraced run is given a short, fixed budget
    // rather than a flat weight, so a long retrace and a short one take about
    // the same time; and the pace ramps in and out over a few samples, so the
    // hand accelerates away and settles back rather than teleporting.
    int i = 1;
    while (i < pts.length) {
      if (!_retrace[i]) {
        i++;
        continue;
      }
      int end = i;
      double runLength = 0;
      while (end < pts.length && _retrace[end]) {
        runLength += (pts[end] - pts[end - 1]).distance;
        end++;
      }
      // Tiny retraced snippets (a few px at a loop seam) are crossed at
      // normal pace — speeding through them is itself a visible dart.
      if (runLength > 18.0) {
        // Cross the whole run in the time a short forward hop would take.
        const budget = 120.0;
        // The floor matters: below about 0.08 the middle of the run is so fast
        // that the ramp can't hide the change of pace, and the sweep snaps.
        final fast = (budget / runLength).clamp(0.08, 0.6);
        final count = end - i;
        // Half the run spent easing in, half easing out — the longest ramp the
        // run can afford, so the speed never steps.
        final ramp = (count / 2).clamp(1, 8).toInt();
        for (int k = i; k < end; k++) {
          final into = (k - i + 1) / ramp;
          final outOf = (end - k) / ramp;
          // Smoothstep at both ends of the run.
          final edge = into.clamp(0.0, 1.0) * outOf.clamp(0.0, 1.0);
          final blend = edge * edge * (3 - 2 * edge);
          smoothed[k] = smoothed[k] * (1 - blend) + fast * blend;
        }
      }
      i = end;
    }

    double running = 0;
    for (int i = 1; i < pts.length; i++) {
      running += (pts[i] - pts[i - 1]).distance * smoothed[i];
      _cum[i] = running;
    }
    if (running <= 0) return;
    for (int i = 0; i < _cum.length; i++) {
      _cum[i] /= running;
    }
  }

  /// Catmull-Rom point, so the hand follows a curve through the path points
  /// rather than cutting the corners of a polyline.
  Offset _spline(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    double axis(double a, double b, double c, double d) =>
        0.5 *
        ((2 * b) +
            (-a + c) * t +
            (2 * a - 5 * b + 4 * c - d) * t2 +
            (-a + 3 * b - 3 * c + d) * t3);
    return Offset(
      axis(p0.dx, p1.dx, p2.dx, p3.dx),
      axis(p0.dy, p1.dy, p2.dy, p3.dy),
    );
  }

  @override
  void initState() {
    super.initState();
    _buildProfile();
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
      _buildProfile();
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

  /// Point at fraction [t] (0..1) along the curvature-weighted profile, so the
  /// hand slows through turns instead of moving at a constant speed.
  Offset _sampleAt(double t) {
    final pts = _dense;
    if (pts.isEmpty) return Offset.zero;
    if (pts.length == 1 || t <= 0) return pts.first;
    if (_cum.length != pts.length) return pts.last;

    final target = t.clamp(0.0, 1.0);
    for (int i = 1; i < pts.length; i++) {
      if (target <= _cum[i]) {
        final span = _cum[i] - _cum[i - 1];
        final f = span <= 0 ? 0.0 : (target - _cum[i - 1]) / span;
        return Offset.lerp(pts[i - 1], pts[i], f)!;
      }
    }
    return pts.last;
  }

  /// The demo loops, so without this the hand teleported from the end of the
  /// letter straight back to the start — which reads as the hand jumping to
  /// somewhere else instead of finishing. Fade out on arrival, stay hidden
  /// through the pause, fade back in at the start of the next pass.
  double _opacityFor(double c) {
    const traceEnd = 0.75; // matches the Interval below
    const gone = 0.86;
    const back = 0.97;
    if (c < 0.05) return c / 0.05; // fading in
    if (c <= traceEnd) return 1.0; // drawing
    if (c < gone) return 1.0 - (c - traceEnd) / (gone - traceEnd);
    if (c < back) return 0.0; // resting, hidden
    return (c - back) / (1 - back);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stroke.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _progress.value;
          final pos = _sampleAt(t);
          final hs = widget.handSize;
          final opacity = _opacityFor(_controller.value);

          if (opacity <= 0.01) return const SizedBox.shrink();

          return Stack(
            children: [
              // Cartoon pointing hand, fingertip anchored on the path.
              // (No painted trail — the white dotted guide shows the line.)
              Positioned(
                left: pos.dx - hs * 0.38,
                top: pos.dy - hs * 0.04,
                child: Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    size: Size(hs, hs * 1.1),
                    painter: _PointingHandPainter(),
                  ),
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
    final index = RRect.fromLTRBR(30, 4, 46, 60, const Radius.circular(8));
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
