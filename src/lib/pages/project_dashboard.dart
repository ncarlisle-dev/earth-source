import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'project_settings.dart';
import 'predictions/predictions_page.dart';
import 'data/data_page.dart';
import 'map_page.dart';
import 'projects_page.dart';

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
  /// Description of the project
  String? projectDescription;

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
                await widget.project.setDescription(projectDescription!);

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
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => UserProjectsPage(),
            )),
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
              )
            )
          ),
        ), 
        Center(
          child: Text(
            widget.project.description,
            style: TextStyle(fontSize: 15)
          ),
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
            child: ButtonContent(icon: Icons.map_outlined, text: "Site Map")
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
                (context) => PredictionsPage(project: widget.project),
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
    ));
  }
}

class ButtonContent extends StatelessWidget
{
  const ButtonContent({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) 
  {
   return Padding(
          padding: const .symmetric(vertical: 10.0),
          child: SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: .start,
              children: <Widget>[
                Icon(icon),
                Expanded(
                  child: Padding(
                    padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                    child: Center(child: Text(text, style: TextTheme.of(context).headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, )
                  )),
                    ),
                  ),
              ],
            ),
          ),
        );
  }
}