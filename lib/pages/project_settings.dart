import 'package:flutter/material.dart';
import '../api/api.dart' as api;
import 'projects_page.dart';

/// A stateful widget for the project settings page, with a given project id
/// as a required field.
class ProjectSettings extends StatefulWidget
{
  final String projectId;
  const ProjectSettings({super.key, required this.projectId});

  @override
  State<ProjectSettings> createState() => _ProjectSettingsState();
}

/// The mutable state of the project settings page.
class _ProjectSettingsState extends State<ProjectSettings> 
{
  /// Displays a pop-up dialogue box that confirms if the user wants to delete
  /// the current project, and if so, returns them to the projects page.
  void deleteProject() async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Are you sure you want to delete this project? All "
            "associated project data (e.g. layers, units, pXRF sample data, and"
            " predictions) will be deleted from the app with the project.")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                // Find the appropriate project in the project controller
                // and delete the corresponding prediction job.
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                projectController.deleteProject(widget.projectId);
                if (context.mounted)
                {
                  Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => ProjectsPage(),
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Project Settings",
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: deleteProject,
            child: Text("Delete Project")
          )
        ), 
      ]
    );
  }
}