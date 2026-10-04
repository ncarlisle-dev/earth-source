import 'package:flutter/material.dart';

/// Utility function - modifies the alpha channel of a color value depending
/// on the value of the prediction at that point.
Color heatValueToColor(double value) 
{
  final baseColor = HeatPalette.colorFor(value, "soil");

  final double minAlpha = 0.05;
  final double maxAlpha = 0.80;
  final double alpha = minAlpha + (maxAlpha - minAlpha) * value;

  return baseColor.withValues(alpha: alpha);
}

/// A palette containing colors that signify each different kind of material.
class HeatPalette 
{
  /// Map of colors to represent soil.
  static const Map<int, Color> soilColors = {
    0: Colors.transparent,
    1: Color.fromARGB(255, 206, 253, 200), 
    2: Color.fromARGB(255, 185, 247, 114), 
    3: Color.fromARGB(255, 117, 200, 54), 
    4: Color.fromARGB(255, 69, 153, 32), 
    5: Color.fromARGB(255, 8, 61, 1), 
  };

  /// Map of colors to represent pottery.
  static const Map<int, Color> potteryColors = {
    0: Colors.transparent,
    1: Color.fromARGB(255, 148, 178, 244), 
    2: Color.fromARGB(255, 116, 160, 241), 
    3: Color.fromARGB(255, 80, 128, 252), 
    4: Color.fromARGB(255, 50, 108, 255), 
    5: Color.fromARGB(255, 1, 69, 241), 
  };

  /// Map of colors to represent metal.
  static const Map<int, Color> metalColors = {
    0: Colors.transparent,
    1: Color.fromARGB(255, 229, 199, 247), 
    2: Color.fromARGB(255, 225, 149, 242), 
    3: Color.fromARGB(255, 173, 91, 196), 
    4: Color.fromARGB(255, 110, 55, 125), 
    5: Color.fromARGB(255, 50, 0, 53), 
  };

  /// Map of colors to represent slag.
  static const Map<int, Color> slagColors = {
    0: Colors.transparent,
    1: Color.fromARGB(255, 241, 237, 154), 
    2: Color.fromARGB(255, 241, 213, 111), 
    3: Color.fromARGB(255, 211, 160, 66), 
    4: Color.fromARGB(255, 207, 121, 40), 
    5: Color.fromARGB(255, 99, 45, 0), 
  };

  /// Determines into which bin a data point falls depending on how high the 
  /// prediction is at that point.
  static int determineBin(double point) 
  {
    if (point < 0.50) return 0;
    if (point < 0.60) return 1;
    if (point < 0.75) return 2;
    if (point < 0.80) return 3;
    if (point < 0.90) return 4;
    return 5;
  }

  /// Uses appropriate color palette for each material to select a color.
  static Color colorFor(double point, String material) 
  {
    switch (material) {
      case "soil":
        return soilColors[determineBin(point)]!;
      case "pottery":
        return potteryColors[determineBin(point)]!;
      case "metal":
        return metalColors[determineBin(point)]!;
      case "slag":
        return slagColors[determineBin(point)]!;
      default:
        return soilColors[determineBin(point)]!;
    }
  }
}

/// An extension of the CustomPainter class that paints a gridded heatmap onto
/// an image.
class HeatmapPainter extends CustomPainter 
{
  /// 2D list of predicted values, with rows and columns in the list 
  /// corresponding to rows and columns on the map.
  final List<List<double>> heat;
  /// Boolean that determines whether grid lines should be painted on the map
  /// for debugging purposes.
  final bool debugGridLines;

  const HeatmapPainter({
    required this.heat,
    this.debugGridLines = false,
  });

  @override
  void paint(Canvas canvas, Size size) 
  {
    /// Divide the canvas into rows and columns based on dimensions of the 
    /// data list and paint each cell accordingly.
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
        if (v == 0.0) continue; 

        rectPaint.color = heatValueToColor(v);

        final double left = x * cellW;
        final double top = y * cellH;
        final rect = Rect.fromLTWH(left, top, cellW, cellH);

        canvas.drawRect(rect, rectPaint);
      }
    }

    /// If applicable, draw grid lines demarcating each individual cell on the
    /// canvas.
    if (debugGridLines) {
      final gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black.withValues();

      for (int x = 0; x <= cols; x++) {
        final dx = x * cellW;
        canvas.drawLine(Offset(dx, 0), 
          Offset(dx, size.height), gridPaint);
      }
      for (int y = 0; y <= rows; y++) {
        final dy = y * cellH;
        canvas.drawLine(Offset(0, dy), 
          Offset(size.width, dy), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) 
  {
    return !identical(oldDelegate.heat, heat) ||
        oldDelegate.debugGridLines != debugGridLines;
  }
}
