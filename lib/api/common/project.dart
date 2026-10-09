import '../services/network_service.dart';
import 'network.dart' as network;
import 'specs.dart' as specs;
import 'package:flutter_map_math/flutter_geo_math.dart' as map_math;

/// TODO: Change filepath in functions involving file upload, retrieval, or
/// deletion to accurately reflect where it will be stored in the database.

const List<String> requiredPxrfFields = 
[
  "Test #", "Ag", "Ag +/-", "Al", "Al +/-", "As", "As +/-", "Au", "Au +/-", 
  "Bi", "Bi +/-", "Ca", "Ca +/-" "Cd", "Cd +/-", "Co", "Co +/-", "Cr", "Cr +/-",
  "Cu", "Cu +/-", "Fe", "Fe +/-", "Hf", "Hf +/-", "K", "K +/-", "Li", "Li +/-",
  "Mg", "Mg +/-", "Mn", "Mn +/-", "Mo", "Mo +/-", "Nb", "Nb +/-", "Ni", 
  "Ni +/-", "P", "P +/-", "Pb", "Pb +/-", "Pd", "Pd +/-", "Re", "Re +/-", "Rh", 
  "Rh +/-", "Ru", "Ru +/-", "S", "S +/-", "Sb", "Sb +/-", "Se", "Se +/-", "Si", 
  "Si +/-", "Sn", "Sn +/-", "Sr", "Sr +/-", "Ta", "Ta +/-", "Ti", "Ti +/-", "V", 
  "V +/-", "W", "W +/-", "Zn", "Zn +/-", "Zr", "Zr +/-", "Latitude", "Longitude"
];

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
  final List<specs.LayerSpec> layers = [];
  /// List of units the project contains.
  final List<specs.UnitSpec> units = [];
  /// List of pXRF data files corresponding to the project.
  final List<specs.DataSpec> pxrfData = [];
  /// List of training data files corresponding to the project.
  final List<specs.DataSpec> trainingData = [];
  /// Map of layer and unit names to file names.
  final Map<String, Map <String, String>> dataAssignments = {};

  Project(this.name, this.description, this.createdAt);

  /// Adds a file containing pXRF data to the project after validating the
  /// file's contents.
  /// 
  /// Throws a [ProjectException] if the file cannot be validated and a
  /// [network.ApiNetworkException] if the file cannot successfully be uploaded
  /// or the project cannot be modified.
  Future<void> addPxrfData(String fileName, String fileContents) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    int numPoints = validateDataFile(false, fileContents);
    if (numPoints == 0) {
      // TODO: Describe specifically what the issue is to the user. I wasn't 
      // sure how to implement this elegantly - it didn't seem best to throw an
      // exception within the validateDataFile function itself, and I couldn't
      // work out a good way to pass the source of the error back here - so I 
      // am leaving it for now.
      throw ProjectException(
        "Given data is not correctly formatted - either fields are missing or "
        "no data is present."
      );
    }
    // Setting size to 0 for the time being since that seems like something the
    // backend would handle.
    specs.DataSpec pxrfFile = specs.DataSpec(
      fileName, 
      id!, 
      DateTime.now(), 
      numPoints, 
      0
    );
    pxrfData.add(pxrfFile);
    lastUpdated = DateTime.now();
    String filePath = "";
    try {
      await networkService.writeFile(filePath, fileContents);
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Fetches a pXRF data file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the training data could not
  /// successfully be fetched.
  Future<String?> getPxrfData(String fileName) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    String filePath = "";
    String? fileContents;
    try {
      fileContents = await networkService.fetchFile(filePath);
      return fileContents;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data could not be fetched due to the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Removes a pxrf data spec from the project alongside any corresponding data
  /// assignments and deletes the appropriate file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the pXRF data could not
  /// sunccessfully be removed.
  Future<void> removePxrfData(String fileName) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    int fileIndex = pxrfData.indexWhere(
      (file) => file.fileName == fileName);
    pxrfData.removeAt(fileIndex);
    lastUpdated = DateTime.now();

    dataAssignments.removeWhere((filename, assignment) => filename == fileName);

    try {
        String filePath = "";
        await networkService.deleteFile(filePath);
        await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Adds a file containing training data to the project after validating the
  /// file's contents.
  /// 
  /// Throws a [ProjectException] if the file cannot be validated and a
  /// [network.ApiNetworkException] if the file cannot successfully be uploaded
  /// or the project cannot be modified.
  Future<void> addTrainingData(String fileName, String fileContents) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    int numPoints = validateDataFile(true, fileContents);
    if (numPoints == 0) {
      // TODO: Describe specifically what the issue is to the user. I wasn't 
      // sure how to implement this elegantly - it didn't seem best to throw an
      // exception within the validateDataFile function itself - so I am leaving
      // this for now.
      throw ProjectException(
        "Given data is not correctly formatted - either fields are missing or "
        "no data is present."
      );
    }
    specs.DataSpec trainFile = specs.DataSpec(
      fileName, 
      id!, 
      DateTime.now(), 
      numPoints, 
      0
    );
    trainingData.add(trainFile);
    lastUpdated = DateTime.now();
    String filePath = "";
    try {
      await networkService.writeFile(filePath, fileContents);
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Fetches a training data file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the training data could not
  /// successfully be fetched.
  Future<String?> getTrainingData(String fileName) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    /// TODO: As with layer image, change this to the appropriate filepath.
    String filePath = "";
    String? fileContents;
    try {
      fileContents = await networkService.fetchFile(filePath);
      return fileContents;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data could not be fetched"
        "due to the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Removes a training data spec from the project and deletes the 
  /// corresponding file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the training data could not
  /// sunccessfully be removed.
  Future<void> removeTrainingData(String fileName) async 
  {
    NetworkService networkService = NetworkService.getInstance();
    int fileIndex = trainingData.indexWhere(
      (file) => file.fileName == fileName);
    trainingData.removeAt(fileIndex);
    lastUpdated = DateTime.now();

    try {
        String filePath = "";
        await networkService.deleteFile(filePath);
        await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Creates a new layer at the current time using the given name and 
  /// description and adds it to the project.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if given layer name matches
  /// a pre-existing layer.
  Future<specs.LayerSpec> createLayer(String name, String description) 
    async
  {
    NetworkService networkService = NetworkService.getInstance();
    // Check if a pre-existing layer has the same name and only make a new 
    // layer if not
    Iterable<specs.LayerSpec> duplicateName = layers.where(
      (layer) => layer.name == name);

    if (duplicateName.isEmpty) {
      specs.LayerSpec createdLayer = specs.LayerSpec(
        name, 
        description, 
        DateTime.now(), 
        DateTime.now()
      );
      layers.add(createdLayer);
      lastUpdated = DateTime.now();

      try {
        // Filepath to the directory where the layer's corresponding image will
        // be stored - leaving this empty for now since the database isn't set
        // up, but I'm assuming the directory will be labelled with the layer's
        // name
        String layerFilePath = "";
        await networkService.uploadProject(this);
        await networkService.createDirectory(layerFilePath);
        return createdLayer;
      }
      on network.ApiNetworkException catch (error) {
        throw network.ApiNetworkException(
          "Layer creation failed with the following error:\n$error", 
          error.statusCode
        );
      }
      
    }
    else {
      throw ProjectException(
        "Layer cannot have the same name as a pre-existing layer."
      );
    }
  }

  /// Changes the name of a pre-existing layer.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new layer name matches
  /// a pre-existing layer.
  Future<void> setLayerName(String srcName, String newName) async
  {
    NetworkService networkService = NetworkService.getInstance();
    // Check if a pre-existing layer has the same name and only change the
    // name if not
    Iterable<specs.LayerSpec> duplicateName = layers.where(
      (layer) => layer.name == newName);

    if (duplicateName.isEmpty) {
      int layerIndex = layers.indexWhere((layer) => layer.name == srcName);
      layers[layerIndex].name = newName;
      layers[layerIndex].lastUpdated = DateTime.now();
      lastUpdated = DateTime.now();

      try {
        await networkService.uploadProject(this);
      }
      on network.ApiNetworkException catch (error) {
        throw network.ApiNetworkException(
          "Project failed to update with the following error:\n$error", 
          error.statusCode
        );
      }
    }
    else {
      throw ProjectException(
        "Layer cannot have the same name as a pre-existing layer."
      );
    }
  }

  /// Changes the description of a pre-existing layer.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> setLayerDescription(String name, String description) async
  {
    NetworkService networkService = NetworkService.getInstance();
    int layerIndex = layers.indexWhere((layer) => layer.name == name);
    layers[layerIndex].description = description;
    layers[layerIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

    try {
        await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Deletes a layer from the project and deletes the corresponding directory
  /// and image file.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification or the layer cannot be successfully deleted.
  Future<void> deleteLayer(String name) async
  {
    NetworkService networkService = NetworkService.getInstance();
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
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Creates a new unit and initializes its fields with the given parameters, 
  /// then checks for any conflict with pre-existing units.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded
  /// after modification and a [Project.Exception] if either a unit already
  /// exists with the same name or the current unit overlaps with a pre-existing
  /// unit.
  Future<specs.UnitSpec> createUnit(
    String name, 
    String description, 
    ({double latitude, double longitude}) topLeft, 
    double width, 
    double height, 
    double pointInterval
  ) async
  {
    NetworkService networkService = NetworkService.getInstance();
    // Check to make sure no pre-existing unit has the same name.
    Iterable<specs.UnitSpec> duplicateName = units.where(
      (unit) => unit.name == name);
    if (duplicateName.isEmpty) {
      specs.UnitSpec createdUnit = specs.UnitSpec(
        name, 
        description,
        DateTime.now(),
        DateTime.now(), 
        topLeft, 
        width, 
        height, 
        pointInterval, 
      );

      // Check to make sure there is no overlap between the new unit and any
      // pre-existing unit.
      for (var i = 0; i < units.length; i++) {
        if (isOverlapping(createdUnit, units[i])) {
          throw ProjectException(
            "Created unit overlaps with unit ${units[i].name}."
          );
        }
      }

      // If all checks pass, attempt to add unit.
      units.add(createdUnit);
      lastUpdated = DateTime.now();
      try {
        await networkService.uploadProject(this);
      }
      on network.ApiNetworkException catch (error) {
        throw network.ApiNetworkException(
          "Project failed to update with the following error:\n$error", 
          error.statusCode
        );
      }
      return createdUnit;
    }
    throw ProjectException(
      "Unit cannot have the same name as a pre-existing unit."
    );
  }

  /// Changes the name of a pre-existing unit.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new unit name matches
  /// a pre-existing unit.
  Future<void> setUnitName(String srcName, String newName) async
  {
    NetworkService networkService = NetworkService.getInstance();
    // Check if a pre-existing unit has the same name and only change the
    // name if not.
    Iterable<specs.UnitSpec> duplicateName = units.where(
      (unit) => unit.name == newName);

    if (duplicateName.isEmpty) {
      int unitIndex = units.indexWhere((unit) => unit.name == srcName);
      units[unitIndex].name = newName;
      units[unitIndex].lastUpdated = DateTime.now();
      lastUpdated = DateTime.now();

      try {
        await networkService.uploadProject(this);
      }
      // TODO: Rename file in the backend - renameFile() function needs to be
      // implemented in our network service
      on network.ApiNetworkException catch (error) {
        throw network.ApiNetworkException(
          "Project failed to update with the following error:\n$error", 
          error.statusCode
        );
      }
    }
    else {
      throw ProjectException(
        "Unit cannot have the same name as a pre-existing unit."
      );
    }
  }
  
  /// Changes the description of a pre-existing unit.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> setUnitDescription(String name, String description) async
  {
    NetworkService networkService = NetworkService.getInstance();
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units[unitIndex].description = description;
    units[unitIndex].lastUpdated = DateTime.now();
    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Attempts to reposition a unit after checking that its new position doesn't
  /// overlap with any pre-existing units, and discards any data assignments
  /// that no longer fits the unit's new positioning.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if repositioning would incur
  /// overlap with another unit.
  Future<void> repositionUnit(String name, ({double latitude, double longitude})
   topLeft, double width, double height, double pointInterval) async
  {
    NetworkService networkService = NetworkService.getInstance();
    // Initialize updated unit with position fields in order to check for
    // overlap.
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    specs.UnitSpec updatedUnit = specs.UnitSpec(
      "", 
      "", 
      DateTime.now(), 
      DateTime.now(),
      topLeft,
      width,
      height,
      pointInterval
    );

    // Check to make sure there is no overlap between the repositioned unit and 
    /// any pre-existing unit.
    for (var i = 0; i < units.length; i++) {
      if (isOverlapping(updatedUnit, units[i])) {
        throw ProjectException(
          "Created unit overlaps with unit ${units[i].name}."
        );
      }
    }

    // If no overlap is present, change position of unit.
    units[unitIndex].topLeftCoords = topLeft;
    units[unitIndex].width = width;
    units[unitIndex].height = height;
    units[unitIndex].pointInterval = pointInterval;
    units[unitIndex].lastUpdated = DateTime.now();

    // Check that data assigned to the unit still falls within its bounds and
    // remove assignments that do not.
    dataAssignments.forEach((filename, assignment) {
       assignment.forEach((layer, unit) {
        if (unit == name) 
        {
          Future<String?> fileContents = getPxrfData(filename);
          fileContents.then((value) {
            if (!checkAssignment(value!, units[unitIndex])) {
              dataAssignments.remove(filename);
            }
          });
        }
      });
    });

    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Deletes a unit from the project.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> deleteUnit(String name) async
  {
    NetworkService networkService = NetworkService.getInstance();
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    units.removeAt(unitIndex);
    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Assigns a layer and unit to a file after first confirming that the given
  /// data fits within the unit.
  /// 
  /// Throws a [ProjectException] if data does not fit within the unit and a
  /// [network.ApiNetworkException] if the project fails to upload.
  Future<void> assignData(String layerName, String unitName, String fileName) 
  async
  {
    NetworkService networkService = NetworkService.getInstance();

    // Ensure provided data fits within the given unit.
    int unitIndex = units.indexWhere((unit) => unit.name == name);
    Future<String?> fileContents = getPxrfData(fileName);
    fileContents.then((value) {
      if (!checkAssignment(value!, units[unitIndex])) {
        throw ProjectException(
          "Data from the file $fileName cannot be assigned to unit $unitName."
        );
      }
    });

    final layerUnitMap = <String, String>{layerName: unitName};
    dataAssignments[fileName] = layerUnitMap;

    lastUpdated = DateTime.now();

    try {
      await networkService.uploadProject(this);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Uploads an image corresponding to a layer to the appropriate location in
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the image fails to upload.
  Future<void> uploadLayerImage(String layerName, String imageContents) async
  {
    NetworkService networkService = NetworkService.getInstance();
    String filePath = "";
    try {
      networkService.writeFile(filePath, imageContents);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer image failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Fetches an image corresponding to a layer from the appropriate location in
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the image cannot be retrieved.
  Future<String?> getLayerImage(String layerName) async
  {
    NetworkService networkService = NetworkService.getInstance();
    String filePath = "";
    String? imageContents;
    try {
      imageContents = await networkService.fetchFile(filePath);
      return imageContents;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer image could not be fetched due to the following error:\n$error", 
        error.statusCode
      );
    }
  }

  /// Deletes an image corresponding to a layer from the appropriate location in
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the image cannot be deleted.
  Future<void> removeLayerImage(String layerName) async
  {
    NetworkService networkService = NetworkService.getInstance();
    String filePath = "";
    try {
      await networkService.deleteFile(filePath);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer image could not be deleted due to the following error:\n$error", 
        error.statusCode
      );
    }
  }
}

/* ================================ Utility ================================ */

/// Checks if two units are overlapping and returns true if so, false if not.
bool isOverlapping(specs.UnitSpec unit1, specs.UnitSpec unit2)
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
bool isWithinUnit(specs.UnitSpec unit, double latitude, double longitude)
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
bool checkAssignment(String fileContents, specs.UnitSpec unit) 
{
  List<List<String>> formattedData = [];
  List<String> fileLines = fileContents.split('\n');
  for (var i = 0; i < fileLines.length; i++) {
    formattedData.add(fileLines[i].split(','));
  }

  int latIndex = formattedData[0].indexWhere((field) => field == "Latitude");
  int longIndex = formattedData[0].indexWhere((field) => field == "Longitude");

  // Extract the coordinates for each data point and check if they fall within
  // the unit.
  for (var i = 1; i < fileLines.length; i++) {
    double latitude = double.parse(formattedData[i][latIndex]);
    double longitude = double.parse(formattedData[i][longIndex]);
    if (!isWithinUnit(unit, latitude, longitude))
    {
      return false;
    }
  }

  return true;
}

/// Checks to make sure all required fields are present in the data file (the
/// order in which they're present doesn't matter) and that data is there in 
/// the first place. If the checks are successful, the function returns the 
/// number of sample points in the file; otherwise, it returns 0.
int validateDataFile(bool isTrainingData, String fileContents) 
{
  List<List<String>> formattedData = [];
  List<String> fileLines = fileContents.split('\n');
  for (var i = 0; i < fileLines.length; i++) {
    formattedData.add(fileLines[i].split(','));
  }

  // Check to make sure data is actually there.
  if (fileLines.length <= 1)
  {
    return 0;
  }

  // Check to make sure none of the required fields are missing.
  for (var i = 0; i < requiredPxrfFields.length; i++) {
    if (formattedData[0].indexWhere(
      (field) => field == requiredPxrfFields[i]) == -1
    ) {
      return 0;
    }
  }

  // If the data is training data, check to make sure the material field is 
  // present.
  if (isTrainingData && formattedData[0].indexWhere(
      (field) => field == "material") == -1
  ) {
    return 0;
  }

  // If all checks pass, return the number of data points in the file.
  return fileLines.length - 1;
}