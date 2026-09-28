///import '../services/network_service.dart' as network_service;

class ProjectController {
  static ProjectController? instance;
  final List<Project> userProjects;

  ProjectController(this.userProjects);

  static ProjectController getInstance() {
    if (instance != null) return instance!;

    instance = ProjectController();
    return instance!;
  }

  Future<Project> createProject(String name, String description)
  {
    throw UnimplementedError();
  }

  Future<void> deleteProject(String id)
  {
    throw UnimplementedError();
  }
}

class Project {
  String? id;
  final String name;
  final String description;
  final DateTime createdAt;
  DateTime? lastUpdated;
  List<LayerSpec>? layers;
  List<UnitSpec>? units;

  Project(this.name, this.description, this.createdAt);

  Future<LayerSpec> createLayer(String name, String description)
  {
    throw UnimplementedError();
  }

  Future<void> setLayerName(String srcName, String newName)
  {
    throw UnimplementedError();
  }

  Future<void> setLayerDescription(String name, String description)
  {
    throw UnimplementedError();
  }

  Future<void> deleteLayer(String name)
  {
    throw UnimplementedError();
  }

  Future<UnitSpec> createUnit(String name, String description, 
  ({double latitude, double longitude}) topLeft, double width, double height, 
  double pointInterval)
  {
    throw UnimplementedError();
  }

  Future<void> setUnitName(String srcName, String newName)
  {
    throw UnimplementedError();
  }

  Future<void> setUnitDescription(String name, String description)
  {
    throw UnimplementedError();
  }

  Future<void> repositionUnit(String name, ({double latitude, double longitude})
   topLeft, double width, double height, double pointInterval)
  {
    throw UnimplementedError();
  }

  Future<void> deleteUnit(String name)
  {
    throw UnimplementedError();
  }

  Future<void> uploadLayerImage(String layerName, String imageContents)
  {
    throw UnimplementedError();
  }

  Future<String?> getLayerImage(String layerName)
  {
    throw UnimplementedError();
  }

  Future<void> removeLayerImage(String layerName)
  {
    throw UnimplementedError();
  }
}

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
class LayerSpec {
  final String name;
  final String description;
  final DateTime lastUpdated;
  final DateTime createdAt;

  LayerSpec(this.name, this.description, this.lastUpdated, this.createdAt);
}

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
class UnitSpec {
  final String name;
  final String description;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final ({double latitude, double longitude}) topLeftCoords;
  final double width;
  final double height;
  final double pointInterval;

  UnitSpec(this.name, this.description, this.lastUpdated, this.createdAt, 
  this.topLeftCoords, this.width, this.height, this.pointInterval);
}