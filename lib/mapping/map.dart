import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;

import 'dart:io' as io;

// TODO: expand file documentation

/// Class for a single site unit.
class Unit
{
  coord_converter.DDCoordinates? cornerPoint;
  double? length;
  double? width;
}

/// Class for an entire site map.
class SiteMap
{
  /// Coordinates for the corner points are stored in UTM and DD (since the 
  /// latter is needed to plot latitude and longitude)
  final List<coord_converter.UTMCoordinates> _cornerCoordinatesUTM = [];
  final List<coord_converter.DDCoordinates> _cornerCoordinatesDD = [];
  final List<Unit> _units = [];

  double? sampleInterval;
  io.File? imageFile;

  /// Initializes map data and converts UTM coordinates to DD.
  void initializeMap(
    int utmZone,
    bool utmHemisphere, 
    List<List> coordinates,
    double interval,
    String filePath
  )
  {
    for (var i = 0; i < 4; i++) {
      coord_converter.UTMCoordinates utmCoords = coord_converter.UTMCoordinates(
        x: coordinates[i][0],
        y: coordinates[i][1],
        zoneNumber: utmZone,
        isSouthernHemisphere: utmHemisphere
      );
      _cornerCoordinatesUTM.add(utmCoords);
      _cornerCoordinatesDD.add(coord_converter.DDCoordinates.fromUTM(utmCoords));
    }

    imageFile = io.File(filePath);
    sampleInterval = interval;
  }

  /// Adds a unit to the map.
  void addUnit(List cornerPoint, double length, double width) 
  {
    Unit newUnit = Unit();
    coord_converter.UTMCoordinates utmCoords = coord_converter.UTMCoordinates(
      x: cornerPoint[0],
      y: cornerPoint[1],
      zoneNumber: _cornerCoordinatesUTM[0].zoneNumber,
      isSouthernHemisphere: _cornerCoordinatesUTM[0].isSouthernHemisphere
    );

    newUnit.cornerPoint = coord_converter.DDCoordinates.fromUTM(utmCoords);
    newUnit.length = length;
    newUnit.width = width;
    _units.add(newUnit);
  }

  /// Expands a unit.
  void expandUnit(int unitNumber, double newLength, double newWidth)
  {
    _units[unitNumber - 1].length = newLength;
    _units[unitNumber - 1].length = newWidth;
  }
}