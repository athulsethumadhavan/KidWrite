import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color? primaryColor;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.primaryColor,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  final List<_Bubble> _bubbles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    for (int i = 0; i < 12; i++) {
      _bubbles.add(_Bubble.random(_rng));
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? AppColors.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.10),
                AppColors.accent.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
        // Floating bubbles
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            return CustomPaint(
              painter: _BubblePainter(
                bubbles: _bubbles,
                progress: _floatController.value,
                pulseProgress: _pulseController.value,
                baseColor: primary,
              ),
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _Bubble {
  final double x;      // 0..1 fractional
  final double startY; // 0..1 fractional
  final double radius;
  final double speed;
  final double opacity;
  final int colorIndex;

  _Bubble({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.colorIndex,
  });

  factory _Bubble.random(Random rng) => _Bubble(
    x: rng.nextDouble(),
    startY: rng.nextDouble(),
    radius: 10 + rng.nextDouble() * 30,
    speed: 0.3 + rng.nextDouble() * 0.7,
    opacity: 0.08 + rng.nextDouble() * 0.15,
    colorIndex: rng.nextInt(5),
  );
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  final double pulseProgress;
  final Color baseColor;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.purple,
    AppColors.green,
  ];

  _BubblePainter({
    required this.bubbles,
    required this.progress,
    required this.pulseProgress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final color = _colors[bubble.colorIndex];
      final paint = Paint()
        ..color = color.withValues(alpha: bubble.opacity)
        ..style = PaintingStyle.fill;

      final t = (progress * bubble.speed + bubble.startY) % 1.0;
      final y = size.height * (1.0 - t);
      final x = size.width * bubble.x +
          sin(progress * 2 * pi + bubble.startY * 10) * 20;
      final r = bubble.radius * (1 + pulseProgress * 0.1);

      canvas.drawCircle(Offset(x, y), r, paint);

      // Border
      final borderPaint = Paint()
        ..color = color.withValues(alpha: bubble.opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), r, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.progress != progress || old.pulseProgress != pulseProgress;
}
