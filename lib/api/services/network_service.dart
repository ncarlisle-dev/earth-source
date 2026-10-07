import '../common/common.dart' as common;

class NetworkService {
  static NetworkService? instance;

  /// Privately-named constructor to prevent other modules from creating a 
  /// new service.
  NetworkService._();
  
  static NetworkService getInstance() {
    if (instance != null) return instance!;

    instance = NetworkService._();
    return instance!;
  }

  Future<bool> login(String username, String password)
    => throw UnimplementedError();

  Future<void> logout()
    => throw UnimplementedError();

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
}