import 'dart:convert' as convert;

import '../common/common.dart' as common;
import './api_types.dart' as api_types;

import 'package:dzod/dzod.dart' as dzod;
import 'package:convex_flutter/convex_flutter.dart' as convex;

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

  Future<List<common.ConnectionSpec>> getConnectionEntries() async
  {
    final client = _getClient();
    final response = await client.query(
      "connections:getUserConnectionSpecs",
      {}
    );
    
    final apiConnectionSpecs = parseNetworkResponse(
      response,
      _z.array(api_types.zApiConnectionSpec)
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
    int port
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
      api_types.zApiConnectionSpec
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
      name: "connections:createConnectionSpec",
      args: { 'id': id },
    );
  }

  Future<List<common.Project>> getUserProjects() async
  {
    
  }

  Future<common.Project> getProject(String id)
    => throw UnimplementedError();

  Future<void> uploadProject(common.Project project)
    => throw UnimplementedError();

  Future<void> deleteProject(String id)
    => throw UnimplementedError();

  Future<bool> fileExists(String filePath)
    => throw UnimplementedError();

  Future<String?> fetchFile(String filePath)
    => throw UnimplementedError();

  Future<void> writeFile(String filePath, String content)
    => throw UnimplementedError();

  Future<void> deleteFile(String filePath)
    => throw UnimplementedError();

  Future<bool> directoryExists(String filePath)
    => throw UnimplementedError();

  Future<void> createDirectory(String filePath)
    => throw UnimplementedError();

  Future<void> deleteDirectory(String filePath)
    => throw UnimplementedError();

  Future<void> trainModel(String filepath, common.TrainingJob job)
    => throw UnimplementedError();
  
  Future<void> runModel(
    String? modelId, 
    common.PredictionJob job, 
    List<String> filepaths
  )
    => throw UnimplementedError();
}