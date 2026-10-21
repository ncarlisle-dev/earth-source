import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'package:coordinate_converter/coordinate_converter.dart' as coord_converter;

/// A stateful widget for the project site map page, which takes the current 
/// project as a required field.
class MapPage extends StatefulWidget
{
  const MapPage({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<MapPage> createState() => _MapPageState();
}

/// The mutable state of the site map page.
class _MapPageState extends State<MapPage>
{
  List<api.LayerSpec> updatedLayers = [];
  List<api.UnitSpec> updatedUnits = [];

  void addLayer()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String layerName;
    String layerDescription;
    List<coord_converter.UTMCoordinates> cornerCoords;

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
                      labelText: "Enter layer name:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the layer.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        layerName = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter layer description:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description for the layer.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        layerDescription = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Top-left X Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords1.x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Top-left Y Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords1.y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Bottom-left X Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords2.x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Bottom-left Y Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords2.y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Bottom-right X Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords3.x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Bottom-right Y Coordinate'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      utmCoords3.y = double.parse(value.toString());
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Create Layer"),
              // Access project controller and add new project before navigating
              // to project dashboard.
              onPressed: () async {
                formKey.currentState!.save();
                //api.ProjectController projectController = 
                //  await api.ProjectController.getInstance();
                // api.Project newProject = await projectController.createProject(
                //  projectName!, 
                //  projectDescription!
                //);
                if (context.mounted)
                {
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

  void deleteLayer(String layerId) async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Are you sure you want to delete this layer?")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                projectController.userProjects[projectIndex].
                  deleteLayer(layerId);
                setState(() {
                  updatedLayers = 
                    projectController.userProjects[projectIndex].layers;
                });
                if (context.mounted)
                {
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

  void deleteUnit(String unitId) async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Are you sure you want to delete this unit?")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                projectController.userProjects[projectIndex].
                  deleteUnit(unitId);
                setState(() {
                  updatedUnits = 
                    projectController.userProjects[projectIndex].units;
                });
                if (context.mounted)
                {
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
    List<api.LayerSpec> layers;
    List<api.UnitSpec> units;
    updatedLayers.isEmpty 
      ? layers = widget.project.layers : layers = updatedLayers;
    updatedUnits.isEmpty ? units = widget.project.units : units = updatedUnits;
    return ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Site Map", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ),
        ), 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Layers", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.indigo
              )
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: addLayer,
            child: Text("Add Layer"),
          )
        ),
        ListView.builder(
          itemCount: layers.length, 
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
                        layers[index].name,
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Description: ${layers[index].description}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Corner Coordinates: ${layers[index].cornerCoordinates}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Last Updated: ${layers[index].lastUpdated}"
                        ,
                        style: TextStyle(fontSize: 15)
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute<void>(builder: 
                                (context) => ProjectDashboard(
                                  project: snapshot.data![index]
                                )
                              )
                            ),
                          child: Text("Edit Layer")
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () => deleteLayer(layers[index].id!),
                          child: Text("Delete Layer")
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Units", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.indigo
              )
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: deletePrediction,
            child: Text("Add Unit"),
          )
        ),
      ]
    );
  }
}