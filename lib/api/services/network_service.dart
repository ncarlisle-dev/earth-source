import '../common/common.dart' as common;
import 'package:logto_dart_sdk/logto_dart_sdk.dart' as logto;
import 'package:convex_flutter/convex_flutter.dart' as convex;
import 'package:flutter/material.dart' as material;

const _logtoConfig = logto.LogtoConfig(
  endpoint: "https://5uk3n8.logto.app",
  appId: "zezv2cwbq7xi0gw6wrmzf",
  resources: [
    "https://5uk3n8.logto.app/api",
  ],
);

const _logtoRedirectUrl = "io.logto://callback";

class NetworkService {
  static NetworkService? _instance;
  final logto.LogtoClient _logtoClient = logto.LogtoClient(config: _logtoConfig);

  /// Privately-named constructor to prevent other modules from creating a 
  /// new service.
  NetworkService._();
  
  static Future<NetworkService> getInstance() async {
    if (_instance != null) return _instance!;

    material.WidgetsFlutterBinding.ensureInitialized();

    await convex.ConvexClient.initialize(
      convex.ConvexConfig(
        deploymentUrl: 'https://standing-eel-607.convex.cloud',
        operationTimeout: Duration(seconds: 15),
        healthCheckQuery: "health:ping",
      ),
    );

    _instance = NetworkService._();

    return _instance!;
  }

  Future<void> login() async
  {
    await _logtoClient.signIn(_logtoRedirectUrl);
    final accessToken = await _logtoClient.getAccessToken(
      resource: "https://5uk3n8.logto.app/api"
    );

    final convexClient = convex.ConvexClient.instance;
    print("????????????????? Setting auth token to '${accessToken!.token}'");
    await convexClient.setAuth(token: accessToken!.token);

    print('????????????????? Connected: ${convexClient.isConnected}');
    print('????????????????? Connection state: ${convexClient.currentConnectionState}');

    print("Storing user ???????????????????");
    try {
      final _ = await convexClient.mutation(name: "auth:storeUser", args: {});
    } catch (e) {
      print(e.toString());
    }


    // print("Creating connection spec ???????????????????");
    // final test = await convexClient.mutation(
    //   name: "connections:createConnectionSpec",
    //   args: {
    //     "ipAddress": "127.0.0.1",
    //     "port": 8888,
    //   },
    // );

    // print("Inserted connection spec with result: $test");
  }

  Future<void> logout() async
  {
    await _logtoClient.signOut(_logtoRedirectUrl);
  }

  Future<bool> isAuthenticated() async
    => _logtoClient.isAuthenticated;

  Future<List<common.ConnectionSpec>> getConnectionEntries()
    => throw UnimplementedError();

  Future<common.ConnectionSpec> getConnectionSpec()
    => throw UnimplementedError();

  Future<void> uploadConnectionSpec(common.ConnectionSpec entry)
    => throw UnimplementedError();

  Future<common.ConnectionSpec> deleteConnectionSpec(String id)
    => throw UnimplementedError();

  Future<List<common.Project>> getProjects()
    => throw UnimplementedError();

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