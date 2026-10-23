import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'project_settings.dart';
import 'predictions/predictions_page.dart';
import 'data/data_page.dart';
import 'map_page.dart';

/// A stateful widget for the project dashboard page, with a given project
/// as a required field.
class ProjectDashboard extends StatefulWidget 
{
  const ProjectDashboard({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

/// The mutable state of the project dashboard page.
class _ProjectDashboardState extends State<ProjectDashboard> 
{
  /// Description of the project, if changed.
  String? projectDescription;

  /// Boolean variable to track whether the description of the project has
  /// been changed.
  bool isDescriptionChanged = false;

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// description for the project.
  void changeDescription()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                      await widget.project.setDescription(value!);

                      setState(() {
                        projectDescription = value;
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
                await widget.project.setDescription(projectDescription!);

                setState(() {
                  isDescriptionChanged = true;
                });

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
    return ListView(
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
              widget.project.name, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ),
        ), 
        Center(
          child: isDescriptionChanged
            ? Text(projectDescription!)
            : Text(widget.project.description)
        ),
        Center(
            child: Text("Date Created: ${widget.project.createdAt}")
          ),
        Center(
            child: Text("Last Updated: ${DateTime.now()}")
          ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: changeDescription,
            child: Text("Change description")
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: 
                (context) => MapPage(project: widget.project),
            )),
            heroTag: "mapPage",
            child: Text("Site Map")
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: 
                (context) => DataPage(project: widget.project),
            )),
            heroTag: "dataPage",
            child: Text("Sample Data")
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => PredictionsPage(projectId: widget.project.id),
            )),
            heroTag: "predictionsPage",
            child: Text("Predictions")
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => ProjectSettings(projectId: widget.project.id),
            )),
            heroTag: "settingsPage",
            child: Text("Settings")
          )
        ),
      ]
    );
  }
}