import '../services/network_service.dart';
import '../common/common.dart' as common;

/// A controller that bridges the frontend and backend, allowing user projects 
/// to be accessed and manipulated by means of the network service
class ProjectController {
  /// Privately-named constructor to prevent other modules from creating a 
  /// new controller.
  ProjectController._();

  /// Static instance of the project controller
  static ProjectController? instance;

  /// User projects stored in the project controller, keyed by ID
  final Map<String, common.Project> _cachedProjects = {};

  /// Retrieves the ProjectController instance if already initialized; if not, 
  /// creates an instance and fetches the user's projects from the database
  /// 
  /// Throws a [network.ApiNetworkException] if the request to fetch user 
  /// projects fails.
  static Future<ProjectController> getInstance() async
  {
    if (instance != null) return instance!;

    instance = ProjectController._();
    return instance!;
  }

  /// Creates a project using a given name and description, uploads it to the 
  /// server, and returns it.
  /// 
  /// Throws a [common.ApiNetworkException] if the server request to upload a 
  /// new project fails.
  Future<common.Project> createProject(
    String name, 
    String description, 
    int utmZone,
    bool isSouthernHemisphere,
    List<common.Coordinate> corners,
  ) async
  {
    // TODO: create a PushProject type or similar so that we're not forwarding
    //       arguments like this so much.
    final networkService = await NetworkService.getInstance();
    final common.Project createdProject;

    try {
      createdProject = await networkService.createProject(
        name,
        description,
        utmZone,
        isSouthernHemisphere,
        corners
      );
    }
    on common.ApiNetworkException catch (error) {
      throw common.ApiNetworkException(
        "Project upload failed with the following error:\n$error", 
        error.statusCode
      );
    }

    _cachedProjects[createdProject.id] = createdProject;
    return createdProject;
  }

  Future<common.Project> getProjectById(String id) async {
    if (_cachedProjects.containsKey(id)) return _cachedProjects[id]!;

    final networkService = await NetworkService.getInstance();

    final project = await networkService.getProjectById(id);
    _cachedProjects[id] = project;
    return project;
  }

  Future<List<common.ProjectSpec>> getUserProjectSpecs() async
  {
    final networkService = await NetworkService.getInstance();
    return await networkService.getUserProjectSpecs();
  }

  /// Finds and deletes a project with the given id.
  /// 
  /// Throws a [network.ApiNetworkException] if the server request to delete the 
  /// project fails.
  Future<void> deleteProject(String id) async
  {
    final networkService = await NetworkService.getInstance();

    try {
      await networkService.deleteProject(id);
    }
    on common.ApiNetworkException catch (error) {
      throw common.ApiNetworkException(
        "Project deletion failed with the following error:\n$error", 
        error.statusCode
      );
    }

    _cachedProjects.remove(id);
  }
}