import '../../services/network_service.dart' as network_service;
import '../../airdroid/connection.dart' as connection;

network_service.NetworkService networkService = 
  network_service.NetworkService.getInstance();

/// A controller that bridges the frontend and backend, allowing user projects 
/// to be accessed and manipulated by means of the network service
class ProjectController 
{
  /// Static instance of the project controller
  static ProjectController? instance;

  /// List of user projects stored in the project controller
  List<Project> userProjects = [];

  /// Retrieves the ProjectController instance if already initialized; if not, 
  /// creates an instance and fetches the user's projects from the database
  /// 
  /// Throws a [Network Exception] if the request to upload user projects fails.
  static Future<ProjectController> getInstance() async
  {
    if (instance != null) return instance!;

    instance = ProjectController();
    try {
      instance!.userProjects = await networkService.getProjects();
    }
    catch (error) {
      throw connection.NetworkException(
        "Failed to upload user projects due to the following error:\n$error", 
        null);
    }
    return instance!;
  }

  /// Creates a project using a given name and description, uploads it to the 
  /// server, and returns it.
  /// 
  /// Throws a [Network Exception] if the server request to upload a new 
  /// project fails.
  Future<Project> createProject(String name, String description) async
  {
    Project createdProject = Project(name, description, DateTime.now(), 
      DateTime.now());
    userProjects.add(createdProject);
    try {
      await networkService.uploadProject(createdProject);
    }
    catch (error) {
      throw connection.NetworkException(
        "Project creation failed with the following error:\n$error", null);
    }
    return createdProject;
  }

  /// Finds and deletes a project with the given id.
  /// 
  /// Throws a [NetworkException] if the server request to delete the project
  /// fails.
  Future<void> deleteProject(String id) async
  {
    int deleteIndex = userProjects.indexWhere((project) => project.id == id);
    userProjects.removeAt(deleteIndex);
    try {
      await networkService.deleteProject(id);
    }
    catch (error) {
      throw connection.NetworkException(
        "Project deletion failed with the following error:\n$error", null);
    }
  }
}

/// A single archaeological project, encompassing layers, units, and pXRF data
/// from a given site.
class Project 
{
  /// Id of the project.
  String? id;

  /// User-given name of the project.
  final String name;

  /// User-given description of the project.
  final String description;

  /// Time the project was created.
  final DateTime createdAt;

  /// Most recent time the project was updated.
  DateTime lastUpdated;

  /// List of layers the project contains.
  final List<LayerSpec> layers = [];

  /// List of units the project contains.
  final List<UnitSpec> units = [];

  /// List of pXRF data files corresponding to the project.
  final List<DataSpec> pxrfData = [];

  Map<String, Map <String, String>>? dataAssignments = {};

  Project(this.name, this.description, this.createdAt, this.lastUpdated);

  /// Creates a new layer at the current time using the given name and 
  /// description and adds it to the project.
  Future<LayerSpec> createLayer(String name, String description) async
  {
    LayerSpec createdLayer = LayerSpec(name, description, DateTime.now(), 
    DateTime.now());
    layers.add(createdLayer);
    lastUpdated = DateTime.now();
    return createdLayer;
  }

  Future<void> setLayerName(String srcName, String newName) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == srcName);
    layers[layerIndex].name = newName;
    layers[layerIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();
    
  }

  Future<void> setLayerDescription(String name, String description) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == name);
    layers[layerIndex].description = description;
    layers[layerIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();
    
  }

  Future<void> deleteLayer(String name) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == name);
    layers.removeAt(layerIndex);
    lastUpdated = DateTime.now();
    
  }

  Future<UnitSpec> createUnit(String name, String description, 
  ({double latitude, double longitude}) topLeft, double width, double height, 
  double pointInterval) async
  {
    UnitSpec createdUnit = UnitSpec(name, description, DateTime.now(), 
      DateTime.now(), topLeft, width, height, pointInterval);
    units.add(createdUnit);
    lastUpdated = DateTime.now();
    throw UnimplementedError();
  }

  Future<void> setUnitName(String srcName, String newName)
  {
    int unitIndex = units.indexWhere((unit) => unit.name == srcName);
    units[unitIndex].name = newName;
    units[unitIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();
    throw UnimplementedError();
  }

  Future<void> setUnitDescription(String name, String description) async
  {
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units[unitIndex].description = description;
    units[unitIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();
    
  }

  Future<void> repositionUnit(String name, ({double latitude, double longitude})
   topLeft, double width, double height, double pointInterval) async
  {
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units[unitIndex].topLeftCoords = topLeft;
    units[unitIndex].width = width;
    units[unitIndex].height = height;
    units[unitIndex].pointInterval = pointInterval;
    units[unitIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

  }

  Future<void> deleteUnit(String name) async
  {
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units.removeAt(unitIndex);
    lastUpdated = DateTime.now();

  }

  Future<void> uploadLayerImage(String layerName, String imageContents) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == layerName);
    layers[layerIndex].layerImage = imageContents;
    layers[layerIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

  }

  Future<String?> getLayerImage(String layerName) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == layerName);
    return layers[layerIndex].layerImage;
  }

  Future<void> removeLayerImage(String layerName) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == layerName);
    layers[layerIndex].layerImage = "";
    lastUpdated = DateTime.now();
  }
}

/// A layer within an archaeological site, representing a stratum at which 
/// different materials are found.
class LayerSpec 
{
  /// User-provided name of the layer.
  String name;

  /// User-provided description of the layer.
  String description;

  /// Most recent time any change was made to the layer.
  DateTime lastUpdated;

  /// Time the layer was created.
  final DateTime createdAt;

  /// String representing the contents of the layer image - empty by default.
  String layerImage = "";

  LayerSpec(this.name, this.description, this.lastUpdated, this.createdAt);
}

/// A unit within an archaeological site, defined by a top left coordinate and
/// a given width and height.
class UnitSpec 
{
  /// User-provided name of the unit.
  String name;

  /// User-provided description of the unit.
  String description;

  /// Most recent time any change was made to the unit.
  DateTime lastUpdated;

  /// Time the unit was created.
  final DateTime createdAt;

  /// Decimal degrees coordinates of the top left corner of the unit.
  ({double latitude, double longitude}) topLeftCoords;

  /// Width of the unit.
  double width;

  /// Height of the unit.
  double height;

  /// Interval between points sampled within the unit.
  double pointInterval;

  UnitSpec(this.name, this.description, this.lastUpdated, this.createdAt, 
  this.topLeftCoords, this.width, this.height, this.pointInterval);
}

/// Pxrf data from a given file corresponding to a specific project.
class DataSpec
{
  /// Name of the data file.
  String fileName;

  /// Id of the corresponding project.
  String projectId;

  /// Time the data file was uploaded to the project.
  DateTime createdAt;

  /// Number of points sampled within the data file.
  int numPoints;

  /// Size of the file.
  int size;

  DataSpec(this.fileName, this.projectId, this.createdAt, this.numPoints, 
    this.size);
}