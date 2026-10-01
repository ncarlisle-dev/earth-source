import '../../services/network_service.dart' as network_service;
import '../../airdroid/connection.dart' as connection;
import 'project.dart' as project;

network_service.NetworkService networkService = 
  network_service.NetworkService.getInstance();

/// A controller that bridges the frontend and backend, allowing user projects 
/// to be accessed and manipulated by means of the network service
class ProjectController 
{
  /// Static instance of the project controller
  static ProjectController? instance;

  /// List of user projects stored in the project controller
  List<project.Project> userProjects = [];

  /// Retrieves the ProjectController instance if already initialized; if not, 
  /// creates an instance and fetches the user's projects from the database
  /// 
  /// Throws a [connection.NetworkException] if the request to fetch user 
  /// projects fails.
  static Future<ProjectController> getInstance() async
  {
    if (instance != null) return instance!;

    instance = ProjectController();
    try {
      instance!.userProjects = await networkService.getProjects();
    }
    catch (error) {
      throw connection.NetworkException(
        "Failed to upload user projects due to the following error:\n$error", 
        null);
    }
    return instance!;
  }

  /// Creates a project using a given name and description, uploads it to the 
  /// server, and returns it.
  /// 
  /// Throws a [connection.NetworkException] if the server request to upload a 
  /// new project fails.
  Future<project.Project> createProject(String name, String description) async
  {
    project.Project createdProject = 
      project.Project(name, description, DateTime.now());
    createdProject.lastUpdated = DateTime.now();
    try {
      await networkService.uploadProject(createdProject);
      userProjects.add(createdProject);
    }
    catch (error) {
      throw connection.NetworkException(
        "Project upload failed with the following error:\n$error", null);
    }
    return createdProject;
  }

  /// Finds and deletes a project with the given id.
  /// 
  /// Throws a [connection.NetworkException] if the server request to delete the 
  /// project fails.
  Future<void> deleteProject(String id) async
  {
    int deleteIndex = userProjects.indexWhere((project) => project.id == id);
    try {
      await networkService.deleteProject(id);
      userProjects.removeAt(deleteIndex);
    }
    catch (error) {
      throw connection.NetworkException(
        "Project deletion failed with the following error:\n$error", null);
    }
  }
}