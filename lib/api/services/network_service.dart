import 'dart:async';
import 'dart:convert' as convert;

import '../common/common.dart' as common;
import './api_types.dart' as api_types;

import 'package:latlong2/latlong.dart' as latlong;
import 'package:dzod/dzod.dart' as dzod;
import 'package:convex_flutter/convex_flutter.dart' as convex;
import 'package:http/http.dart' as http;

// TODO: add extra utility functions for converting between API types and 
// frontend types (i.e. ApiLayer => Layer).

/// Object given by [dzod] to access types.
final _z = dzod.z;

T parseNetworkResponse<T>(String response, dzod.Schema<T> schema)
{
  final dynamic jsonResponse = convert.jsonDecode(response);
  final validationResult = schema.validate(jsonResponse);
  final data = validationResult.data;
  
  if (validationResult.isFailure || data == null) {
    throw common.ApiNetworkException(
      "Failed to parse network response. Error message:\n"
        "${validationResult.errors!.formattedErrors}",
      null,
    );
  }
  
  return data;
}

Map<String, double> convertCoordRecordToMap(common.Coordinate coord)
  => {
    'latitude':  coord.latitude,
    'longitude': coord.longitude,
  };

latlong.LatLng convertCoordRecordToObj(common.Coordinate coord)
  => latlong.LatLng(coord.latitude, coord.longitude);

Map<String, dynamic> removeNullEntries(Map<String, dynamic> map)
{
  map.removeWhere((_, value) => value == null);
  return map;
}

common.Project convertApiProject(api_types.ApiProject apiProject)
{
  return common.Project(
    id:                   apiProject.id,
    name:                 apiProject.name,
    description:          apiProject.description,
    utmZone:              apiProject.utmZone,
    isSouthernHemisphere: apiProject.isSouthernHemisphere,
    corners:              apiProject.corners.map((corner) => latlong.LatLng(
                            corner.latitude,
                            corner.longitude,
                          )).toList(),
    dataAssignments:      apiProject.dataAssignments,
    createdAt:            DateTime.fromMillisecondsSinceEpoch(
                            apiProject.createdAt
                          ),
    lastUpdated:          DateTime.fromMillisecondsSinceEpoch(
                            apiProject.lastUpdated
                          ),

    layers: apiProject.layers.map((layer) => common.Layer(
      id:            layer.id,
      name:          layer.name,
      description:   layer.description,
      corners:       layer.corners.map(convertCoordRecordToObj).toList(),
      image:         layer.image,
      createdAt:     DateTime.fromMillisecondsSinceEpoch(layer.createdAt),
      lastUpdated:   DateTime.fromMillisecondsSinceEpoch(layer.lastUpdated),
    )).toList(),

    units: apiProject.units.map((unit) => common.Unit(
      id:            unit.id,
      name:          unit.name,
      description:   unit.description,
      corners:       unit.corners.map(convertCoordRecordToObj).toList(),
      pointInterval: unit.pointInterval,
      createdAt:     DateTime.fromMillisecondsSinceEpoch(unit.createdAt),
      lastUpdated:   DateTime.fromMillisecondsSinceEpoch(unit.lastUpdated),
    )).toList(),

    pxrfData: apiProject.pxrfData.map((spec) => common.PxrfDataSpec(
      id:                 spec.id,
      fileName:           spec.fileName,
      numPoints:          spec.numPoints,
      size:               spec.size,
      createdAt:          DateTime.fromMillisecondsSinceEpoch(spec.createdAt),
      lastUpdated:        DateTime.fromMillisecondsSinceEpoch(spec.lastUpdated),
    )).toList(),

    trainingData: apiProject.trainingData.map(
      (spec) => common.TrainingDataSpec(
        id:               spec.id,
        fileName:         spec.fileName,
        numPoints:        spec.numPoints,
        size:             spec.size,
        createdAt:        DateTime.fromMillisecondsSinceEpoch(spec.createdAt),
        lastUpdated:      DateTime.fromMillisecondsSinceEpoch(spec.lastUpdated),
      )
    ).toList(),

    predictions: apiProject.predictions.map((job) => common.PredictionJob(
      id:                 job.id,
      name:               job.name,
      description:        job.description,
      layerId:            job.layerId,
      modelId:            job.modelId,
      status:             job.status,
      createdAt:          DateTime.fromMillisecondsSinceEpoch(job.createdAt),
      lastUpdated:        DateTime.fromMillisecondsSinceEpoch(job.lastUpdated),
    )).toList(),

    models: apiProject.models.map((job) => common.TrainingJob(
      id:                 job.id,
      name:               job.name,
      description:        job.description,
      status:             job.status,
      trainingDataSpecId: job.trainingDataSpecId,
      createdAt:          DateTime.fromMillisecondsSinceEpoch(job.createdAt),
      lastUpdated:        DateTime.fromMillisecondsSinceEpoch(job.lastUpdated),
    )).toList(),
  );
}
const _cloudUrl = "https://standing-eel-607.convex.cloud";
const _httpActionsUrl = "https://standing-eel-607.convex.site";

