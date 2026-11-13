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

  /// List of all possible UTM zones from 1 to 60.
  List<String> utmZones = [for (var i = 1; i <= 60; i++) "$i"];
  /// List of northern and southern hemispheres.
  List<String> hemispheres = ["Southern", "Northern"];

  /// List to store specs for all user projects.
  List<api.ProjectSpec> projects = [];
  /// List to store string representations of layer images.
  List<String> layerImages = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Loads data for project specs and layer images when the page is loaded.
  Future<void> _loadData() async
  {

    api.ProjectController projectController = 
      await api.ProjectController.getInstance();

    api.LayerImages layerImageController =
      await api.LayerImages.getInstance();

    projects = await projectController.getUserProjectSpecs();

    for (var project in projects)
    {
      final projectData = await projectController.getProjectById(project.id);
      String layerImage = "";
      if (projectData.layers.isNotEmpty)
      {
        layerImage = await layerImageController.getImageByProjectId(
          project.id, 
          projectData.layers[0].id
        );
      }
      layerImages.add(layerImage);
    }

    setState(() {
      projects;
      layerImages;
      loading = false;
    });
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

                api.Project newProject = await projectController.createProject(
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

                // Update projects and layerImages to update page display.
                projects.add(api.ProjectSpec(
                  id: newProject.id, 
                  name: projectName, 
                  description: projectDescription, 
                  utmZone: newProject.utmZone, 
                  isSouthernHemisphere: newProject.isSouthernHemisphere, 
                  corners: newProject.corners, 
                  numLayers: 0, 
                  numUnits: 0, 
                  numPxrfData: 0, 
                  numTrainingData: 0, numPredictions: 0, 
                  numModels: 0, 
                  createdAt: newProject.createdAt, 
                  lastUpdated: newProject.lastUpdated
                ));

                layerImages.add("");

                setState(() => projects);
                setState(() => layerImages);

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
    return Material(child: ListView(
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
          loading
            ?
            Center(child: Text("Loading data..."))
            :
            projects.isEmpty
              ?
              Center(child: Text(
                "No projects to show. Create one with the button above!"
              ))
              :
              ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: projects.length, 
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () async {
                      final projectController = 
                        await ProjectController.getInstance();
                      final project = await projectController.getProjectById(
                        projects[index].id
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
                      child: ProjectListItem(
                        name: projects[index].name,
                        description: projects[index].description,
                        timeCreated: 
                          projects[index].createdAt.toString(),
                        timeUpdated: 
                          projects[index].lastUpdated.toString(),
                        numLayers: projects[index].numLayers.toString(),
                        numUnits: projects[index].numUnits.toString(),
                        numPredictions: 
                          projects[index].numPredictions.toString(),
                        thumbnail: 
                        layerImages.isEmpty
                        ?
                        Center()
                        :
                            layerImages[index] == ""
                            ?
                            Center(child: 
                              Text("No image added to this project yet!")
                            )
                            :
                            Image.memory(
                              convert.base64Decode(layerImages[index]),
                              height: 300
                            ),
                        ),
                      )
                  );
                }
              ),
        Center(),
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