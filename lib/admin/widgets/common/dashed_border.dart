import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a dashed rounded rectangle around [child].
///
/// Flutter has no dashed [Border], so the outline is stroked by hand from the
/// rounded-rect path.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke so the dashes sit inside the bounds.
    final bounds = Offset.zero & size;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          bounds.deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    final brush = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final step = dashLength + gapLength;

    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += step) {
        final end = math.min(start + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(start, end), brush);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
