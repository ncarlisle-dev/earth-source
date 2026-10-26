import 'dart:async';

import 'package:archaeo_sight_2/api/common/common.dart';

import '../services/network_service.dart';
import 'network.dart' as network;
import 'specs.dart' as specs;
import 'jobs.dart' as jobs;
import 'package:latlong2/latlong.dart' as latlong;

typedef Coordinate = ({ double latitude, double longitude });

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
  // TODO: turn these fields private and expose getters only

  /// ID of the project.
  final String id;
  /// User-given name of the project.
  String name;
  /// User-given description of the project.
  String description;
  /// Location of the corners of the project site.
  List<latlong.LatLng> corners;
  /// List of layers the project contains.
  final List<specs.Layer> layers;
  /// List of units the project contains.
  final List<specs.Unit> units;
  /// List of pXRF data files corresponding to the project.
  final List<specs.PxrfDataSpec> pxrfData;
  /// List of training data files corresponding to the project.
  final List<specs.TrainingDataSpec> trainingData;
  /// Map of layer and unit ids to file ids.
  final Map<String, Map <String, String?>> dataAssignments;
  /// List of batch jobs for generating predictions.
  final List<jobs.PredictionJob> predictions;
  /// List of batch jobs for training models.
  final List<jobs.TrainingJob> models;
  /// UTM zone of the project site.
  int utmZone;
  /// Boolean that tracks whether or not the project is in the Southern 
  /// Hemisphere.
  bool isSouthernHemisphere;
  /// Time the project was created.
  final DateTime createdAt;
  /// Most recent time the project was updated.
  DateTime lastUpdated;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.corners,
    required this.layers,
    required this.units,
    required this.pxrfData,
    required this.trainingData,
    required this.dataAssignments,
    required this.predictions,
    required this.models,
    required this.utmZone,
    required this.isSouthernHemisphere,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Changes the name of a project and uploads the modified project to the 
  /// database.
  /// 
  /// Throws a [network.ApiNetworkException] if the update fails.
  Future<void> setName(String name) async
  {
    final networkService = await NetworkService.getInstance();
    try {
      lastUpdated = await networkService.setProjectMetadata(id, name: name);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    name = name;
  }


  /// Changes the description of a project and uploads the modified project to
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the update fails.
  Future<void> setDescription(String newDescription) async
  {
    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.setProjectMetadata(id, description: newDescription);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    description = newDescription;
  }

  Future<void> setUtmZone(int utmZone) async
  {
    assert(utmZone >= 0 && utmZone <= 60, "UTM zone is invalid.");

    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.setProjectMetadata(
        id,
        utmZone: utmZone
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    utmZone = utmZone;
  }

  Future<void> setHemisphere(bool isSouthern) async
  {
    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.setProjectMetadata(
        id,
        isSouthernHemisphere: isSouthern
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    isSouthernHemisphere = isSouthern;
  }

  /// Adds a file containing pXRF data to the project after validating the
  /// file's contents.
  /// 
  /// Throws a [network.ApiNetworkException] if the upload fails.
  Future<PxrfDataSpec> addPxrfData(
    String fileContents,
    String fileName,
    String description,
  ) async
  {
    validateDataFile(false, fileContents);

    final networkService = await NetworkService.getInstance();
    final specs.PxrfDataSpec createdSpec;

    try {
      createdSpec = await networkService.addPxrfData(
        id,
        fileContents,
        fileName,
        description
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }

    pxrfData.add(createdSpec);
    lastUpdated = createdSpec.createdAt;
    return createdSpec;
  }

  /// Fetches a pXRF data file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the training data could not
  /// successfully be fetched.
  Future<String> getPxrfData(String specId) async 
  {
    final networkService = await NetworkService.getInstance();
    final String fileContents;

    try {
      fileContents = await networkService.fetchPxrfData(id, specId);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data could not be fetched due to the following error:\n$error", 
        error.statusCode
      );
    }

    return fileContents;
  }

  /// Removes a pxrf data spec from the project alongside any corresponding data
  /// assignments and deletes the appropriate file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the pXRF data could not
  /// sunccessfully be removed.
  Future<void> removePxrfData(String id) async 
  {
    final networkService = await NetworkService.getInstance();
    final specIndex = pxrfData.indexWhere((spec) => spec.id == id);
    assert(
      specIndex >= 0,
      "Project doesn't have pXRF data spec with ID '$id'."
    );

    try {
      lastUpdated = await networkService.deletePxrfData(id, id);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "pXRF data failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }

    dataAssignments.forEach((layerId, layerAssignments) {
      layerAssignments.forEach((unitId, specId) {
        if (pxrfData[specIndex].id == specId) {
          dataAssignments[layerId]![unitId] = null;
        }
      });
    });

    pxrfData.removeAt(specIndex);
  }

  /// Adds a file containing training data to the project after validating the
  /// file's contents.
  /// 
  /// Throws a [network.ApiNetworkException] if the upload fails.
  Future<TrainingDataSpec> addTrainingData(
    String fileContents,
    String fileName,
    String description,
  ) async
  {
    final networkService = await NetworkService.getInstance();
    validateDataFile(true, fileContents);

    final TrainingDataSpec createdSpec;

    try {
      createdSpec = await networkService.addTrainingData(
        id,
        fileContents,
        fileName,
        description
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }

    trainingData.add(createdSpec);
    lastUpdated = createdSpec.createdAt;
    return createdSpec;
  }

  /// Fetches a training data file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the network request fails.
  Future<String> getTrainingData(String specId) async 
  {
    final networkService = await NetworkService.getInstance();
    final String fileContents;

    try {
      fileContents = await networkService.fetchTrainingData(id, specId);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data could not be fetched"
        "due to the following error:\n$error", 
        error.statusCode
      );
    }

    return fileContents;
  }

  /// Removes a training data spec from the project and deletes the 
  /// corresponding file from the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the training data could not
  /// sunccessfully be removed.
  Future<void> removeTrainingData(String specId) async 
  {
    final networkService = await NetworkService.getInstance();
    final int specIndex = trainingData.indexWhere((spec) => spec.id == specId);

    assert(
      specIndex >= 0,
      "Project doesn't have training data spec with ID '$specId'."
    );

    try {
      lastUpdated = await networkService.deleteTrainingData(id, specId);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Training data failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }

    trainingData.removeAt(specIndex);
  }

  /// Creates a new layer at the current time using the given name and 
  /// description and adds it to the project.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<specs.Layer> createLayer(
    String name, 
    String description, 
    List<Coordinate> corners
  ) async
  {
    assert(corners.length == 4, "corners doesn't have four elements.");

    final networkService = await NetworkService.getInstance();
    final Layer createdLayer;

    try {
      final (:createdLayers, :timestamp, createdUnits: _) =
        await networkService.configureProjectSite(
          id,
          newLayers: [(
            name: name,
            description: description,
            corners: corners,
          )],
        );

      createdLayer = createdLayers[0];
      lastUpdated = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer creation failed with the following error:\n$error", 
        error.statusCode
      );
    }

    layers.add(createdLayer);
    return createdLayer;
  }

  /// Changes the name of a pre-existing layer.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new layer name matches
  /// a pre-existing layer.
  Future<void> updateLayer(
    String id,
    {
      String?           name,
      String?           description,
      List<Coordinate>? corners,
    }
  ) async
  {
    // validate arguments
    assert(
      name != null || description != null || corners != null,
      "No updates specified."
    );

    final layerIndex = layers.indexWhere((layer) => layer.id == id);
    assert(layerIndex >= 0, "Layer with ID '$id' not found.");

    // make network request
    final networkService = await NetworkService.getInstance();
    final DateTime updateTimestamp;

    try {
      final (createdLayers: _, createdUnits: _, :timestamp) = 
        await networkService.configureProjectSite(
          this.id,
          layerUpdates: {
            id: (
              name: name,
              description: description,
              corners: corners,
            )
          }
        );

      updateTimestamp = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    // set local fields
    if (name != null) layers[layerIndex].name = name;
    if (description != null) layers[layerIndex].description = description;
    if (corners != null) {
      layers[layerIndex].corners = corners
      .map(convertCoordRecordToObj)
      .toList();
    }

    layers[layerIndex].lastUpdated = updateTimestamp;
    lastUpdated = updateTimestamp;
  }

  /// Deletes a layer from the project and deletes the corresponding directory
  /// and image file.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification or the layer cannot be successfully deleted.
  Future<void> deleteLayer(String id) async
  {
    final int layerIndex = layers.indexWhere((layer) => layer.id == id);
    assert(layerIndex >= 0, "Layer with ID '$id' not found.");

    final networkService = await NetworkService.getInstance();

    try {
      final (createdLayers: _, createdUnits: _, :timestamp) = 
        await networkService.configureProjectSite(
          this.id,
          layersToDelete: [id],
        );
      
      lastUpdated = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }

    dataAssignments.remove(id);
    layers.removeAt(layerIndex);
  }

  /// Creates a new unit and initializes its fields with the given parameters, 
  /// then checks for any conflict with pre-existing units.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded
  /// after modification and a [Project.Exception] if either a unit already
  /// exists with the same name or the current unit overlaps with a pre-existing
  /// unit.
  Future<specs.Unit> createUnit(
    String           name, 
    String           description, 
    List<Coordinate> corners, 
    double           pointInterval
  ) async
  {
    assert(corners.length == 4, "corners doesn't have four elements.");

    // Check to make sure there is no overlap between the new unit and any
    // pre-existing units.
    for (final unit in units) {
      if (
        isOverlapping(
          corners.map(convertCoordRecordToObj).toList(),
          unit.corners
        )
      ) {
        throw ProjectException(
          "Created unit overlaps with unit '${unit.name}."
        );
      }
    }

    // If all checks pass, attempt to add unit.
    final networkService = await NetworkService.getInstance();

    final Unit createdUnit;
    final DateTime updateTimestamp;

    try {
      final (createdLayers: _, :createdUnits, :timestamp) = 
        await networkService.configureProjectSite(
          id,
          newUnits: [(
            name:          name,
            description:   description,
            pointInterval: pointInterval,
            corners:       corners,
          )],
        );
      
      createdUnit = createdUnits[0];
      updateTimestamp = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    units.add(createdUnit);
    lastUpdated = updateTimestamp;

    return createdUnit;
  }

  /// Changes the name of a pre-existing unit.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new unit name matches
  /// a pre-existing unit.
  Future<void> updateUnit(
    String id,
    {
      String?           name,
      String?           description,
      List<Coordinate>? corners,
      double?           pointInterval,
    }
  ) async
  {
    // validate arguments
    assert(
      name != null 
        || description != null
        || corners != null
        || pointInterval != null,
      "No updates specified."
    );

    final unitIndex = units.indexWhere((unit) => unit.id == id);
    assert(unitIndex >= 0, "Unit with ID '$id' not found.");

    final cornerObjs = corners?.map(convertCoordRecordToObj).toList();

    if (cornerObjs != null) {
      for (final unit in units) {
        if (isOverlapping(cornerObjs,unit.corners)) {
          throw ProjectException(
            "Modified unit overlaps with unit '${unit.name}."
          );
        }
      }
    }

    // make network request
    final networkService = await NetworkService.getInstance();
    final DateTime updateTimestamp;

    try {
      final (createdLayers: _, createdUnits: _, :timestamp) = 
        await networkService.configureProjectSite(
          this.id,
          unitUpdates: {
            id: (
              name:          name,
              description:   description,
              corners:       corners,
              pointInterval: pointInterval,
            )
          }
        );

      updateTimestamp = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    // Check that data assigned to the unit still falls within its bounds and
    // remove assignments that do not.
    if (cornerObjs != null) {
      dataAssignments.forEach((layerId, layerAssignments) async {
        final specId = layerAssignments[id];
        if (specId == null) return;

        final specIndex = pxrfData.indexWhere((spec) => spec.id == specId);
        assert(specIndex >= 0, "Spec with ID '$specId' not found.");

        if (!checkAssignment(pxrfData[specIndex], cornerObjs)) {
          dataAssignments[layerId]![id] = null;
        }
      });
    }

    // set local fields
    if (name != null)          units[unitIndex].name = name;
    if (description != null)   units[unitIndex].description = description;
    if (cornerObjs != null)    units[unitIndex].corners = cornerObjs;
    if (pointInterval != null) units[unitIndex].pointInterval = pointInterval;

    units[unitIndex].lastUpdated = updateTimestamp;
    lastUpdated = updateTimestamp;
  }

  /// Deletes a unit from the project.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification.
  Future<void> deleteUnit(String id) async
  {
    final int unitIndex = units.indexWhere((unit) => unit.id == id);
    assert(unitIndex >= 0, "Unit with ID '$id' not found.");

    final networkService = await NetworkService.getInstance();

    try {
      final (createdLayers: _, createdUnits: _, :timestamp) = 
        await networkService.configureProjectSite(
          this.id,
          unitsToDelete: [id],
        );
      
      lastUpdated = timestamp;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Unit failed to delete with the following error:\n$error", 
        error.statusCode
      );
    }

    for (final layerId in dataAssignments.keys) {
      dataAssignments[layerId]!.remove(id);
    }

    units.removeAt(unitIndex);
  }

  /// Assigns a layer and unit to a file after first confirming that the given
  /// data fits within the unit.
  /// 
  /// Throws a [ProjectException] if data does not fit within the unit and a
  /// [network.ApiNetworkException] if the project fails to upload.
  Future<void> assignData(String layerId, String unitId, String specId) async
  {
    // validate args
    final int layerIndex = layers.indexWhere((layer) => layer.id == layerId);
    final int unitIndex = units.indexWhere((unit) => unit.id == unitId);
    final int specIndex = pxrfData.indexWhere((spec) => spec.id == specId);

    assert(layerIndex >= 0, "Layer with ID '$layerId' not found.");
    assert(unitIndex >= 0, "Unit with ID '$unitId' not found.");
    assert(specIndex >= 0, "pXRF data spec with ID '$specIndex' not found.");

    // Ensure provided data fits within the given unit.
    if (!checkAssignment(pxrfData[specIndex], units[unitIndex].corners)) {
      throw ProjectException(
        "Data from pXRF data spec with ID '$specId' cannot be assigned to unit "
        "with ID '$unitId'."
      );
    }

    // make updates
    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.assignProjectPxrfData(
        id,
        layerId,
        unitId,
        specId
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    dataAssignments[layerId]![unitId] = specId;
  }

  /// Sends the data files assigned to the layer passed by name as a parameter 
  /// to a machine learning model (either the baseline model or a user-created 
  /// model if passed a model ID) to generate predictions and returns a 
  /// [jobs.PredictionJob] object that allows for status watching and result 
  /// fetching.
  /// 
  /// Throws a [ProjectException] if no data files correspond to that layer and 
  /// a [network.ApiNetworkException] if either the job fails to run or the 
  /// project cannot be uploaded after modification.
  Future<jobs.PredictionJob> runPredictionJob(
    String  name,
    String  description,
    String  layerId,
    String? modelId
  ) async 
  {
    // validate args
    final layerIndex = layers.indexWhere((layer) => layer.id == layerId);
    assert(layerIndex >= 0, "Layer with ID '$layerId' not found.");

    final modelIndex = modelId == null
      ? null
      : models.indexWhere((job) => job.id == modelId);
    assert(
      modelIndex == null || modelIndex >= 0,
      "Model with ID '$modelId' not found."
    );

    // assert(
    //   !dataAssignments[layerId]!.values.every((id) => id == null),
    //   "Project has no data assignments on layer with ID '$layerId'."
    // );

    // run update
    final networkService = await NetworkService.getInstance();
    final jobs.PredictionJob predictionJob;

    try {
      predictionJob = await networkService.runPredictionJob(
        id,
        name,
        description,
        layerId,
        modelId
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Prediction job failed to run with the following error:\n$error", 
        error.statusCode
      );
    }

    // update local copy
    predictions.add(predictionJob);
    lastUpdated = predictionJob.createdAt;
    return predictionJob;
  }

  Future<jobs.JobStatus> watchPredictionJobStatus(String jobId) async 
  {
    // validate args
    final jobIndex = predictions.indexWhere(
      (prediction) => prediction.id == jobId);
    assert(jobIndex >= 0, "Job with ID '$jobId' not found.");

    try {
      predictions[jobIndex].watchStatus(id, predictions[jobIndex].setStatus);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Job status failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    return predictions[jobIndex].status;
  }

  /// Runs a training job using a given file as training data for the new model 
  /// and returns a [jobs.TrainingJob] object.
  /// 
  /// Throws a [network.ApiNetworkException] if the job fails to run or the 
  /// project cannot be uploaded after modification.
  Future<jobs.TrainingJob> runTrainingJob(
    String name,
    String description,
    String specId,
  ) async 
  {
   // validate args
    final specIndex = trainingData.indexWhere((spec) => spec.id == specId);
    assert(specIndex >= 0, "Training data spec with ID '$specId' not found.");

    // run update
    final networkService = await NetworkService.getInstance();
    final jobs.TrainingJob trainingJob;

    try {
      trainingJob = await networkService.runTrainingJob(
        id,
        name,
        description,
        specId
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Prediction job failed to run with the following error:\n$error", 
        error.statusCode
      );
    }

    // update local copy
    models.add(trainingJob);
    lastUpdated = trainingJob.createdAt;
    return trainingJob;
  }

  /// Changes the name of a prediction job.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new job name matches
  /// a pre-existing job.
  Future<void> setPredictionJobMetadata(
    String id,
    {
      String? name,
      String? description
    }
  ) async
  {
    // validate args
    assert(name != null || description != null, "No updates specified.");

    final jobIndex = predictions.indexWhere((job) => job.id == id);
    assert(jobIndex >= 0, "Job with ID '$id' not found.");
    
    // run update
    final networkService = await NetworkService.getInstance();

    final DateTime timestamp;
    try {
      timestamp = await networkService.setPredictionJobMetadata(
        this.id,
        id,
        name: name,
        description: description
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    if (name != null) predictions[jobIndex].name = name;
    if (description != null) predictions[jobIndex].description = description;

    predictions[jobIndex].lastUpdated = timestamp;
    lastUpdated = timestamp;
  }


  /// Changes the name of a prediction job.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification and a [ProjectException] if new job name matches
  /// a pre-existing job.
  Future<void> setTrainingJobMetadata(
    String id,
    {
      String? name,
      String? description
    }
  ) async
  {
    // validate args
    assert(name != null || description != null, "No updates specified.");

    final jobIndex = models.indexWhere((job) => job.id == id);
    assert(jobIndex >= 0, "Job with ID '$id' not found.");
    
    // run update
    final networkService = await NetworkService.getInstance();

    final DateTime timestamp;
    try {
      timestamp = await networkService.setTrainingJobMetadata(
        this.id,
        id,
        name: name,
        description: description
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Project failed to update with the following error:\n$error", 
        error.statusCode
      );
    }

    if (name != null) models[jobIndex].name = name;
    if (description != null) models[jobIndex].description = description;

    models[jobIndex].lastUpdated = timestamp;
    lastUpdated = timestamp;
  }


  /// Deletes a prediction job from the project and deletes the corresponding 
  /// data file if it exists.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification or the prediction job cannot be successfully deleted.
  Future<void> deletePredictionJob(String id) async
  {
    final jobIndex = predictions.indexWhere((job) => job.id == id);
    assert(jobIndex >= 0, "Prediction job with ID '$id' not found.");
    assert(
      predictions[jobIndex].status == .complete
      || predictions[jobIndex].status == .failed
    );

    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.deletePredictionJob(this.id, id);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Network service failed to check if predictions file was created due"
        " to the following error: $error",
        error.statusCode
      );
    }

    predictions.removeAt(jobIndex);
  }

  /// Deletes a training job from the project and deletes the corresponding 
  /// data file if it exists.
  /// 
  /// Throws a [network.ApiNetworkException] if the project cannot be uploaded 
  /// after modification or the training job cannot be successfully deleted.
  Future<void> deleteTrainingJob(String id) async
  {
    final jobIndex = models.indexWhere((job) => job.id == id);
    assert(jobIndex >= 0, "Training job with ID '$id' not found.");
    assert(
      models[jobIndex].status == .complete
      || models[jobIndex].status == .failed
    );

    final networkService = await NetworkService.getInstance();

    try {
      lastUpdated = await networkService.deleteTrainingJob(this.id, id);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Network service failed to check if models file was created due"
        " to the following error: $error",
        error.statusCode
      );
    }

    models.removeAt(jobIndex);
  }

  /// Uploads an image corresponding to a layer to the appropriate location in
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the image fails to upload.
  Future<void> uploadLayerImage(
    String id,
    String imageContents,
    String filename,
  ) async
  {
    final layerIndex = layers.indexWhere((layer) => layer.id == id);
    assert(layerIndex >= 0, "Layer with ID '$id' not found.");

    final networkService = await NetworkService.getInstance();
    final DateTime timestamp;

    try {
      layers[layerIndex].image = await networkService.uploadLayerImage(
        this.id,
        id,
        imageContents,
        filename
      );

      timestamp = layers[layerIndex].image!.uploadedAt;
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer image failed to upload with the following error:\n$error", 
        error.statusCode
      );
    }

    layers[layerIndex].lastUpdated = timestamp;
    lastUpdated = timestamp;
  }

  /// Fetches an image corresponding to a layer from the appropriate location in
  /// the database.
  /// 
  /// Throws a [network.ApiNetworkException] if the image cannot be retrieved.
  Future<String> getLayerImage(String id) async
  {
    assert(
      layers.indexWhere((layer) => layer.id == id) >= 0,
      "Layer with ID '$id' not found."
    );

    final networkService = await NetworkService.getInstance();

    try {
      return await networkService.fetchLayerImage(this.id, id);
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
  Future<void> removeLayerImage(String id) async
  {
    final layerIndex = layers.indexWhere((layer) => layer.id == id);
    assert(layerIndex >= 0, "Layer with ID '$id' not found.");

    final networkService = await NetworkService.getInstance();
    final DateTime timestamp;

    try {
      timestamp = await networkService.deleteLayerImage(this.id, id);
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Layer image could not be deleted due to the following error:\n$error", 
        error.statusCode
      );
    }

    layers[layerIndex].image = null;
    layers[layerIndex].lastUpdated = timestamp;
    lastUpdated = timestamp;
  }
}

/* ================================ Utility ================================ */

/// Checks if two units are overlapping and returns true if so, false if not.
bool isOverlapping(List<latlong.LatLng> corners1, List<latlong.LatLng> corners2)
{
  assert(corners1.length == 4, "corners1 doesn't have four points.");
  assert(corners2.length == 4, "corners2 doesn't have four points.");

  // TODO: fix this to use corner points

  // Determine the top latitude, bottom latitude, left longitude, and right 
  // longitude for each unit - top and left are given, bottom and right have to
  // be calculated.
  // double top1 = unit1.topLeftCoords.latitude;
  // double left1 = unit1.topLeftCoords.longitude;
  // double bottom1 = map_math.FlutterMapMath.destinationPoint(
  //   unit1.topLeftCoords.latitude, 
  //   unit1.topLeftCoords.longitude, 
  //   unit1.height, 
  //   180).latitude;
  // double right1 = map_math.FlutterMapMath.destinationPoint(
  //   unit1.topLeftCoords.latitude, 
  //   unit1.topLeftCoords.longitude, 
  //   unit1.width, 
  //   90).longitude;

  // double bottom2 = map_math.FlutterMapMath.destinationPoint(
  //   unit2.topLeftCoords.latitude, 
  //   unit2.topLeftCoords.longitude, 
  //   unit2.height, 
  //   180).latitude;
  // double right2 = map_math.FlutterMapMath.destinationPoint(
  //   unit2.topLeftCoords.latitude, 
  //   unit2.topLeftCoords.longitude, 
  //   unit2.width, 
  //   90).longitude;
  // double top2 = unit2.topLeftCoords.latitude;
  // double left2 = unit2.topLeftCoords.longitude;
  
  // // Check if one of the top corners of unit 2 is inside unit 1.
  // if (top2 > bottom1 && top2 <= top1) {
  //   // Checking for the top left corner
  //   if (left2 < right1 && left2 >= left1) {
  //     return true;
  //   }
  //   /// Checking for the top right corner.
  //   else if (right2 > left1 && right2 <= right1) {
  //     return true;
  //   }
  // }
  // // Check if one of the bottom corners of unit 2 is inside unit 1.
  // else if (top1 > bottom2 && bottom2 <= bottom1) {
  //   // Checking for the bottom left corner.
  //   if (left2 < right1 && left2 >= left1) {
  //     return true;
  //   }
  //   // Checking for the bottom right corner.
  //   else if (right2 > left1 && right2 <= right1) {
  //     return true;
  //   }
  // }

  // // If none of the corners of unit 2 is inside unit 1, the only other way
  // // they can be overlapping is if unit 1 is entirely inside unit 2 - check
  // // accordingly.
  // else if (bottom2 <= top1 && top1 <= top2) {
  //   if (bottom2 <= bottom1 && bottom1 <= top2) {
  //     if (left2 <= left1 && left1 <= right2) {
  //       if (left2 <= right1 && right1 <= right2) {
  //         return true;
  //       }
  //     }
  //   }
  // }

  // If all checks fail, they are not overlapping; return false.
  return false;
}

/// Checks if a single lat/long point falls within a given set of corners.
bool isWithinUnit(
  List<latlong.LatLng> corners,
  double latitude,
  double longitude
)
{
  assert(corners.length == 4, "corners doesn't have four elements.");

  // TODO: fix this to use corner poitns

  // double top = unit.topLeftCoords.latitude;
  // double left = unit.topLeftCoords.longitude;
  // double bottom = map_math.FlutterMapMath.destinationPoint(
  //   unit.topLeftCoords.latitude, 
  //   unit.topLeftCoords.longitude, 
  //   unit.height, 
  //   180).latitude;
  // double right = map_math.FlutterMapMath.destinationPoint(
  //   unit.topLeftCoords.latitude, 
  //   unit.topLeftCoords.longitude, 
  //   unit.width, 
  //   90).longitude;

  // if (top >= latitude && latitude >= bottom  
  //   && right >= longitude && longitude >= left) {
  //     return true;
  // }

  return false;
}

/// Checks if all the data within the inputted [pxrfDataSpec] falls within the 
/// bounds of the inputted [corners].
/// 
/// [corners] must have four elements.
/// 
/// Returns true if all assigned data falls within appropriate boundaries,
/// false if not.
bool checkAssignment(PxrfDataSpec pxrfDataSpec, List<latlong.LatLng> corners) 
{
  assert(corners.length == 4, "corners doesn't have four elements.");

  // TODO: compare the expected number of points to the number of points in the
  //       data spec.

  return false;
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