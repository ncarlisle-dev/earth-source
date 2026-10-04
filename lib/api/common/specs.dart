import 'network.dart' as network;

class AirdroidConnectionSpec {
  String ipAddress;
  int port;
  DateTime createdAt;
  DateTime? lastUsed;
  network.ConnectionStatus status;

  AirdroidConnectionSpec(
    this.ipAddress,
    this.port,
    this.createdAt,
    this.lastUsed,
    this.status
  );
}

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
class LayerSpec
{
  /// Given name of the layer.
  String name;
  /// Given description of the layer.
  String description;
  /// Time the layer was last updated.
  DateTime lastUpdated;
  /// Time the layer was created.
  final DateTime createdAt;

  LayerSpec(this.name, this.description, this.lastUpdated, this.createdAt);
}

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
class UnitSpec
{
  /// Given name of the unit.
  String name; 
  /// Given description of the unit.
  String description;
  /// Time the unit was last updated.
  DateTime lastUpdated; 
  /// Time the unit was created.
  DateTime createdAt;
  /// Coordinates of the top left corner of the unit.
  ({double latitude, double longitude}) topLeftCoords;
  /// Width of the unit.
  double width;
  /// Height of the unit.
  double height;
  /// Interval between sampling points within the unit.
  double pointInterval;

  UnitSpec(
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
    this.fileName, 
    this.projectId, 
    this.createdAt, 
    this.numPoints, 
    this.size
  );
}