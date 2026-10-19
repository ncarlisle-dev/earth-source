import '../common/common.dart' as common;
import 'package:logto_dart_sdk/logto_dart_sdk.dart' as logto;
import 'package:convex_flutter/convex_flutter.dart' as convex;

const _logtoConfig = logto.LogtoConfig(
  endpoint: "https://5uk3n8.logto.app",
  appId: "zezv2cwbq7xi0gw6wrmzf",
);

const _logtoRedirectUrl = "io.logto://callback";

class NetworkService {
  static NetworkService? instance;
  final _logtoClient = logto.LogtoClient(config: _logtoConfig);

  /// Privately-named constructor to prevent other modules from creating a 
  /// new service.
  NetworkService._();
  
  static NetworkService getInstance() {
    if (instance != null) return instance!;

    instance = NetworkService._();
    return instance!;
  }

  Future<void> login() async
  {
    await _logtoClient.signIn(_logtoRedirectUrl);
    final userInfo = await _logtoClient.getUserInfo();
    print(userInfo.toJson());
    print(userInfo.sub);

    await convex.ConvexClient.initialize(
      convex.ConvexConfig(
        deploymentUrl: 'https://standing-eel-607.convex.cloud',
        clientId: 'flutter-app-1.0',
        operationTimeout: Duration(seconds: 30), // Optional, defaults to 30s
      ),
    );

    final convexClient = convex.ConvexClient.instance;

    await convexClient.setAuth(token: userInfo.sub);
    final test = await convexClient.mutation(
      name: 'users:list',
      args: {
        "ipAddress": "127.0.0.1",
        "port": "8888",
      },
    );

    print("Inserted connection spec with id: $test");
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