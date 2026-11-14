import 'package:flutter/material.dart';
import '../api/api.dart' as api;
import 'home_page.dart';

/// A stateful widget for the project settings page, with a given project id
/// as a required field.
class ProjectSettings extends StatefulWidget
{
  // Id of the current project.
  final api.Project project;
  const ProjectSettings({super.key, required this.project});

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
            " predictions) will also be deleted from the app.")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                final projectController = 
                  await api.ProjectController.getInstance();

                await projectController.deleteProject(widget.project.id);
                if (context.mounted)
                {
                  Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => HomePage(),
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

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// description for the project.
  void changeDescription()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String projectDescription = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter new description:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value for the new description';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectDescription = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                formKey.currentState!.save();
                await widget.project.setDescription(projectDescription);

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    return Material(child: ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
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
            onPressed: changeDescription,
            child: Text("Change Project Description")
          )
        ), 
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: deleteProject,
            child: Text("Delete Project")
          )
        ), 
      ]
    ));
  }
}