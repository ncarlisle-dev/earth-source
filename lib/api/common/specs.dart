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
class Layer
{
  /// Id of the layer.
  final String id;
  /// Given name of the layer.
  String name;
  /// Given description of the layer.
  String description;
  /// Coordinates of the four corner points of the layer image.
  List<latlong.LatLng> corners;
  /// The layer's image.
  ({ String name, int size, DateTime uploadedAt })? image;
  /// Time the layer was created.
  final DateTime createdAt;
  /// Time the layer was last updated.
  DateTime lastUpdated;

  Layer({
    required this.id,
    required this.name,
    required this.description,
    required this.corners,
    required this.image,
    required this.createdAt,
    required this.lastUpdated,
  });
}

/// A unit within an archaeological site, defined by four corners.
class Unit
{
  /// Id of the unit.
  final String id;
  /// Given name of the unit.
  String name; 
  /// Given description of the unit.
  String description;
  /// Coordinates of the corners of the unit.
  List<latlong.LatLng> corners;
  /// Interval between sampling points within the unit.
  double pointInterval;
  /// Time the unit was created.
  final DateTime createdAt;
  /// Time the unit was last updated.
  DateTime lastUpdated; 

  Unit({
    required this.id,
    required this.name,
    required this.description,
    required this.corners,
    required this.pointInterval,
    required this.createdAt, 
    required this.lastUpdated, 
  });
}

/// Data from a given file corresponding to a specific project.
abstract class DataSpec 
{
  /// Id of the data file.
  final String id;
  /// Name of the data file.
  String fileName; 
  /// Number of sampled points within the data file.
  int numPoints;
  /// Size of the file.
  int size;
  /// Time the data file was added to the project.
  final DateTime createdAt;
  /// Time the layer was last updated.
  DateTime lastUpdated;

  DataSpec({
    required this.id,
    required this.fileName, 
    required this.numPoints, 
    required this.size,
    required this.createdAt, 
    required this.lastUpdated, 
  });
}

/// pXRF data from a given file corresponding to a specific project.
class PxrfDataSpec extends DataSpec {
  PxrfDataSpec({
    required super.id,
    required super.fileName, 
    required super.numPoints, 
    required super.size,
    required super.createdAt, 
    required super.lastUpdated, 
  });
}

/// Training data from a given file corresponding to a specific project.
class TrainingDataSpec extends DataSpec {
  TrainingDataSpec({
    required super.id,
    required super.fileName, 
    required super.numPoints, 
    required super.size,
    required super.createdAt, 
    required super.lastUpdated, 
  });
}

/// A directory item in a pXRF device.
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

/// A shallow representation of a project, holding metadata about the project
/// it represents.
class ProjectSpec {
  final String                  id;
  final String                  name;
  final String                  description;
  final int                     utmZone;
  final bool                    isSouthernHemisphere;
  final List<latlong.LatLng>    corners;
  final int                     numLayers;
  final int                     numUnits;
  final int                     numPxrfData;
  final int                     numTrainingData;
  final int                     numPredictions;
  final int                     numModels;
  final DateTime                createdAt;
  final DateTime                lastUpdated;

  ProjectSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.utmZone,
    required this.isSouthernHemisphere,
    required this.corners,
    required this.numLayers,
    required this.numUnits,
    required this.numPxrfData,
    required this.numTrainingData,
    required this.numPredictions,
    required this.numModels,
    required this.createdAt,
    required this.lastUpdated,
  });
}