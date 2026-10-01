import 'package:flutter_map_math/flutter_geo_math.dart' as map_math;

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
class LayerSpec 
{
  /// User-provided name of the layer.
  String? name;
  /// User-provided description of the layer.
  String? description;
  /// Most recent time any change was made to the layer.
  DateTime? lastUpdated;
  /// Time the layer was created.
  DateTime? createdAt;
}

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
class UnitSpec 
{
  /// User-provided name of the unit.
  String? name;
  /// User-provided description of the unit.
  String? description;
  /// Most recent time any change was made to the unit.
  DateTime? lastUpdated;
  /// Time the unit was created.
  DateTime? createdAt;
  /// Decimal degrees coordinates of the top left corner of the unit.
  ({double latitude, double longitude})? topLeftCoords;
  /// Width of the unit.
  double? width;
  /// Height of the unit.
  double? height;
  /// Interval between points sampled within the unit.
  double? pointInterval;
}

/// Pxrf data from a given file corresponding to a specific project.
class DataSpec
{
  /// Name of the data file.
  String? fileName;
  /// Id of the corresponding project.
  String? projectId;
  /// Time the data file was uploaded to the project.
  DateTime? createdAt;
  /// Number of points sampled within the data file.
  int? numPoints;
  /// Size of the file.
  int? size;
}

/// Utility function - checks if two units are overlapping and returns true if
/// so, false if not.
bool isOverlapping(UnitSpec unit1, UnitSpec unit2)
{
  /// Determine the top latitude, bottom latitude, left longitude, and right 
  /// longitude for each unit - top and left are given, bottom and right have to
  /// be calculated.
  double top1 = unit1.topLeftCoords!.latitude;
  double left1 = unit1.topLeftCoords!.longitude;
  double bottom1 = map_math.FlutterMapMath.destinationPoint(
    unit1.topLeftCoords!.latitude, 
    unit1.topLeftCoords!.longitude, 
    unit1.height!, 
    180).latitude;
  double right1 = map_math.FlutterMapMath.destinationPoint(
    unit1.topLeftCoords!.latitude, 
    unit1.topLeftCoords!.longitude, 
    unit1.width!, 
    90).longitude;

  double bottom2 = map_math.FlutterMapMath.destinationPoint(
    unit2.topLeftCoords!.latitude, 
    unit2.topLeftCoords!.longitude, 
    unit2.height!, 
    180).latitude;
  double right2 = map_math.FlutterMapMath.destinationPoint(
    unit2.topLeftCoords!.latitude, 
    unit2.topLeftCoords!.longitude, 
    unit2.width!, 
    90).longitude;
  double top2 = unit2.topLeftCoords!.latitude;
  double left2 = unit2.topLeftCoords!.longitude;
  
  /// Check if one of the top corners of unit 2 is inside unit 1.
  if (top2 > bottom1 && top2 <= top1) {
    /// Checking for the top left corner
    if (left2 < right1 && left2 >= left1) {
      return true;
    }
    /// Checking for the top right corner.
    else if (right2 > left1 && right2 <= right1) {
      return true;
    }
  }
  /// Check if one of the bottom corners of unit 2 is inside unit 1.
  else if (top1 > bottom2 && bottom2 <= bottom1) {
    /// Checking for the bottom left corner.
    if (left2 < right1 && left2 >= left1) {
      return true;
    }
    /// Checking for the bottom right corner.
    else if (right2 > left1 && right2 <= right1) {
      return true;
    }
  }

  /// If none of the corners of unit 2 is inside unit 1, the only other way
  /// they can be overlapping is if unit 1 is entirely inside unit 2 - check
  /// accordingly.
  else if (bottom2 <= top1 && top1 <= top2) {
    if (bottom2 <= bottom1 && bottom1 <= top2) {
      if (left2 <= left1 && left1 <= right2) {
        if (left2 <= right1 && right1 <= right2) {
          return true;
        }
      }
    }
  }

  /// If all checks fail, they are not overlapping; return false.
  return false;
}