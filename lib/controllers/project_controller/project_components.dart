import 'package:flutter_map_math/flutter_geo_math.dart' as map_math;

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
typedef LayerSpec = ({
  String name, 
  String description, 
  DateTime lastUpdated, 
  DateTime createdAt
});

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
typedef UnitSpec = ({
  String name, 
  String description, 
  DateTime lastUpdated, 
  DateTime createdAt, 
  ({double latitude, double longitude}) topLeftCoords, 
  double width, 
  double height, 
  double pointInterval
});

/// Pxrf data from a given file corresponding to a specific project.
typedef DataSpec = ({
  String fileName, 
  String projectId, 
  DateTime createdAt, 
  int numPoints, 
  int size
});

/// Utility function - checks if two units are overlapping and returns true if
/// so, false if not.
bool isOverlapping(UnitSpec unit1, UnitSpec unit2)
{
  // Determine the top latitude, bottom latitude, left longitude, and right 
  // longitude for each unit - top and left are given, bottom and right have to
  // be calculated.
  double top1 = unit1.topLeftCoords.latitude;
  double left1 = unit1.topLeftCoords.longitude;
  double bottom1 = map_math.FlutterMapMath.destinationPoint(
    unit1.topLeftCoords.latitude, 
    unit1.topLeftCoords.longitude, 
    unit1.height, 
    180).latitude;
  double right1 = map_math.FlutterMapMath.destinationPoint(
    unit1.topLeftCoords.latitude, 
    unit1.topLeftCoords.longitude, 
    unit1.width, 
    90).longitude;

  double bottom2 = map_math.FlutterMapMath.destinationPoint(
    unit2.topLeftCoords.latitude, 
    unit2.topLeftCoords.longitude, 
    unit2.height, 
    180).latitude;
  double right2 = map_math.FlutterMapMath.destinationPoint(
    unit2.topLeftCoords.latitude, 
    unit2.topLeftCoords.longitude, 
    unit2.width, 
    90).longitude;
  double top2 = unit2.topLeftCoords.latitude;
  double left2 = unit2.topLeftCoords.longitude;
  
  // Check if one of the top corners of unit 2 is inside unit 1.
  if (top2 > bottom1 && top2 <= top1) {
    // Checking for the top left corner
    if (left2 < right1 && left2 >= left1) {
      return true;
    }
    /// Checking for the top right corner.
    else if (right2 > left1 && right2 <= right1) {
      return true;
    }
  }
  // Check if one of the bottom corners of unit 2 is inside unit 1.
  else if (top1 > bottom2 && bottom2 <= bottom1) {
    // Checking for the bottom left corner.
    if (left2 < right1 && left2 >= left1) {
      return true;
    }
    // Checking for the bottom right corner.
    else if (right2 > left1 && right2 <= right1) {
      return true;
    }
  }

  // If none of the corners of unit 2 is inside unit 1, the only other way
  // they can be overlapping is if unit 1 is entirely inside unit 2 - check
  // accordingly.
  else if (bottom2 <= top1 && top1 <= top2) {
    if (bottom2 <= bottom1 && bottom1 <= top2) {
      if (left2 <= left1 && left1 <= right2) {
        if (left2 <= right1 && right1 <= right2) {
          return true;
        }
      }
    }
  }

  // If all checks fail, they are not overlapping; return false.
  return false;
}

/// Checks if a single lat/long point falls within a given unit.
bool isWithinUnit(UnitSpec unit, double latitude, double longitude)
{
  double top = unit.topLeftCoords.latitude;
  double left = unit.topLeftCoords.longitude;
  double bottom = map_math.FlutterMapMath.destinationPoint(
    unit.topLeftCoords.latitude, 
    unit.topLeftCoords.longitude, 
    unit.height, 
    180).latitude;
  double right = map_math.FlutterMapMath.destinationPoint(
    unit.topLeftCoords.latitude, 
    unit.topLeftCoords.longitude, 
    unit.width, 
    90).longitude;

  if (top >= latitude && latitude >= bottom  
    && right >= longitude && longitude >= left) {
      return true;
  }
  return false;
}

/// Checks if all the data within a pXRF file falls within the bounds of the
/// appropriate unit (using isWithinUnit above). Unimplemented at the moment
/// as the CSV data functions have not yet been implemented.
/// 
/// Returns true if all assigned data still falls within appropriate boundaries,
/// false if not.
bool checkAssignment(String filename, UnitSpec unit) 
{
  throw UnimplementedError();
}