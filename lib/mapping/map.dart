import 'package:coordinate_converter/coordinate_converter.dart';
import 'dart:io';

class Unit {
  UTMCoordinates? _cornerPoint;
  double? _length;
  double? _width;
}

class SiteMap {
  final List<UTMCoordinates> _cornerCoordinates = [];
  final List<Unit> _units = [];

  File? _imageFile;

  void initializeMap(int utmZone, bool utmHemisphere, List<List> coordinates, String filePath) {
    for (var i = 0; i < 4; i++)
    {
      _cornerCoordinates.add(UTMCoordinates(x: coordinates[i][0], y: coordinates[i][1], zoneNumber: utmZone, isSouthernHemisphere: utmHemisphere));
    }
    _imageFile = File(filePath);
  }
}

