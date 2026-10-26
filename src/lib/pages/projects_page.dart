import 'package:archaeo_sight_2/api/controllers/project_controller.dart';
import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import './project_dashboard.dart';

/// A stateful widget for the user projects page.
class UserProjectsPage extends StatefulWidget 
{
  const UserProjectsPage({super.key});

  @override
  State<UserProjectsPage> createState() => _UserProjectsPageState();
}

/// The mutable state of the user projects page.
class _UserProjectsPageState extends State<UserProjectsPage>
{
  /// Name of the created project.
  String projectName = "";
  /// UTM zone of the created project.
  String zoneValue = "1";
  /// Hemisphere of the created project.
  String hemisphere = "Southern";
  /// Description of the created project.
  String projectDescription = "";

  List<String> utmZones = [for (var i = 1; i <= 60; i++) "$i"]; // 0 to 60
  List<String> hemispheres = ["Southern", "Northern"];

  /// Fetches a list of all the user's projects.
  Future<List<api.ProjectSpec>> fetchProjects() async
  {
    api.ProjectController projectController = 
      await api.ProjectController.getInstance();
    
    return await projectController.getUserProjectSpecs();
  }

  /// Displays a dialogue box containing forms for the user to fill out for
  /// project creation, adds the new project to the project controller, and
  /// navigates to the dashboard for the newly created project.
  void createProject()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final dropdownStateZone = GlobalKey<FormFieldState>();
    final dropdownStateHemisphere = GlobalKey<FormFieldState>();

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
                      labelText: "Enter project name:",
                    ),
                    initialValue: projectName,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the project.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectName = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter project description:",
                    ),
                    initialValue: projectDescription,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description for the project.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectDescription = value!;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Select UTM Zone:")
                  ),
                  DropdownButtonFormField(
                    key: dropdownStateZone,
                    initialValue: zoneValue,
                    items: utmZones.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        zoneValue = value!;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Select hemisphere:")
                  ),
                  DropdownButtonFormField(
                    key: dropdownStateHemisphere,
                    initialValue: hemisphere,
                    items: hemispheres.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        hemisphere = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Create Project"),
              // Access project controller and add new project before navigating
              // to project dashboard.
              onPressed: () async {
                formKey.currentState!.save();

                final projectController = await api.ProjectController
                  .getInstance();

                final newProject = await projectController.createProject(
                  projectName, 
                  projectDescription,
                  int.parse(zoneValue),
                  hemisphere == "Southern",
                  [
                    // TODO: add input for this field
                    (latitude: 0, longitude: 0), 
                    (latitude: 0, longitude: 0),
                    (latitude: 0, longitude: 0),
                    (latitude: 0, longitude: 0),
                  ]
                );

                if (context.mounted) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute<void>(builder: 
                      (context) => ProjectDashboard(project: newProject)
                    )
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
              "Projects", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ), //Icon
        ), 
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: createProject,
            child: const Icon(Icons.add)
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: FutureBuilder(
            future: fetchProjects(),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<List<api.ProjectSpec>> snapshot
            ) {
              if (snapshot.hasError) {
                print(snapshot.error.toString());
                return Center(child: Text("Error occurred fetching data."));
              }

              if (!snapshot.hasData) {
                return Center(child: Text("Loading data..."));
              }

              if (snapshot.data!.isEmpty) {
                return Center(child: Text(
                  "No projects to show. Create one with the button above!"
                ));
              }

              return ListView.builder(
                itemCount: snapshot.data!.length, 
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: SizedBox(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              snapshot.data![index].name,
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Description: "
                                "${snapshot.data![index].description}",
                              style: TextStyle(fontSize: 15)
                            ),
                            Text(
                              "Date Created: "
                                "${snapshot.data![index].createdAt}",
                              style: TextStyle(fontSize: 15)
                            ),
                            Text(
                              "Last Updated: "
                                "${snapshot.data![index].lastUpdated}",
                              style: TextStyle(fontSize: 15)
                            ),
                            Text(
                              "Number of Layers: "
                                "${snapshot.data![index].numLayers}",
                              style: TextStyle(fontSize: 15)
                            ),
                            Text(
                              "Number of Units: "
                                "${snapshot.data![index].numUnits}",
                              style: TextStyle(fontSize: 15)
                            ),
                            Text(
                              "Number of Predictions: "
                                "${snapshot.data![index].numPredictions}",
                              style: TextStyle(fontSize: 15)
                            ),

                            // Button which navigates to the project 
                            // dashboard page for the selected project.
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final projectController = 
                                    await ProjectController.getInstance();
                                  final project = await projectController
                                    .getProjectById(
                                      snapshot.data![index].id
                                    );

                                  if (!context.mounted) return;

                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute<void>(
                                      builder: (context) 
                                        => ProjectDashboard(
                                          project: project
                                        )
                                    )
                                  );
                                },
                                child: Text("View Project")
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }
              );
            }
          ),
        ),
      ],
    );
  }
}
