import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;
import 'package:latlong2/latlong.dart' as latlong;
import '../mapping/visualizer.dart' as visualizer;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io' as io; 
import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;

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
  /// String to store the encoded contents of an image file.
  String? imageContents;

  /// Loads an image from the local file system and encodes it as a base 64
  /// string.
  Future<void> loadImage() async {
    file_picker.PlatformFile? image = await file_picker.FilePicker.pickFile(
      type: file_picker.FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (image != null) {
      final filePath = image.path!;
      io.File imageFile = io.File(filePath);
      typed_data.Uint8List bytes = await imageFile.readAsBytes();
      imageContents = convert.base64.encode(bytes);
    }
  }

  /// Displays a modal in which the user can create a layer and upload a 
  /// corresponding image from their files, which results in a layer being
  /// added to the project controller.
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
                      layerName = value!;
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
                      layerDescription = value!;
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: loadImage,
                      child: Text("Upload layer image:"),
                    )
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Create Layer"),
              onPressed: () async {
                formKey.currentState!.save();

                // Convert corner coordinates to lat/long.
                List<latlong.LatLng> layerCorners = 
                  visualizer.convertCoordsUTM(cornerCoords);

                // Access project controller and add new layer to the project.
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                api.LayerSpec createdLayer = await 
                  projectController.userProjects[projectIndex].createLayer(
                    layerName!, 
                    layerDescription!, 
                    layerCorners
                  );

                // Upload layer image encoded as a string to the database.
                projectController.userProjects[projectIndex].
                  uploadLayerImage(createdLayer.id!, imageContents!);

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

  /// Displays a form filled in with the fields for the corresponding layer that
  /// the user can choose to edit, registers which if any of the fields have 
  /// been changed, and updates information for the layer accordingly.
  void editLayer(api.LayerSpec layer)
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool nameChanged = false;
    bool descriptionChanged = false;
    bool positioningChanged = false;

    String layerName = layer.name;
    String layerDescription = layer.description;
    List<coord_converter.UTMCoordinates> cornerCoords = 
      visualizer.convertCoordsLatLng(layer.cornerCoordinates);

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
                    initialValue: layer.name,
                    onSaved: (value) async {
                      if (value != layer.name)
                      {
                        layerName = value!;
                        nameChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: layer.description,
                    onSaved: (value) async {
                      if (value != layer.description)
                      {
                        layerDescription = value!;
                        descriptionChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left X Coordinate:'
                    ),
                    initialValue: cornerCoords[0].x as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[0].x)
                      {
                        cornerCoords[0].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Y Coordinate:'
                    ),
                    initialValue: cornerCoords[0].y as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[0].y)
                      {
                        cornerCoords[0].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left X Coordinate:'
                    ),
                    initialValue: cornerCoords[1].x as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[1].x)
                      {
                        cornerCoords[1].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Y Coordinate:'
                    ),
                    initialValue: cornerCoords[1].y as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[1].y)
                      {
                        cornerCoords[1].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right X Coordinate:'
                    ),
                    initialValue: cornerCoords[2].x as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[2].x)
                      {
                        cornerCoords[2].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Y Coordinate:'
                    ),
                    initialValue: cornerCoords[2].y as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[2].y)
                      {
                        cornerCoords[2].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right X Coordinate:'
                    ),
                    initialValue: cornerCoords[3].x as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[3].x)
                      {
                        cornerCoords[3].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Y Coordinate:'
                    ),
                    initialValue: cornerCoords[3].y as String,
                    onSaved: (value) {
                      if (double.parse(value!) != cornerCoords[3].y)
                      {
                        cornerCoords[3].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Save Edits"),
              onPressed: () async {
                formKey.currentState!.save();

                // Convert corner coordinates to lat/long.
                List<latlong.LatLng> layerCorners = 
                  visualizer.convertCoordsUTM(cornerCoords);

                // Access appropriate project in the project controller.
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                
                // Check to see which, if any, of the fields has been changed
                // by the user and make updates accordingly.
                if (nameChanged) {
                  projectController.userProjects[projectIndex].setLayerName(
                    layer.id!, 
                    layerName
                  );
                }
                if (descriptionChanged) {
                  projectController.userProjects[projectIndex].
                    setLayerDescription(layer.id!, layerDescription);
                }
                if (positioningChanged) {
                  projectController.userProjects[projectIndex].
                    setLayerPositioning(layer.id!, layerCorners);
                }

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

  /// Deletes the given layer from the project and updates what is displayed.
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

  /// Displays a modal in which the user can create a unit, which results in the 
  /// unit being added to the project controller.
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
                      unitName = value!;
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
                      unitDescription = value!;
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
                        width = double.parse(value!);
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
                      height = double.parse(value!);
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
                      pointInterval = double.parse(value!);
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
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                projectController.userProjects[projectIndex].createUnit(
                  unitName!, 
                  unitDescription!, 
                  topLeftCoords, 
                  width!,
                  height!, 
                  pointInterval!
                );
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

  /// Displays a form filled in with the fields for the corresponding unit that
  /// the user can choose to edit, registers which if any of the fields have 
  /// been changed, and updates information for the unit accordingly.
  void editUnit(api.UnitSpec unit)
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool nameChanged = false;
    bool descriptionChanged = false;
    bool positioningChanged = false;

    String unitName = unit.name;
    String unitDescription = unit.description;
    coord_converter.UTMCoordinates topLeftUtm = 
      coord_converter.UTMCoordinates.fromDD(coord_converter.DDCoordinates(
        latitude: unit.topLeftCoords.latitude, 
        longitude: unit.topLeftCoords.longitude
      ));
    double width = unit.width;
    double height = unit.height;
    double pointInterval = unit.pointInterval;

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
                    initialValue: unit.name,
                    onSaved: (value) async {
                      if (value != unit.name)
                      {
                        unitName = value!;
                        nameChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: unit.description,
                    onSaved: (value) async {
                      if (value != unit.description)
                      {
                        unitDescription = value!;
                        descriptionChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left X Coordinate:'
                    ),
                    initialValue: topLeftUtm.x as String,
                    onSaved: (value) {
                      if (double.parse(value!) != topLeftUtm.x) 
                      {
                        topLeftUtm.x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Y Coordinate:'
                    ),
                    initialValue: topLeftUtm.y as String,
                    onSaved: (value) {
                      if (double.parse(value!) != topLeftUtm.y) 
                      {
                        topLeftUtm.y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Unit Width (m):",
                    ),
                    initialValue: unit.width as String,
                    onSaved: (value) {
                      if (double.parse(value!) != unit.width) 
                      {
                        width = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Unit Height (m):",
                    ),
                    initialValue: unit.height as String,
                    onSaved: (value) {
                      if (double.parse(value!) != unit.height) 
                      {
                        height = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Unit Point Interval (cm):",
                    ),
                    initialValue: unit.pointInterval as String,
                    onSaved: (value) {
                      if (double.parse(value!) != unit.pointInterval) 
                      {
                        pointInterval = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Submit Edits"),
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
                api.ProjectController projectController = 
                  await api.ProjectController.getInstance();
                int projectIndex = projectController.userProjects.indexWhere(
                  (project) => project.id == widget.project.id);
                
                // Check to see which, if any, of the fields has been changed
                // by the user and make updates accordingly.
                if (nameChanged) {
                  projectController.userProjects[projectIndex].setUnitName(
                    unit.id!, 
                    unitName
                  );
                }
                if (descriptionChanged) {
                  projectController.userProjects[projectIndex].
                    setUnitDescription(unit.id!, unitDescription);
                }
                if (positioningChanged) {
                  projectController.userProjects[projectIndex].
                    repositionUnit(
                      unit.id!, 
                      topLeftCoords, 
                      width, 
                      height, 
                      pointInterval
                    );
                }

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

  /// Deletes the given unit from the project and updates what is displayed.
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

  /// Fetches the image corresponding to a layer from the database for display.
  Future<String> fetchImage(String layerId) async
  {
    String? loadedImage;

    api.ProjectController projectController = 
      await api.ProjectController.getInstance();
    int projectIndex = projectController.userProjects.indexWhere(
      (project) => project.id == widget.project.id);

    loadedImage = 
      await projectController.userProjects[projectIndex].getLayerImage(layerId);

    return loadedImage!;
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
                      FutureBuilder(
                        future: fetchImage(layers[index].id!),
                        builder: (
                          BuildContext ctx, 
                          AsyncSnapshot<String> snapshot
                        ) 
                        => !(snapshot.hasData)
                        ?
                        Center(child: Text("Layer image cannot be uploaded."))
                        :
                        Image.memory(
                          convert.base64Decode(snapshot.data!),
                          height: 300
                        )
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
                          onPressed: () => editLayer(layers[index]),
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
                          onPressed: () => editUnit(units[index]),
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