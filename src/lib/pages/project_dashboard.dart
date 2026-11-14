import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'project_settings.dart';
import 'predictions/predictions_page.dart';
import 'data/data_page.dart';
import 'map_page.dart';
import 'projects_page.dart';
import 'home_page.dart';

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
  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// name for the project.
  void changeName()
  {
    String projectName = "";

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
                      labelText: "Enter new project name:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value for the new name';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectName = value!;
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
                await widget.project.setName(projectName);

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
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 16.0, 
            horizontal: 20.0
          ),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => UserProjectsPage(),
            )),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
        Stack(
          alignment: AlignmentGeometry.topRight,
          children: <Widget>[
            Center(
              child: Text(
                widget.project.name, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
            padding: EdgeInsetsGeometry.symmetric(
              vertical: 16.0, 
              horizontal: 20.0
            ),
            child: IconButton(
              icon: Icon(Icons.edit),
              color: Color.fromARGB(255, 232, 237, 242),
              style: IconButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 84, 122, 149)
              ),
              onPressed: changeName,
            )
          ),
          ],
        ), 
        Padding(
            padding: EdgeInsetsGeometry.only(
              bottom: 16.0, 
              left: 20.0, 
              right: 20.0
            ),
            child: Center(
              child: Text(
                widget.project.description,
                style: TextStyle(fontSize: 15)
              ),
            ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute<void>(builder: 
                  (context) => MapPage(project: widget.project),
                )
              ),
              child: ButtonContent(icon: Icons.map_outlined, text: "Site Map"),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute<void>(builder: 
                  (context) => DataPage(project: widget.project),
                )
              ),
              child: ButtonContent(
                icon: Icons.dataset_outlined, 
                text: "Sample Data"
              ),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute<void>(builder: 
                    (context) => PredictionsPage(project: widget.project),
                  )
                ),
              child: ButtonContent(
                icon: Icons.batch_prediction, 
                text: "Predictions"
              ),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute<void>(builder: 
                    (context) => ProjectSettings(project: widget.project),
                  )
                ),
              child: ButtonContent(
                icon: Icons.settings_rounded, 
                text: "Project Settings"
              ),
            )
          )
        ),
      ]
    ));
  }
}

/// The content of a button, containing an icon and text phrase aligned on a 
/// row.
class ButtonContent extends StatelessWidget
{
  const ButtonContent({super.key, required this.icon, required this.text});

  /// The icon contained by the button.
  final IconData icon;
  /// The text contained by the button.
  final String text;

  @override
  Widget build(BuildContext context) 
  {
    return Padding(
      padding: const .symmetric(vertical: 10.0),
      child: SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: .start,
          children: <Widget>[
            Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 25.0),
                child: Center(child: Icon(icon, size: 75))),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                child: Center(child: Text(
                  text, 
                  style: TextTheme.of(context).headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: Color.fromARGB(255, 194, 165, 109)
                  )
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}