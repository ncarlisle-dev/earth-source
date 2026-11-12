import 'package:archaeo_sight_2/api/controllers/project_controller.dart';
import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import './project_dashboard.dart';
import 'dart:convert' as convert;

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

  Future<String> fetchLayerImage(String projectId) async
  {
    String layerImage = "";

    final projectController = await ProjectController.getInstance();
    final project = await projectController.getProjectById(projectId);

    if (project.layers.isNotEmpty)
    {
      layerImage = await project.getLayerImage(project.layers[0].id);
    }

    return layerImage;
  }

  /// Displays a dialogue box containing forms for the user to fill out for
  /// project creation, adds the new project to the project controller, and
  /// navigates to the dashboard for the newly created project.
  void createProject()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final dropdownStateZone = GlobalKey<FormFieldState>();
    final dropdownStateHemisphere = GlobalKey<FormFieldState>();

    List<double> eastings = [];
    List<double> northings = [];

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
                  Text(
                    "Enter coordinates for each corner of the project site."
                  ),
                  // top left corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Easting:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left easting';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      eastings.add(double.parse(value.toString()));
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Northing:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left northing';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      northings.add(double.parse(value.toString()));
                    },
                  ),

                  // top right corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Easting:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-right easting';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      eastings.add(double.parse(value.toString()));
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Northing:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-right northing';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      northings.add(double.parse(value.toString()));
                    },
                  ),

                  // bottom left corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Easting:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left easting';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      eastings.add(double.parse(value.toString()));
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Northing:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left northing';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      northings.add(double.parse(value.toString()));
                    },
                  ),
  
                  // bottom
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Easting:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-right easting';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      eastings.add(double.parse(value.toString()));
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Northing:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-right northing';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      northings.add(double.parse(value.toString()));
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

                await projectController.createProject(
                  projectName, 
                  projectDescription,
                  int.parse(zoneValue),
                  hemisphere == "Southern",
                  [
                    (easting: eastings[0], northing: northings[0]), 
                    (easting: eastings[1], northing: northings[1]),  
                    (easting: eastings[2], northing: northings[2]),  
                    (easting: eastings[3], northing: northings[3]), 
                  ]
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
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
    return Material(child: Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Projects", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
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
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: snapshot.data!.length, 
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () async {
                      final projectController = 
                        await ProjectController.getInstance();
                      final project = await projectController.getProjectById(
                        snapshot.data![index].id
                      );

                      if (!context.mounted) return;

                      Navigator.push(context, MaterialPageRoute<void>(
                        builder: (context) => ProjectDashboard(project: project)
                      ));
                    },
                    child: Card(
                      margin: EdgeInsetsGeometry.only(top: 20.0),
                      color: Color.fromARGB(255, 232, 237, 242),
                      surfaceTintColor: Color.fromARGB(255, 84, 122, 149),
                      child: 
                        ProjectListItem(
                          name: snapshot.data![index].name,
                          description: snapshot.data![index].description,
                          timeCreated: 
                            snapshot.data![index].createdAt.toString(),
                          timeUpdated: 
                            snapshot.data![index].lastUpdated.toString(),
                          numLayers: snapshot.data![index].numLayers.toString(),
                          numUnits: snapshot.data![index].numUnits.toString(),
                          numPredictions: 
                            snapshot.data![index].numPredictions.toString(),
                          thumbnail: FutureBuilder(
                            future: fetchLayerImage(snapshot.data![index].id),
                            builder: (
                              BuildContext ctx, 
                              AsyncSnapshot<String> newSnapshot
                            ) {
                              if (newSnapshot.hasError) {
                                print(newSnapshot.error!.toString());
                                return Center(
                                  child: Text("Error fetching layer image.")
                                );
                              }

                              if (!newSnapshot.hasData) {
                                return Center(child: Text("Loading image..."));
                              }

                              if (newSnapshot.data == "") {
                                return Center(child: Text(
                                  "No layer image available."
                                ));
                              }

                              else { 
                                return Image.memory(
                                  convert.base64Decode(newSnapshot.data!),
                                  height: 300
                                );
                                }
                            }),
                        ),
                    )
                  );
                }
              );
            }
          ),
        ),
      ],
    ));
  }
}

/// Widget containing the text-based fields for a project.
class ProjectFields extends StatelessWidget {
  const ProjectFields({
    super.key,
    required this.name,
    required this.description,
    required this.timeCreated,
    required this.timeUpdated,
    required this.numLayers,
    required this.numUnits,
    required this.numPredictions
  });

  /// Name of the project.
  final String name;
  /// Description of the project.
  final String description;
  /// Time at which the project was created.
  final String timeCreated;
  /// Time at which the project was last updated.
  final String timeUpdated;
  /// Number of layers in the project.
  final String numLayers;
  /// Number of units in the project.
  final String numUnits;
  /// Number of predictions the project contains.
  final String numPredictions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: <Widget>[
        Text(
          name,
          maxLines: 2,
          overflow: .ellipsis,
          style: const TextStyle(fontWeight: .bold, fontSize: 22.0),
        ),
        const Padding(padding: .only(bottom: 2.0)),
        Expanded(
          child: Text(
            description,
            maxLines: 2,
            overflow: .ellipsis,
            style: const TextStyle(
              fontSize: 15.0, 
              color: Color.fromARGB(255, 84, 122, 149)
            ),
          ),
        ),
        Text(
          "Created At: $timeCreated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Last Modified: $timeUpdated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Number of Layers: $numLayers",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Number of Units: $numUnits",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Number of Predictions: $numPredictions",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
      ],
    );
  }
}

/// Widget representing a single project spec, contained in a row in which the
/// image for the topmost layer is displayed to the left and the text-based
/// fields are displayed to the right.
class ProjectListItem extends StatelessWidget {
  const ProjectListItem({
    super.key,
    required this.name,
    required this.description,
    required this.timeCreated,
    required this.timeUpdated,
    required this.numLayers,
    required this.numUnits,
    required this.numPredictions,
    required this.thumbnail
  });

  /// Widget for the thumbnail image.
  final Widget thumbnail;
  /// Name of the project.
  final String name;
  /// Description of the project.
  final String description;
  /// Time at which the project was created.
  final String timeCreated;
  /// Time at which the project was last updated.
  final String timeUpdated;
  /// Number of layers in the project.
  final String numLayers;
  /// Number of units in the project.
  final String numUnits;
  /// Number of predictions the project contains.
  final String numPredictions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 10.0),
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: .start,
          children: <Widget>[
            AspectRatio(aspectRatio: 1.0, child: thumbnail),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                child: ProjectFields(
                  name: name,
                  description: description,
                  timeCreated: timeCreated,
                  timeUpdated: timeUpdated,
                  numLayers: numLayers,
                  numUnits: numUnits,
                  numPredictions: numPredictions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}