class NetworkService {
  static NetworkService? instance;

  /// Privately-named constructor to prevent other modules from creating a 
  /// new service.
  NetworkService._();

  /// Helper function that returns the client used for all network requests.
  convex.ConvexClient _getClient()
    => convex.ConvexClient.instance;
  
  /// Gets the [NetworkService] instance. When called for the first time,
  /// initializes the backend client.
  static Future<NetworkService> getInstance() async {
    if (instance != null) return instance!;

    instance = NetworkService._();

    await convex.ConvexClient.initialize(
      convex.ConvexConfig(
        deploymentUrl: _cloudUrl,
        operationTimeout: Duration(seconds: 15),
        healthCheckQuery: "health:ping",
      ),
    );

    return instance!;
  }

  Future<bool> login(String username, String password)
    => throw UnimplementedError();

  Future<void> logout()
    => throw UnimplementedError();

  Future<List<common.ConnectionSpec>> getUserConnectionEntries() async
  {
    final client = _getClient();
    final response = await client.query(
      "connections:getUserConnectionSpecs",
      {},
    );
    
    final apiConnectionSpecs = parseNetworkResponse(
      response,
      _z.array(api_types.zApiConnectionSpec),
    );

    return apiConnectionSpecs
      .map((spec) => common.ConnectionSpec(
        id:        spec.id,
        ipAddress: spec.ipAddress,
        port:      spec.port,
        createdAt: DateTime.fromMillisecondsSinceEpoch(spec.createdAt),
        status:    .disconnected,
      ))
      .toList();
  }

  /// Currently unused
  Future<api_types.ApiConnectionSpec> getConnectionSpecById(String id) async
    => throw UnimplementedError();

