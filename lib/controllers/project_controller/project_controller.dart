import '../../services/network_service.dart';
import '../../airdroid/connection.dart';
import 'project.dart';

/// A controller that bridges the frontend and backend, allowing user projects 
/// to be accessed and manipulated by means of the network service
class ProjectController 
{
  /// Static instance of the project controller
  static ProjectController? instance;

  /// List of user projects stored in the project controller
  List<Project> userProjects = [];

  /// Retrieves the ProjectController instance if already initialized; if not, 
  /// creates an instance and fetches the user's projects from the database
  /// 
  /// Throws a [connection.NetworkException] if the request to fetch user 
  /// projects fails.
  static Future<ProjectController> getInstance() async
  {
    NetworkService networkService = NetworkService.getInstance();
    if (instance != null) return instance!;

    instance = ProjectController();
    try {
      instance!.userProjects = await networkService.getProjects();
    }
    on NetworkException catch (error) {
      throw NetworkException(
        "Failed to upload user projects due to the following error:\n$error", 
        null
      );
    }
    return instance!;
  }

  /// Creates a project using a given name and description, uploads it to the 
  /// server, and returns it.
  /// 
  /// Throws a [connection.NetworkException] if the server request to upload a 
  /// new project fails.
  Future<Project> createProject(String name, String description) async
  {
    NetworkService networkService = NetworkService.getInstance();
    Project createdProject = 
      Project(name, description, DateTime.now());
    createdProject.lastUpdated = DateTime.now();
    try {
      await networkService.uploadProject(createdProject);
      userProjects.add(createdProject);
    }
    on NetworkException catch (error) {
      throw NetworkException(
        "Project upload failed with the following error:\n$error", 
        null
      );
    }
    return createdProject;
  }

  /// Finds and deletes a project with the given id.
  /// 
  /// Throws a [connection.NetworkException] if the server request to delete the 
  /// project fails.
  Future<void> deleteProject(String id) async
  {
    NetworkService networkService = NetworkService.getInstance();
    int deleteIndex = userProjects.indexWhere((project) => project.id == id);
    try {
      await networkService.deleteProject(id);
      userProjects.removeAt(deleteIndex);
    }
    on NetworkException catch (error) {
      throw NetworkException(
        "Project deletion failed with the following error:\n$error", 
        null
      );
    }
  }
}