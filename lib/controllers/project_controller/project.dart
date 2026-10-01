import '../../services/network_service.dart' as network_service;
import '../../airdroid/connection.dart' as connection;
import 'project_components.dart' as components;

/// Thrown whenever an attempt to modify a project would result in conflicts
/// with the project's current state.
class ProjectException implements Exception
{
  /// The error message.
  final String message;

  const ProjectException(this.message);

  @override
  String toString()
    => message;
}

network_service.NetworkService networkService = 
  network_service.NetworkService.getInstance();

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
  DateTime? lastUpdated;
  /// List of layers the project contains.
  final List<components.LayerSpec> layers = [];
  /// List of units the project contains.
  final List<components.UnitSpec> units = [];
  /// List of pXRF data files corresponding to the project.
  final List<components.DataSpec> pxrfData = [];

  Map<String, Map <String, String>>? dataAssignments = {};

  Project(this.name, this.description, this.createdAt);

  /// Creates a new layer at the current time using the given name and 
  /// description and adds it to the project.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if given layer name matches
  /// a pre-existing layer.
  Future<components.LayerSpec> createLayer(String name, String description) async
  {
    /// Check if a pre-existing layer has the same name and only make a new 
    /// layer if not
    Iterable<components.LayerSpec> duplicateName = layers.where((layer) 
      => layer.name == name);

    if (duplicateName.isEmpty) {
      components.LayerSpec createdLayer = components.LayerSpec();
      createdLayer.name = name;
      createdLayer.description = description;
      createdLayer.createdAt = DateTime.now();
      createdLayer.lastUpdated = DateTime.now();
      layers.add(createdLayer);
      lastUpdated = DateTime.now();

      try {
        /// Filepath to the directory where the layer's corresponding image will
        /// be stored - leaving this empty for now since the database isn't set
        /// up, but I'm assuming the directory will be labelled with the layer's
        /// name
        String layerFilePath = "";
        await networkService.uploadProject(this);
        await networkService.createDirectory(layerFilePath);
        return createdLayer;
      }
      catch (error) {
        throw connection.NetworkException(
        "Layer creation failed with the following error:\n$error", null);
      }
      
    }
    else {
      throw ProjectException(
        "Layer cannot have the same name as a pre-existing layer.");
    }
  }

  /// Changes the name of a pre-existing layer.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new layer name matches
  /// a pre-existing layer.
  Future<void> setLayerName(String srcName, String newName) async
  {
    /// Check if a pre-existing layer has the same name and only change the
    /// name if not
    Iterable<components.LayerSpec> duplicateName = layers.where((layer) 
      => layer.name == newName);

    if (duplicateName.isEmpty) {
      int layerIndex = layers.indexWhere((layer) => layer.name == srcName);
      layers[layerIndex].name = newName;
      layers[layerIndex].lastUpdated = DateTime.now();
      lastUpdated = DateTime.now();

      try {
        await networkService.uploadProject(this);
      }
      catch (error) {
        throw connection.NetworkException(
        "Project failed to update with the following error:\n$error", null);
      }
    }
    else {
      throw ProjectException(
      "Layer cannot have the same name as a pre-existing layer.");
    }
  }

  /// Changes the description of a pre-existing layer.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> setLayerDescription(String name, String description) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == name);
    layers[layerIndex].description = description;
    layers[layerIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

    try {
        await networkService.uploadProject(this);
    }
    catch (error) {
      throw connection.NetworkException(
      "Project failed to update with the following error:\n$error", null);
    }
  }

  /// Deletes a layer from the project and deletes the corresponding directory
  /// and image file.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification or the layer cannot be successfully deleted.
  Future<void> deleteLayer(String name) async
  {
    int layerIndex = layers.indexWhere((layer) => layer.name == name);
    layers.removeAt(layerIndex);
    lastUpdated = DateTime.now();

    try {
        String imageFilePath = "";
        String layerFilePath = "";
        await networkService.deleteFile(imageFilePath);
        await networkService.deleteDirectory(layerFilePath);
        await networkService.uploadProject(this);
    }
    catch (error) {
      throw connection.NetworkException(
      "Layer failed to delete with the following error:\n$error", null);
    }
  }

  /// Creates a new unit and initializes its fields with the given parameters, 
  /// then checks for any conflict with pre-existing units.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded
  /// after modification and a [Project.Exception] if either a unit already
  /// exists with the same name or the current unit overlaps with a pre-existing
  /// unit.
  Future<components.UnitSpec> createUnit(String name, String description, 
  ({double latitude, double longitude}) topLeft, double width, double height, 
  double pointInterval) async
  {
    /// Check to make sure no pre-existing unit has the same name
    Iterable<components.UnitSpec> duplicateName = units.where((unit) => unit.name == name);
    if (duplicateName.isEmpty) {
      components.UnitSpec createdUnit = components.UnitSpec();
      createdUnit.name = name;
      createdUnit.description = description;
      createdUnit.topLeftCoords = topLeft;
      createdUnit.width = width;
      createdUnit.height = height;
      createdUnit.pointInterval = pointInterval;
      createdUnit.createdAt = DateTime.now();
      createdUnit.lastUpdated = DateTime.now();

      /// Check to make sure there is no overlap between the new unit and any
      /// pre-existing unit
      for (var i = 0; i < units.length; i++) {
        if (components.isOverlapping(createdUnit, units[i])) {
          throw ProjectException(
            "Unit cannot overlap with any pre-existing units.");
        }
      }

      /// If all checks pass, attempt to add unit
      units.add(createdUnit);
      lastUpdated = DateTime.now();
      try {
        await networkService.uploadProject(this);
      }
      catch (error) {
        throw connection.NetworkException(
        "Project failed to update with the following error:\n$error", null);
      }
      return createdUnit;
    }
    throw ProjectException(
      "Unit cannot have the same name as a pre-existing unit.");
  }

  /// Changes the name of a pre-existing unit.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new unit name matches
  /// a pre-existing unit.
  Future<void> setUnitName(String srcName, String newName) async
  {
    /// Check if a pre-existing unit has the same name and only change the
    /// name if not
    Iterable<components.UnitSpec> duplicateName = units.where((unit) 
      => unit.name == newName);

    if (duplicateName.isEmpty) {
      int unitIndex = units.indexWhere((unit) => unit.name == srcName);
      units[unitIndex].name = newName;
      units[unitIndex].lastUpdated = DateTime.now();
      lastUpdated = DateTime.now();

      try {
        await networkService.uploadProject(this);
      }
      catch (error) {
        throw connection.NetworkException(
        "Project failed to update with the following error:\n$error", null);
      }
    }
    else {
      throw ProjectException(
      "Unit cannot have the same name as a pre-existing unit.");
    }
  }
  
  /// Changes the description of a pre-existing unit.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> setUnitDescription(String name, String description) async
  {
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units[unitIndex].description = description;
    units[unitIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    catch (error) {
      throw connection.NetworkException(
      "Project failed to update with the following error:\n$error", null);
    }
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

  /// Deletes a unit from the project.
  /// 
  /// Throws a [connection.NetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> deleteUnit(String name) async
  {
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units.removeAt(unitIndex);
    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    catch (error) {
      throw connection.NetworkException(
      "Project failed to update with the following error:\n$error", null);
    }
  }

  /// Uploads an image corresponding to a layer to the appropriate location in
  /// the database.
  /// 
  /// Throws a [connection.NetworkException] if the image fails to upload.
  Future<void> uploadLayerImage(String layerName, String imageContents) async
  {
    String filePath = "";
    try {
      networkService.writeFile(filePath, imageContents);
    }
    catch (error) {
      throw connection.NetworkException(
        "Layer image failed to upload with the following error:\n$error", null);
    }
  }

  /// Fetches an image corresponding to a layer from the appropriate location in
  /// the database.
  /// 
  /// Throws a [connection.NetworkException] if the image cannot be retrieved.
  Future<String?> getLayerImage(String layerName) async
  {
    String filePath = "";
    String? imageContents;
    try {
      imageContents = await networkService.fetchFile(filePath);
      return imageContents;
    }
    catch (error) {
      throw connection.NetworkException(
        "Layer image could not be fetched due to the following error:\n$error", 
        null);
    }
  }

  /// Deletes an image corresponding to a layer from the appropriate location in
  /// the database.
  /// 
  /// Throws a [connection.NetworkException] if the image cannot be deleted.
  Future<void> removeLayerImage(String layerName) async
  {
    String filePath = "";
    try {
      await networkService.deleteFile(filePath);
    }
    catch (error) {
      throw connection.NetworkException(
        "Layer image could not be deleted due to the following error:\n$error", 
        null);
    }
  }
}