  Future<common.ConnectionSpec> createConnectionSpec(
    String ipAddress,
    int port,
  ) async
  {
    // TODO: validate IP adderess and port params?

    final client = _getClient();
    final createResponse = await client.mutation(
      name: "connections:createConnectionSpec",
      args: { 'ipAddress': ipAddress, 'port': port },
    );
    
    final createdSpec = parseNetworkResponse(
      createResponse,
      api_types.zApiConnectionSpec,
    );

    return common.ConnectionSpec(
        id:        createdSpec.id,
        ipAddress: createdSpec.ipAddress,
        port:      createdSpec.port,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdSpec.createdAt),
        status:    .disconnected,
    );
  }

  Future<void> deleteConnectionSpec(String id) async
  {
    final client = _getClient();
    await client.mutation(
      name: "connections:deleteConnectionSpec",
      args: { 'id': id },
    );
  }

  Future<List<common.ProjectSpec>> getUserProjectSpecs() async
  {
    final client = _getClient();
    final response = await client.query(
      "projects:getUserProjectSpecs",
      {},
    );

    final apiProjectSpecs = parseNetworkResponse(
      response,
      _z.array(api_types.zApiProjectSpec)
    );

    return apiProjectSpecs.map((apiSpec) => common.ProjectSpec(
      id:                   apiSpec.id,
      name:                 apiSpec.name,
      description:          apiSpec.description,
      utmZone:              apiSpec.utmZone,
      isSouthernHemisphere: apiSpec.isSouthernHemisphere,
      corners:              apiSpec
                              .corners
                              .map(convertCoordRecordToObj)
                              .toList(),
      numLayers:            apiSpec.numLayers,
      numUnits:             apiSpec.numUnits,
      numPxrfData:          apiSpec.numPxrfData,
      numTrainingData:      apiSpec.numTrainingData,
      numPredictions:       apiSpec.numPredictions,
      numModels:            apiSpec.numModels,
      createdAt:            DateTime.fromMillisecondsSinceEpoch(
                              apiSpec.createdAt
                            ),
      lastUpdated:          DateTime.fromMillisecondsSinceEpoch(
                              apiSpec.lastUpdated
                            ),
    )).toList();
  }

  Future<common.Project> getProjectById(String id) async
  {
    final client = _getClient();
    final response = await client.query(
      "projects:getProjectById",
      { 'id': id },
    );
    
    final apiProject = parseNetworkResponse(
      response,
      api_types.zApiProject,
    );

    return convertApiProject(apiProject);
  }

  Future<common.Project> createProject(
    String                  name,
    String                  description,
    int                     utmZone,
    bool                    isSouthernHemisphere,
    List<common.Coordinate> corners,
  ) async
  {
    final client = _getClient();
    final response = await client.mutation(
      name: "projects:createProject",
      args: {
        'name':                 name,
        'description':          description,
        'utmZone':              utmZone,
        'isSouthernHemisphere': isSouthernHemisphere,
        'corners':              corners.map(convertCoordRecordToMap).toList(),
      },
    );
    
    final apiProject = parseNetworkResponse(response, api_types.zApiProject);
    return convertApiProject(apiProject);
  }

  Future<void> deleteProject(String id) async
  {
    final client = _getClient();
    await client.mutation(
      name: "projects:deleteProject",
      args: { 'id': id },
    );
  }

  Future<DateTime> setProjectMetadata(
    String id,
    {
      String? name,
      String? description,
      int?    utmZone,
      bool?   isSouthernHemisphere,
    }
  ) async
  {
    // TODO: merge this method and project site updater into one thing
    assert(
      name != null
        || description != null
        || utmZone != null
        || isSouthernHemisphere != null,
      "No updates specified."
    );

    final client = _getClient();
    final response = await client.mutation(
      name: "projects:setProjectMetadata",
      args: removeNullEntries({
        'id':                   id,
        'name':                 name,
        'description':          description,
        'utmZone':              utmZone,
        'isSouthernHemisphere': isSouthernHemisphere,
      }),
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<({
    List<common.Unit>  createdUnits,
    List<common.Layer> createdLayers,
    DateTime           timestamp,
  })> configureProjectSite(
    String id,
    {
      List<common.Coordinate>? siteCorners,

      List<({
        String                  name,
        String                  description,
        double                  pointInterval,
        List<common.Coordinate> corners,
      })> newUnits = const [],

      Map<
        String,
        ({
          String?                  name,
          String?                  description,
          double?                  pointInterval,
          List<common.Coordinate>? corners,
        })
      > unitUpdates = const {},

      List<String> unitsToDelete = const [],

      List<({
        String                  name,
        String                  description,
        List<common.Coordinate> corners,
      })> newLayers = const [],

      Map<
        String,
        ({
          String?                  name,
          String?                  description,
          List<common.Coordinate>? corners,
        })
      > layerUpdates = const {},

      List<String> layersToDelete = const [],
    }
  ) async
  {
    // check params
    // TODO: assert no duplicate IDs

    assert(
      siteCorners != null
        || newUnits.isNotEmpty
        || unitUpdates.isNotEmpty
        || unitsToDelete.isNotEmpty
        || newLayers.isNotEmpty
        || layerUpdates.isNotEmpty
        || layersToDelete.isNotEmpty,
      "No updates specified."
    );

    // send request
    // TODO: remove empty arrays/maps from arguments
    final client = _getClient();
    final response = await client.action(
      name: "projects:configureProjectSite",
      args: removeNullEntries({
        'id':             id,
        'siteCorners':    siteCorners?.map((corner) => {
                            'latitude':  corner.latitude,
                            'longitude': corner.longitude,
                          }).toList(),
        'newUnits':       newUnits.map((unit) => {
                            'name':          unit.name,
                            'description':   unit.description,
                            'corners':       unit.corners
                                              .map(convertCoordRecordToMap)
                                              .toList(),
                            'pointInterval': unit.pointInterval,
                          }).toList(),
        'unitUpdates':    unitUpdates.map((unitId, updates) => MapEntry(
                            unitId, 
                            removeNullEntries({
                              'name':           updates.name,
                              'description':    updates.description,
                              'corners':        updates.corners
                                                  ?.map(convertCoordRecordToMap)
                                                  .toList(),
                              'pointInterval':  updates.pointInterval,
                            }),
                          )),
        'unitsToDelete':  unitsToDelete,
        'newLayers':      newLayers.map((layer) => {
                            'name':         layer.name,
                            'description':  layer.description,
                            'corners':      layer.corners
                                              .map(convertCoordRecordToMap)
                                              .toList(),
                          }).toList(),
        'layerUpdates':   layerUpdates.map((layerId, updates) => MapEntry(
                            layerId,
                            removeNullEntries({
                              'name':         updates.name,
                              'description':  updates.description,
                              'corners':      updates.corners
                                                ?.map(convertCoordRecordToMap)
                                                .toList(),
                            }),
                          )),
        'layersToDelete': layersToDelete,
      },
    ));

    // parse response
    final zExpectedConfigurationResult = _z
      .object({
        'createdUnits':  _z.array(api_types.zApiUnit),
        'createdLayers': _z.array(api_types.zApiLayer),
        'timestamp':     api_types.zTimestamp,
      })
      .transform((map) => (
        createdUnits: map['createdUnits'] as List<api_types.ApiUnit>,
        createdLayers: map['createdLayers'] as List<api_types.ApiLayer>,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      ));

    final configResult = parseNetworkResponse(
      response,
      zExpectedConfigurationResult
    );

    // return results
    return (
      createdUnits: configResult.createdUnits.map((unit) => common.Unit(
        id:            unit.id,
        name:          unit.name,
        description:   unit.description,
        corners:       unit.corners.map(convertCoordRecordToObj).toList(),
        pointInterval: unit.pointInterval,
        createdAt:     DateTime.fromMillisecondsSinceEpoch(unit.createdAt),
        lastUpdated:   DateTime.fromMillisecondsSinceEpoch(unit.lastUpdated),
      )).toList(),
      createdLayers: configResult.createdLayers.map((layer) => common.Layer(
        id:           layer.id,
        name:         layer.name,
        description:  layer.description,
        corners:      layer.corners.map(convertCoordRecordToObj).toList(),
        image:        layer.image,
        createdAt:    DateTime.fromMillisecondsSinceEpoch(layer.createdAt),
        lastUpdated:  DateTime.fromMillisecondsSinceEpoch(layer.lastUpdated),
      )).toList(),
      timestamp:     configResult.timestamp,
    );
  }

  Future<String> fetchPxrfData(String projectId, String specId) async
  {
    final client = _getClient();
    final downloadUrl = await client.query(
      "projects:getProjectPxrfDataUrl",
      { 'projectId': projectId, 'specId': specId }
    );

    final http.Response response;
    try {
      response = await http.get(Uri.parse(downloadUrl));
    } catch (e) {
      throw common.ApiNetworkException('pXRF data download failed: $e', null);
    }

    if (response.statusCode != 200) {
      throw common.ApiNetworkException(
        'pXRF data download failed.',
        response.statusCode
      );
    }

    return response.body;
  }

  Future<({ String name, int size, DateTime uploadedAt })> uploadLayerImage(
    String projectId,
    String layerId,
    String imageContents,
    String filename,
  ) async
  {
    // setup request
    final uri = Uri.parse("$_httpActionsUrl/uploadLayerImage");

    var request = http.MultipartRequest('POST', uri);

    request.fields['projectId'] = projectId;
    request.fields['layerId'] = layerId;
    request.files.add(
      .fromString(
        'file',
        imageContents,
        filename: filename,
      )
    );

    // send request
    final http.StreamedResponse streamedResponse;
    final http.Response response;

    try {
      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw common.ApiNetworkException(
        "Failed to send network request:\n$e",
        null
      );
    }

    // validate response and return
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw common.ApiNetworkException(
        "Failed to add layer image. Response body:\n${response.body}",
        response.statusCode,
      );
    }

    final apiImage = parseNetworkResponse(
      response.body,
      api_types.zApiImage,
    );

    return (
      name:       apiImage.name,
      size:       apiImage.size,
      uploadedAt: apiImage.uploadedAt,
    );
  }

  Future<String> fetchLayerImage(
    String projectId,
    String layerId,
  ) async
  {
   final client = _getClient();
    final downloadUrl = await client.query(
      "projects:getProjectLayerImageDownloadUrl",
      { 'projectId': projectId, 'layerId': layerId }
    );

    final http.Response response;
    try {
      response = await http.get(Uri.parse(downloadUrl));
    } catch (e) {
      throw common.ApiNetworkException('Image download failed: $e', null);
    }

    if (response.statusCode != 200) {
      throw common.ApiNetworkException(
        'Image download failed.',
        response.statusCode
      );
    }

    return response.body;
  }

  Future<DateTime> deleteLayerImage(
    String projectId,
    String layerId,
  ) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:deleteProjectLayerImage",
      args: { "projectId": projectId, "layerId": layerId },
    );

    final timestamp = parseNetworkResponse(
      response,
      api_types.zTimestamp,
    );

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<common.PxrfDataSpec> addPxrfData(
    String projectId,
    String fileContents,
    String filename,
    String description
  ) async
  {
    // setup request
    final uri = Uri.parse("$_httpActionsUrl/uploadPxrfData");

    var request = http.MultipartRequest('POST', uri);

    request.fields['projectId'] = projectId;
    request.fields['description'] = description;
    request.files.add(
      .fromString(
        'file',
        fileContents,
        filename: filename,
      )
    );

    // send request
    final http.StreamedResponse streamedResponse;
    final http.Response response;

    try {
      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw common.ApiNetworkException(
        "Failed to send network request:\n$e",
        null
      );
    }

    // validate response and return
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw common.ApiNetworkException(
        "Failed to add pXRF data. Response body:\n${response.body}",
        response.statusCode,
      );
    }

    final apiPxrfDataSpec = parseNetworkResponse(
      response.body,
      api_types.zApiPxrfDataSpec
    );

    return common.PxrfDataSpec(
      id:           apiPxrfDataSpec.id,
      fileName:     apiPxrfDataSpec.fileName,
      numPoints:    apiPxrfDataSpec.numPoints,
      size:         apiPxrfDataSpec.size,
      createdAt:    DateTime.fromMillisecondsSinceEpoch(
                      apiPxrfDataSpec.createdAt
                    ),
      lastUpdated:  DateTime.fromMillisecondsSinceEpoch(
                      apiPxrfDataSpec.lastUpdated
                    ),
    );
  }

  Future<DateTime> deletePxrfData(String projectId, String specId) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:deleteProjectPxrfData",
      args: { "projectId": projectId, "specId": specId },
    );

    final timestamp = parseNetworkResponse(
      response,
      api_types.zTimestamp,
    );

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<DateTime> assignProjectPxrfData(
    String projectId,
    String layerId,
    String unitId,
    String specId
  ) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:assignProjectPxrfData",
      args: {
        "projectId": projectId,
        "layerId":   layerId,
        "unitId":    unitId,
        "specId":    specId
      },
    );

    final timestamp = parseNetworkResponse(
      response,
      api_types.zTimestamp,
    );

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<DateTime> setPxrfDataSpecMetadata(
    String projectId,
    String specId,
    {
      String? fileName,
      String? description,
    }
  ) async
  {
    assert(fileName != null || description != null, "No updates specified.");

    final client = _getClient();

    final response = await client.mutation(
      name: "projects:setProjectPxrfDataMetadata",
      args: {
        'projectId': projectId,
        'specId': specId,
        'fileName': fileName,
        'description': description,
      },
    );

    final timestamp = parseNetworkResponse(
      response,
      api_types.zTimestamp,
    );

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<String> fetchTrainingData(String projectId, String specId) async
  {
    final client = _getClient();
    final downloadUrl = await client.query(
      "projects:getProjectTrainingDataUrl",
      { 'projectId': projectId, 'specId': specId }
    );

    final http.Response response;
    try {
      response = await http.get(Uri.parse(downloadUrl));
    } catch (e) {
      throw common.ApiNetworkException('Training data download failed: $e', null);
    }

    if (response.statusCode != 200) {
      throw common.ApiNetworkException(
        'Training data download failed.',
        response.statusCode
      );
    }

    return response.body;
  }

  Future<common.TrainingDataSpec> addTrainingData(
    String projectId,
    String fileContents,
    String filename,
    String description
  ) async
  {
    // setup request
    final uri = Uri.parse("$_httpActionsUrl/uploadTrainingData");

    var request = http.MultipartRequest('POST', uri);

    request.fields['projectId'] = projectId;
    request.fields['description'] = description;
    request.files.add(
      .fromString(
        'file',
        fileContents,
        filename: filename,
      )
    );

    // send request
    final http.StreamedResponse streamedResponse;
    final http.Response response;

    try {
      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw common.ApiNetworkException(
        "Failed to send network request:\n$e",
        null
      );
    }

    // validate response and return
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw common.ApiNetworkException(
        "Failed to add training data. Response body:\n${response.body}",
        response.statusCode,
      );
    }

    final apiTrainingDataSpec = parseNetworkResponse(
      response.body,
      api_types.zApiTrainingDataSpec
    );

    return common.TrainingDataSpec(
      id:           apiTrainingDataSpec.id,
      fileName:     apiTrainingDataSpec.fileName,
      numPoints:    apiTrainingDataSpec.numPoints,
      size:         apiTrainingDataSpec.size,
      createdAt:    DateTime.fromMillisecondsSinceEpoch(
                      apiTrainingDataSpec.createdAt
                    ),
      lastUpdated:  DateTime.fromMillisecondsSinceEpoch(
                      apiTrainingDataSpec.lastUpdated
                    ),
    );
  }

  Future<DateTime> deleteTrainingData(String projectId, String specId) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:deleteProjectTrainingData",
      args: { "projectId": projectId, "specId": specId },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<DateTime> setTrainingDataSpecMetadata(
    String projectId,
    String specId,
    {
      String? fileName,
      String? description,
    }
  ) async
  {
    assert(fileName != null || description != null, "No updates specified.");

    final client = _getClient();

    final response = await client.mutation(
      name: "projects:setProjectTrainingDataMetadata",
      args: {
        'projectId':   projectId,
        'specId':      specId,
        'fileName':    fileName,
        'description': description,
      },
    );

    final timestamp = parseNetworkResponse(
      response,
      api_types.zTimestamp,
    );

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<common.PredictionJob> runPredictionJob(
    String  projectId,
    String  name,
    String  description,
    String  layerId,
    String? modelId,
  ) async
  {
    final client = _getClient();

    final response = await client.action(
      name: "projects:runPredictionJob",
      args: {
        'projectId':   projectId,
        'name':        name,
        'description': description,
        'layerId':     layerId,
        'modelId':     modelId,
      }
    );

    final createdJob = parseNetworkResponse(
      response,
      api_types.zApiPredictionJob
    );

    return common.PredictionJob(
      id:               createdJob.id,
      name:             createdJob.name,
      description:      createdJob.description,
      layerId:          createdJob.layerId,
      modelId:          createdJob.modelId,
      dataAssignments:  createdJob.dataAssignments,
      status:           createdJob.status,
      createdAt:        DateTime.fromMillisecondsSinceEpoch(
                          createdJob.createdAt
                        ),
      lastUpdated:      DateTime.fromMillisecondsSinceEpoch(
                          createdJob.lastUpdated
                        ),
    );
  }

  Future<DateTime> setPredictionJobMetadata(
    String projectId,
    String jobId,
    {
      String? name,
      String? description,
    }
  ) async
  {
    assert(name != null || description != null, "No updates specified.");

    final client = _getClient();

    final response = await client.mutation(
      name: "projects:setPredictionJobMetadata",
      args: {
        'projectId':   projectId,
        'jobId':       jobId,
        'name':        name,
        'description': description,
      },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<DateTime> deletePredictionJob(String projectId, String jobId) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:deletePredictionJob",
      args: {
        'projectId': projectId,
        'jobId':     jobId,
      },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void Function()> watchPredictionJobStatus(
    String projectId,
    String jobId,
    Function(common.JobStatus) callback
  ) async
  {
    final client = _getClient();
    final handler = await client.subscribe(
      name: "projects:getPredictionJobStatus",
      args: {
        'projectId': projectId,
        'jobId':     jobId,
      },
      onUpdate: (response) {
        final status = parseNetworkResponse(response, api_types.zJobStatus);
        callback(status);
      },
      onError: (message, value) {
        throw common.ApiNetworkException(
          "Error occurred while watching job status (last known value "
            "${value != null ? "'$value'" : "unknown"}). Message:\n$message",
          null
        );
      },
    );

    return handler.cancel;
  }

  Future<String> fetchPredictionJobResults(String projectId, String jobId) async
  {
    final client = _getClient();
    final downloadUrl = await client.query(
      "projects:getPredictionJobResultsUrl",
      { 'projectId': projectId, 'jobId': jobId }
    );

    final http.Response response;
    try {
      response = await http.get(Uri.parse(downloadUrl));
    } catch (e) {
      throw common.ApiNetworkException(
        'Prediction job output download failed: $e',
        null
      );
    }

    if (response.statusCode != 200) {
      throw common.ApiNetworkException(
        'Prediction job output download failed.',
        response.statusCode
      );
    }

    return response.body;
  }

  Future<common.TrainingJob> runTrainingJob(
    String projectId,
    String name,
    String description,
    String trainingDataSpecId,
  ) async
  {
    final client = _getClient();

    final response = await client.action(
      name: "projects:runTrainingJob",
      args: {
        'projectId':          projectId,
        'name':               name,
        'description':        description,
        'trainingDataSpecId': trainingDataSpecId,
      }
    );

    final createdJob = parseNetworkResponse(
      response,
      api_types.zApiTrainingJob
    );

    return common.TrainingJob(
      id:                 createdJob.id,
      name:               createdJob.name,
      description:        createdJob.description,
      trainingDataSpecId: createdJob.trainingDataSpecId,
      status:             createdJob.status,
      createdAt:          DateTime.fromMillisecondsSinceEpoch(
                            createdJob.createdAt
                          ),
      lastUpdated:        DateTime.fromMillisecondsSinceEpoch(
                            createdJob.lastUpdated
                          ),
    );
  }

  Future<DateTime> setTrainingJobMetadata(
    String projectId,
    String jobId,
    {
      String? name,
      String? description,
    }
  ) async
  {
    assert(name != null || description != null, "No updates specified.");

    final client = _getClient();

    final response = await client.mutation(
      name: "projects:setTrainingJobMetadata",
      args: {
        'projectId':   projectId,
        'jobId':       jobId,
        'name':        name,
        'description': description,
      },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<DateTime> deleteTrainingJob(String projectId, String jobId) async
  {
    final client = _getClient();

    final response = await client.mutation(
      name: "projects:deleteTrainingJob",
      args: {
        'projectId':   projectId,
        'jobId':       jobId,
      },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void Function()> watchTrainingJobStatus(
    String projectId,
    String jobId,
    Function(common.JobStatus) callback
  ) async
  {
    final client = _getClient();
    final handler = await client.subscribe(
      name: "projects:getTrainingJobStatus",
      args: {
        'projectId': projectId,
        'jobId':     jobId,
      },
      onUpdate: (response) {
        final status = parseNetworkResponse(response, api_types.zJobStatus);
        callback(status);
      },
      onError: (message, value) {
        throw common.ApiNetworkException(
          "Error occurred while watching job status (last known value "
            "${value != null ? "'$value'" : "unknown"}). Message:\n$message",
          null
        );
      },
    );

    return handler.cancel;
  }
}