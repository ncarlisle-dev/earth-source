import 'package:flutter/material.dart';

class HeatPalette {
  // Bin 1..5 (1 = low/green, 5 = high/red)
  static const Map<int, Color> binColor = {
    0: Colors.transparent,
    1: Color(0xFF56A64B), // green
    2: Color(0xFF8BC34A), // light green
    3: Color(0xFFFFEB3B), // yellow
    4: Color(0xFFFF9800), // orange
    5: Color(0xFFF44336), // red
  };

  /// Quantize probability [0..1] into 5 bins
  static int binFor(double p) {
    if (p < 0.50) return 0;
    if (p < 0.60) return 1;
    if (p < 0.75) return 2;
    if (p < 0.80) return 3;
    if (p < 0.90) return 4;
    return 5;
  }

  /// Center color for probability
  static Color colorFor(double p) => binColor[binFor(p)]!;
}
/// Utility: map a value in [0,maxVal] to a Color.
/// Right now: 0 = transparent, mid = yellow-ish, high = red.
/// You can swap this with whatever ramp you had in HeatmapFieldColorRamp.
Color heatValueToColor(double v, double maxVal) {
  if (v <= 0) {
    return Colors.transparent;
  }

  // Normalize intensity to 0..1
  double p = v / maxVal;
  if (p.isNaN || p.isInfinite) p = 0.0;
  if (p < 0.0) p = 0.0;
  if (p > 1.0) p = 1.0;

  final baseColor = HeatPalette.colorFor(p);

  // We'll scale alpha from ~0.15 at low signal to ~0.8 at high signal,
  // so even weak cells are faintly visible, but strong cells really pop.
  final double minAlpha = 0.15;
  final double maxAlpha = 0.80;
  final double a = minAlpha + (maxAlpha - minAlpha) * p;

  return baseColor.withValues(alpha: a);
}



class HeatmapPainter extends CustomPainter {
  final List<List<double>> heat;
  final double maxVal;

  /// If true, draw grid cell edges for debugging.
  final bool debugGridLines;

  const HeatmapPainter({
    required this.heat,
    required this.maxVal,
    this.debugGridLines = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int rows = heat.length;
    if (rows == 0) return;
    final int cols = heat[0].length;
    if (cols == 0) return;

    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    final rectPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final double v = heat[y][x];
        if (v <= 0.0) continue; // skip pure zero for perf/clarity

        rectPaint.color = heatValueToColor(v, maxVal);

        final double left = x * cellW;
        final double top = y * cellH;
        final rect = Rect.fromLTWH(left, top, cellW, cellH);

        canvas.drawRect(rect, rectPaint);
      }
    }

    if (debugGridLines) {
      final gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black.withOpacity(0.1);

      // vertical lines
      for (int x = 0; x <= cols; x++) {
        final dx = x * cellW;
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      }
      // horizontal lines
      for (int y = 0; y <= rows; y++) {
        final dy = y * cellH;
        canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    // Repaint if the actual numeric grid or range changes.
    // If you make this more clever later, that's fine.
    return !identical(oldDelegate.heat, heat) ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.debugGridLines != debugGridLines;
  }
}