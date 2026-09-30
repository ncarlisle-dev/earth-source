// TODO: move these to a commmon module and implement them
class ConnectionEntry {}
class Project {}

class NetworkService {
  static NetworkService? instance;
  
  static NetworkService getInstance() {
    if (instance != null) return instance!;

    instance = NetworkService();
    return instance!;
  }

  Future<bool> login(String username, String password)
    => throw UnimplementedError();

  Future<void> logout()
    => throw UnimplementedError();

  Future<List<ConnectionEntry>> getConnectionEntries()
    => throw UnimplementedError();

  Future<ConnectionEntry> getConnectionEntry()
    => throw UnimplementedError();

  Future<void> uploadConnectionEntry(ConnectionEntry entry)
    => throw UnimplementedError();

  Future<ConnectionEntry> deleteConnectionEntry(String id)
    => throw UnimplementedError();

  Future<List<Project>> getProjects()
    => throw UnimplementedError();

  Future<Project> getProject(String id)
    => throw UnimplementedError();

  Future<void> uploadProject(Project project)
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