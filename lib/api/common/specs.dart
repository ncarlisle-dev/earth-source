import 'network.dart' as network;
import 'package:latlong2/latlong.dart' as latlong;

class ConnectionSpec
{
  String id;
  String ipAddress;
  int port;
  DateTime createdAt;
  network.ConnectionStatus status;

  ConnectionSpec({
    required this.id,
    required this.ipAddress,
    required this.port,
    required this.createdAt,
    required this.status
  });
}

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
class LayerSpec
{
  /// Id of the layer.
  String id;
  /// Given name of the layer.
  String name;
  /// Given description of the layer.
  String description;
  /// Time the layer was last updated.
  DateTime lastUpdated;
  /// Coordinates of the four corner points of the layer image.
  List<latlong.LatLng> cornerCoordinates;
  /// Time the layer was created.
  final DateTime createdAt;

  LayerSpec(
    this.id,
    this.name, 
    this.description, 
    this.lastUpdated, 
    this.createdAt, 
    this.cornerCoordinates
  );
}

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
class UnitSpec
{
  /// Id of the unit.
  String id;
  /// Given name of the unit.
  String name; 
  /// Given description of the unit.
  String description;
  /// Time the unit was last updated.
  DateTime lastUpdated; 
  /// Time the unit was created.
  DateTime createdAt;
  /// Coordinates of the top left corner of the unit.
  latlong.LatLng topLeftCoords;
  /// Width of the unit.
  double width;
  /// Height of the unit.
  double height;
  /// Interval between sampling points within the unit.
  double pointInterval;

  UnitSpec(
    this.id,
    this.name, 
    this.description, 
    this.lastUpdated, 
    this.createdAt, 
    this.topLeftCoords, 
    this.width, 
    this.height, 
    this.pointInterval
  );
}

/// Pxrf data from a given file corresponding to a specific project.
class DataSpec 
{
  /// Id of the data file.
  String id;
  /// Name of the data file.
  String fileName; 
  /// Id of the corresponding project.
  String projectId;
  /// Time the data file was added to the project.
  DateTime createdAt;
  /// Number of sampled points within the data file.
  int numPoints;
  /// Size of the file.
  int size;

  DataSpec(
    this.id,
    this.fileName, 
    this.projectId, 
    this.createdAt, 
    this.numPoints, 
    this.size
  );
}

class DirectoryItemSpec {
  String name;
  bool isFile;
  int size;
  DateTime lastModified;

  DirectoryItemSpec(
    this.name,
    this.isFile,
    this.size,
    this.lastModified,
  );
}