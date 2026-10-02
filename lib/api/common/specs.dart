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

class LayerSpec {
  String name;
  String description;
  DateTime createdAt;
  DateTime lastUpdated;

  LayerSpec(this.name, this.description, this.createdAt, this.lastUpdated);
}

class UnitSpec {
  String name;
  String description;
  DateTime createdAt;
  DateTime lastUpdated;
  ({ double latitude, double longitude }) topLeftCoords;
  double width;
  double height;
  double pointInterval;

  UnitSpec(
    this.name,
    this.description,
    this.createdAt,
    this.lastUpdated,
    this.topLeftCoords,
    this.width,
    this.height,
    this.pointInterval,
  );
}

class DataSpec {
  String fileName;
  String projectId;
  DateTime createdAt;
  int numPoints;
  int size;

  DataSpec(
    this.fileName,
    this.projectId,
    this.createdAt,
    this.numPoints,
    this.size,
  );
}