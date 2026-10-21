import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;
import 'package:latlong2/latlong.dart' as latlong;
import '../mapping/visualizer.dart' as visualizer;

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
  /// List containing updated layers for the project.
  List<api.LayerSpec> updatedLayers = [];
  /// List containing updated units for the project.
  List<api.UnitSpec> updatedUnits = [];


  void addLayer()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String? layerName;
    String? layerDescription;
    List<coord_converter.UTMCoordinates> cornerCoords = [
      coord_converter.UTMCoordinates(
        x: 0, 
        y: 0, 
        zoneNumber: widget.project.utmZone, 
        isSouthernHemisphere: widget.project.isSouthernHemisphere
      ),
      coord_converter.UTMCoordinates(
        x: 0, 
        y: 0, 
        zoneNumber: widget.project.utmZone, 
        isSouthernHemisphere: widget.project.isSouthernHemisphere
      ), 
      coord_converter.UTMCoordinates(
        x: 0, 
        y: 0, 
        zoneNumber: widget.project.utmZone, 
        isSouthernHemisphere: widget.project.isSouthernHemisphere
      ), 
      coord_converter.UTMCoordinates(
        x: 0, 
        y: 0, 
        zoneNumber: widget.project.utmZone, 
        isSouthernHemisphere: widget.project.isSouthernHemisphere
      ), 
    ];

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
                    decoration: InputDecoration(
                      labelText: 'Top-left X Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[0].x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Y Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[0].y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left X Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[1].x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Y Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[1].y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right X Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-right X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[2].x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Y Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-right Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[2].y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right X Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-right X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[3].x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Y Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bottom-right Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cornerCoords[3].y = double.parse(value.toString());
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Create Layer"),
              // Access project controller and add new project before navigating
              // to project dashboard.
              onPressed: () async {
                formKey.currentState!.save();
                List<latlong.LatLng> layerCorners = 
                  visualizer.convertCoords(cornerCoords);
                /*api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                projectController.userProjects[projectIndex].
                  createLayer(layerName!, layerDescription!, layerCorners);*/
                setState(() {
                  updatedLayers.add(api.LayerSpec(layerName!, layerDescription!, DateTime.now(), DateTime.now(), layerCorners));
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

  void addUnit()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String? unitName;
    String? unitDescription;
    coord_converter.UTMCoordinates topLeftUtm = 
      coord_converter.UTMCoordinates(
        x: 0, 
        y: 0, 
        zoneNumber: widget.project.utmZone, 
        isSouthernHemisphere: widget.project.isSouthernHemisphere
    );
    double? width;
    double? height;
    double? pointInterval;

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
                      labelText: "Enter unit name:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the unit.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        unitName = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter unit description:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description for the unit.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        unitDescription = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left X Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left X Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      topLeftUtm.x = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Y Coordinate:'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the top-left Y Coordinate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      topLeftUtm.y = double.parse(value.toString());
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter unit width in m:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a width for the unit.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        width = double.parse(value!);
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter unit height in m:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a height for the unit.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        height = double.parse(value!);
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter unit point interval in cm:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a point interval for the unit.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        pointInterval = double.parse(value!);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Create Unit"),
              // Access project controller and add new project before navigating
              // to project dashboard.
              onPressed: () async {
                formKey.currentState!.save();
                ({double latitude, double longitude}) topLeftCoords = (
                  latitude: 
                    coord_converter.DDCoordinates.fromUTM(topLeftUtm).latitude, 
                  longitude: 
                    coord_converter.DDCoordinates.fromUTM(topLeftUtm).longitude
                );
                /*api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                projectController.userProjects[projectIndex].
                  createLayer(layerName!, layerDescription!, layerCorners);*/
                setState(() {
                  updatedUnits.add(api.UnitSpec(unitName!, unitDescription!, DateTime.now(), DateTime.now(), topLeftCoords, width!, height!, pointInterval!));
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
        layers.isEmpty 
        ?
        Center(child: Text("No layers created yet!"))
        :
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: layers.length, 
          itemBuilder: (BuildContext context, int index) {
            return Card(
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
                        "Created At: ${layers[index].createdAt}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Last Updated: ${layers[index].lastUpdated}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () => "null",
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
            onPressed: addUnit,
            child: Text("Add Unit"),
          )
        ),
        units.isEmpty 
        ?
        Center(child: Text("No units created yet!"))
        :
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: units.length, 
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: SizedBox(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        units[index].name,
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Description: ${units[index].description}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Top Left Coordinates: ${units[index].topLeftCoords}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Width: ${units[index].width} m",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Height: ${units[index].height} m",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Point Interval: ${units[index].pointInterval} cm",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Created At: ${units[index].createdAt}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Last Updated: ${units[index].lastUpdated}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () => "null",
                          child: Text("Edit Unit")
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () => deleteUnit(units[index].id!),
                          child: Text("Delete Unit")
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ]
    );
  }
}