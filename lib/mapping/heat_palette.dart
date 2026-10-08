import 'package:flutter/material.dart';

/// A palette containing colors that signify each different kind of material.
class HeatPalette 
{
  /// Map of colors to represent soil.
  static const Map<int, Color> soilColors = {
    1: Color.fromARGB(255, 206, 253, 200), 
    2: Color.fromARGB(255, 185, 247, 114), 
    3: Color.fromARGB(255, 117, 200, 54), 
    4: Color.fromARGB(255, 69, 153, 32), 
    5: Color.fromARGB(255, 8, 61, 1), 
  };

  /// Map of colors to represent pottery.
  static const Map<int, Color> potteryColors = {
    1: Color.fromARGB(255, 148, 178, 244), 
    2: Color.fromARGB(255, 116, 160, 241), 
    3: Color.fromARGB(255, 80, 128, 252), 
    4: Color.fromARGB(255, 50, 108, 255), 
    5: Color.fromARGB(255, 1, 69, 241), 
  };

  /// Map of colors to represent metal.
  static const Map<int, Color> metalColors = {
    1: Color.fromARGB(255, 229, 199, 247), 
    2: Color.fromARGB(255, 225, 149, 242), 
    3: Color.fromARGB(255, 173, 91, 196), 
    4: Color.fromARGB(255, 110, 55, 125), 
    5: Color.fromARGB(255, 50, 0, 53), 
  };

  /// Map of colors to represent slag.
  static const Map<int, Color> slagColors = {
    1: Color.fromARGB(255, 241, 237, 154), 
    2: Color.fromARGB(255, 241, 213, 111), 
    3: Color.fromARGB(255, 211, 160, 66), 
    4: Color.fromARGB(255, 207, 121, 40), 
    5: Color.fromARGB(255, 99, 45, 0), 
  };

  /// Determines into which bin a data point falls depending on how high the 
  /// prediction is at that point.
  static int determineBin(double point, double threshold) 
  {
    double valueInterval = (1 - threshold) / 5;
    for (var i = 0; i < 5; i++) {
      if (point <= threshold + (i + 1) * valueInterval) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Uses appropriate color palette for each material to select a color.
  static Color colorFor(double point, double threshold, String material) 
  {
    switch (material) {
      case "soil":
        return soilColors[determineBin(point, threshold)]!;
      case "pottery":
        return potteryColors[determineBin(point, threshold)]!;
      case "metal":
        return metalColors[determineBin(point, threshold)]!;
      case "slag":
        return slagColors[determineBin(point, threshold)]!;
      default:
        return soilColors[determineBin(point, threshold)]!;
    }
  }
}