import 'dart:ui';

import 'package:flutter/material.dart';

/// Lays a scrollable out *behind* a floating header, iOS navigation-bar style.
///
/// The list starts below the header, then slides up under it as you scroll:
/// the top of the content dissolves into the bar rather than being clipped at
/// a hard edge, and the bar itself blurs whatever passes beneath it.
///
/// The header's height is measured on the first frame, so the content's top
/// inset always matches it — no magic numbers to keep in sync with the header
/// layout.
class ScrollUnderHeader extends StatefulWidget {
  /// The bar that stays put at the top.
  final Widget header;

  /// Builds the scrollable. [topInset] is the header's measured height and
  /// must be applied as the scroll view's top padding, otherwise the first
  /// item starts life hidden underneath the bar.
  final Widget Function(BuildContext context, double topInset) builder;

  /// How far below the bar the content is fully opaque. The dissolve runs
  /// from the top of the screen to this point.
  final double fadeHeight;

  const ScrollUnderHeader({
    super.key,
    required this.header,
    required this.builder,
    this.fadeHeight = 28,
  });

  @override
  State<ScrollUnderHeader> createState() => _ScrollUnderHeaderState();
}

class _ScrollUnderHeaderState extends State<ScrollUnderHeader> {
  final GlobalKey _headerKey = GlobalKey();

  /// Best guess until the first frame has been laid out. Replaced with the
  /// real height immediately after, so nothing jumps visibly.
  double _headerHeight = 96;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant ScrollUnderHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The header can change height (a filter row appearing, text reflowing),
    // so re-measure whenever it rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _headerHeight).abs() > 0.5 && mounted) {
      setState(() => _headerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ShaderMask(
            // dstIn keeps the content only where the gradient is opaque, so
            // the alpha ramp becomes a fade rather than a colour wash.
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              // Stops are measured against the rect actually being painted,
              // not the screen, so the dissolve lines up with the bar even
              // when the body doesn't fill the window.
              final h = rect.height <= 0 ? 1.0 : rect.height;
              final end =
                  ((_headerHeight + widget.fadeHeight) / h).clamp(0.0, 1.0);
              final start = (end * 0.55).clamp(0.0, 1.0);
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0, start, end, 1],
              ).createShader(rect);
            },
            child: widget.builder(context, _headerHeight),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                key: _headerKey,
                color: Colors.transparent,
                child: widget.header,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
