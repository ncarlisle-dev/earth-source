import 'dart:convert' as convert;

import '../common/common.dart' as common;
import './api_types.dart' as api_types;

import 'package:latlong2/latlong.dart' as latlong;
import 'package:dzod/dzod.dart' as dzod;
import 'package:convex_flutter/convex_flutter.dart' as convex;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

typedef Coordinate = ({ double latitude, double longitude });

/// Object given by [dzod] to access types.
final _z = dzod.z;

T parseNetworkResponse<T>(String response, dzod.Schema<T> schema)
{
  dynamic jsonResponse = convert.jsonDecode(response);
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

common.Project convertApiProject(api_types.ApiProject apiProject)
{
  return common.Project(
    id:              apiProject.id,
    name:            apiProject.name,
    description:     apiProject.description,
    topLeftCoords:   apiProject.topLeftCoords,
    width:           apiProject.width,
    height:          apiProject.height,
    dataAssignments: apiProject.dataAssignments,
    createdAt:       DateTime.fromMicrosecondsSinceEpoch(apiProject.createdAt),
    lastUpdated:     DateTime.fromMicrosecondsSinceEpoch(
                       apiProject.lastUpdated
                     ),

    layers: apiProject.layers.map((layer) => common.Layer(
      id:                 layer.id,
      name:               layer.name,
      description:        layer.description,
      cornerCoordinates:  [],
      createdAt:          DateTime.fromMicrosecondsSinceEpoch(layer.createdAt),
      lastUpdated:        DateTime.fromMicrosecondsSinceEpoch(
                            layer.lastUpdated
                          ),
    )).toList(),

    units: apiProject.units.map((unit) => common.Unit(
      id:                 unit.id,
      name:               unit.name,
      description:        unit.description,
      topLeftCoords:      latlong.LatLng(
                            unit.topLeftCoords.latitude,
                            unit.topLeftCoords.longitude
                          ),
      width:              unit.width, 
      height:             unit.height,
      pointInterval:      unit.pointInterval,
      createdAt:          DateTime.fromMicrosecondsSinceEpoch(unit.createdAt),
      lastUpdated:        DateTime.fromMicrosecondsSinceEpoch(unit.lastUpdated),
    )).toList(),

    pxrfData: apiProject.pxrfData.map((spec) => common.PxrfDataSpec(
      id:                 spec.id,
      fileName:           spec.fileName,
      numPoints:          spec.numPoints,
      size:               spec.size,
      createdAt:          DateTime.fromMicrosecondsSinceEpoch(spec.createdAt),
      lastUpdated:        DateTime.fromMicrosecondsSinceEpoch(spec.lastUpdated),
    )).toList(),

    trainingData: apiProject.trainingData.map(
      (spec) => common.TrainingDataSpec(
        id:               spec.id,
        fileName:         spec.fileName,
        numPoints:        spec.numPoints,
        size:             spec.size,
        createdAt:        DateTime.fromMicrosecondsSinceEpoch(spec.createdAt),
        lastUpdated:      DateTime.fromMicrosecondsSinceEpoch(spec.lastUpdated),
      )
    ).toList(),

    predictions: apiProject.predictions.map((job) => common.PredictionJob(
      id:                 job.id,
      name:               job.name,
      description:        job.description,
      layerId:            job.layerId,
      modelId:            job.modelId,
      status:             job.status,
      createdAt:          DateTime.fromMicrosecondsSinceEpoch(job.createdAt),
      lastUpdated:        DateTime.fromMicrosecondsSinceEpoch(job.lastUpdated),
    )).toList(),

    models: apiProject.models.map((job) => common.TrainingJob(
      id:                 job.id,
      name:               job.name,
      description:        job.description,
      status:             job.status,
      createdAt:          DateTime.fromMicrosecondsSinceEpoch(job.createdAt),
      lastUpdated:        DateTime.fromMicrosecondsSinceEpoch(job.lastUpdated),
    )).toList(),
  );
}

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
        deploymentUrl: "https://standing-eel-607.convex.cloud",
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
        createdAt: DateTime.fromMicrosecondsSinceEpoch(spec.createdAt),
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
        createdAt: DateTime.fromMicrosecondsSinceEpoch(createdSpec.createdAt),
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

  Future<List<common.Project>> getUserProjects() async
  {
    // TODO: this needs to return project specs, not projects
    final client = _getClient();
    final response = await client.query(
      "projects:getUserProjects",
      {},
    );
    
    final apiProjects = parseNetworkResponse(
      response,
      _z.array(api_types.zApiProject),
    );

    return apiProjects.map(convertApiProject).toList();
  }

  Future<common.Project> getProject(String id) async
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
    String name,
    String description,
    Coordinate topLeftCoords,
    double width,
    double height,
  ) async
  {
    final client = _getClient();
    final response = await client.mutation(
      name: "projects:createProject",
      args: {
        'name':          name,
        'description':   description,
        'topLeftCoords': topLeftCoords,
        'width':         width,
        'height':        height,
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
      String? description
    }
  ) async
  {
    assert(name != null || description != null, "No updates found.");

    final client = _getClient();
    final response = await client.mutation(
      name: "projects:setProjectMetadata",
      args: {
        'id':          id,
        'name':        name,
        'description': description,
      },
    );

    final timestamp = parseNetworkResponse(response, api_types.zTimestamp);

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<({
    List<String> createdUnitIds,
    List<String> createdLayerIds,
    DateTime timestamp,
  })> configureProjectSite(
    String id,
    {
      Coordinate? siteTopLeftCoords,

      double? siteWidth,
      double? siteHeight,

      List<({
        String name,
        String description,
        Coordinate topLeftCoords,
        double width,
        double height,
        double pointInterval
      })> newUnits = const [],

      Map<
        String,
        ({
          String? name,
          String? description,
          Coordinate? topLeftCoords,
          double? width,
          double? height,
          double? pointInterval
        })
      > unitUpdates = const {},

      List<String> unitsToDelete = const [],

      List<({
        String name,
        String description,
      })> newLayers = const [],

      Map<
        String,
        ({
          String? name,
          String? description,
        })
      > layerUpdates = const {},

      List<String> layersToDelete = const [],
    }
  ) async
  {
    assert(
      siteTopLeftCoords != null
        || siteWidth != null
        || siteHeight != null
        || newUnits.isNotEmpty
        || unitUpdates.isNotEmpty
        || unitsToDelete.isNotEmpty
        || newLayers.isNotEmpty
        || layerUpdates.isNotEmpty
        || layersToDelete.isNotEmpty,
      "No updates specified."
    );

    final client = _getClient();
    final response = await client.mutation(
      name: "projects:configureProjectSite",
      args: {
        'id':                 id,
        'siteTopLeftCoords':  siteTopLeftCoords == null
                                ? null
                                : { 
                                  'latitude':  siteTopLeftCoords.latitude,
                                  'longitude': siteTopLeftCoords.longitude,
                                },
        'siteWidth':          siteWidth,
        'siteHeight':         siteHeight,
        'newUnits':           newUnits.map((unit) => {
                                'name':          unit.name,
                                'description':   unit.description,
                                'topLeftCoords': unit.topLeftCoords,
                                'width':         unit.width,
                                'height':        unit.height,
                                'pointInterval': unit.pointInterval,
                              }).toList(),
        'unitUpdates':        unitUpdates.map((unitId, updates) => MapEntry(
                                unitId, 
                                {
                                  'name':          updates.name,
                                  'description':   updates.description,
                                  'topLeftCoords': updates.topLeftCoords,
                                  'width':         updates.width,
                                  'height':        updates.height,
                                  'pointInterval': updates.pointInterval,
                                }
                              )),
        'unitsToDelete':      unitsToDelete,
        'newLayers':          newLayers.map((layer) => {
                                'name':        layer.name,
                                'description': layer.description,
                              }).toList(),
        'layerUpdates':       layerUpdates.map((layerId, updates) => MapEntry(
                                layerId,
                                {
                                  'name':        updates.name,
                                  'description': updates.description,
                                }
                              )),
        'layersToDelete':     layersToDelete,
      },
    );

    final zExpectedConfigurationResult = _z
      .object({
        'createdUnitIds': _z.array(api_types.zId),
        'createdLayerIds': _z.array(api_types.zId),
        'timestamp': api_types.zTimestamp,
      })
      .transform((map) => (
        createdUnitIds: map['createdUnitIds'] as List<String>,
        createdLayerIds: map['createdLayerIds'] as List<String>,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['createdLayerIds']),
      ));

    return parseNetworkResponse(
      response,
      zExpectedConfigurationResult
    );
  }

  Future<String> fetchPxrfData(String specId) async
  {
    final client = _getClient();
    final downloadUrl = await client.query(
      "projects:getProjectPxrfDataUrl",
      { 'id': specId }
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

  Future<common.PxrfDataSpec> addPxrfData(
    String projectId,
    String fileContents,
    String filename,
    String description
  ) async
  {
    final uri = Uri.parse(
      "${_getClient().config.deploymentUrl}/uploadPxrfData"
    );

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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw common.ApiNetworkException(
        "Failed to upload pXRF data. Response body:\n${response.body}",
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

  Future<String> deletePxrfData() async
  {

  }

  Future<void> trainModel(String filepath, common.TrainingJob job)
    => throw UnimplementedError();
  
  Future<void> runModel(
    String? modelId, 
    common.PredictionJob job, 
    List<String> filepaths
  )
    => throw UnimplementedError();
}