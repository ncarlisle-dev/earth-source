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
  List<api.Layer> updatedLayers = [];
  /// List containing updated units for the project.
  List<api.Unit> updatedUnits = [];
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
                final List<List<double>> layerCorners = [
                  [eastings[0], northings[0]],
                  [eastings[1], northings[1]],
                  [eastings[2], northings[2]],
                  [eastings[3], northings[3]],
                ];

                // Access project controller and add new layer to the project.
                final createdLayer = await widget.project.createLayer(
                  layerName!, 
                  layerDescription!, 
                  layerCorners
                    .map((coord) => (
                      easting: coord[0],
                      northing: coord[1]
                    ))
                    .toList()
                );

                // Upload layer image encoded as a string to the database.
                await widget.project.uploadLayerImage(
                  createdLayer.id,
                  imageContents!,
                  "unnamed image" // TODO: create an input for this
                );

                setState(() => updatedLayers = widget.project.layers);

                if (context.mounted) Navigator.of(context).pop();
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
  void editLayer(api.Layer layer)
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool nameChanged = false;
    bool descriptionChanged = false;
    bool positioningChanged = false;

    String layerName = layer.name;
    String layerDescription = layer.description;

    List<List<double>> cornerCoords = [
      [layer.corners[0].x, layer.corners[0].y], 
      [layer.corners[1].x, layer.corners[1].y], 
      [layer.corners[2].x, layer.corners[2].y], 
      [layer.corners[3].x, layer.corners[3].y]
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
                      labelText: 'Top-left Easting:'
                    ),
                    initialValue: "${layer.corners[0].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[0].x) {
                        cornerCoords[0][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Northing:'
                    ),
                    initialValue: "${layer.corners[0].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[0].y) {
                        cornerCoords[0][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Easting:'
                    ),
                    initialValue: "${layer.corners[1].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[1].x) {
                        cornerCoords[1][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Northing:'
                    ),
                    initialValue: "${layer.corners[1].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[1].y) {
                        cornerCoords[1][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Easting:'
                    ),
                    initialValue: "${layer.corners[2].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[2].x) {
                        cornerCoords[2][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Easting:'
                    ),
                    initialValue: "${layer.corners[2].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[2].y) {
                        cornerCoords[2][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Northing:'
                    ),
                    initialValue: "${layer.corners[3].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[3].x) {
                        cornerCoords[3][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Northing:'
                    ),
                    initialValue: "${layer.corners[3].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != layer.corners[3].y) {
                        cornerCoords[3][1] = double.parse(value);
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

                // Check to see which, if any, of the fields has been changed
                // by the user and make updates accordingly.
                if (nameChanged) {
                  await widget.project.updateLayer(layer.id, name: layerName);
                }

                if (descriptionChanged) {
                  await widget.project.updateLayer(
                    layer.id,
                    description: layerDescription
                  );
                }

                if (positioningChanged) {
                  await widget.project.updateLayer(
                    layer.id,
                    corners: cornerCoords.map(
                      (coord) => (
                        easting: coord[0],
                        northing: coord[1]
                      )
                    ).toList(),
                  );
                }

                setState(() => updatedLayers = widget.project.layers);

                if (context.mounted) Navigator.of(context).pop();
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
                await widget.project.deleteLayer(layerId);
                setState(() => updatedLayers = widget.project.layers);

                if (context.mounted) Navigator.of(context).pop();
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
    
    List<double> eastings = [];
    List<double> northings = [];
    
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

                  // point interval
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
                final List<({double easting, double northing})> corners = [
                  (
                    easting: eastings[0], 
                    northing: northings[0]
                  ),
                  (
                    easting: eastings[1], 
                    northing: northings[1]
                  ),
                  (
                    easting: eastings[2], 
                    northing: northings[2]
                  ),
                  (
                    easting: eastings[3], 
                    northing: northings[3]
                  ),
                ];

                await widget.project.createUnit(
                  unitName!, 
                  unitDescription!, 
                  corners,
                  pointInterval!
                );

                setState(() => updatedUnits = widget.project.units);

                if (context.mounted) Navigator.of(context).pop();
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
  void editUnit(api.Unit unit)
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool nameChanged = false;
    bool descriptionChanged = false;
    bool positioningChanged = false;

    String unitName = unit.name;
    String unitDescription = unit.description;
    double pointInterval = unit.pointInterval;

    List<List<double>> corners = [
      [unit.corners[0].x, unit.corners[0].y], 
      [unit.corners[1].x, unit.corners[1].y], 
      [unit.corners[2].x, unit.corners[2].y], 
      [unit.corners[3].x, unit.corners[3].y]
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

                  // top left corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Easting:'
                    ),
                    initialValue: "${corners[0][0]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[0][0]) 
                      {
                        corners[0][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Northing:'
                    ),
                    initialValue: "${corners[0][1]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[0][1]) 
                      {
                        corners[0][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // top right corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Easting:'
                    ),
                    initialValue: "${corners[1][0]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[1][0]) 
                      {
                        corners[1][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Northing:'
                    ),
                    initialValue: "${corners[1][1]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[1][1]) 
                      {
                        corners[1][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // bottom left corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Easting:'
                    ),
                    initialValue: "${corners[2][0]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[2][0]) 
                      {
                        corners[2][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Northing:'
                    ),
                    initialValue: "${corners[2][1]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[2][1]) 
                      {
                        corners[2][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // bottom right corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Easting:'
                    ),
                    initialValue: "${corners[3][0]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[3][0]) 
                      {
                        corners[3][0] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Northing:'
                    ),
                    initialValue: "${corners[3][1]}",
                    onSaved: (value) {
                      if (double.parse(value!) != corners[3][1]) 
                      {
                        corners[3][1] = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // point interval
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Unit Point Interval (cm):",
                    ),
                    initialValue: "${unit.pointInterval}",
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

                // Check to see which, if any, of the fields has been changed
                // by the user and make updates accordingly.
                if (nameChanged) {
                  await widget.project.updateUnit(unit.id, name: unitName);
                }

                if (descriptionChanged) {
                  await widget.project.updateUnit(
                    unit.id,
                    description: unitDescription,
                  );
                }

                if (positioningChanged) {
                  await widget.project.updateUnit(
                    unit.id, 
                    corners: corners.map(
                      (coord) => (
                        easting: coord[0],
                        northing: coord[1]
                      )
                    ).toList(),
                    pointInterval: pointInterval,
                  );
                }

                setState(() => updatedUnits = widget.project.units);

                if (context.mounted) Navigator.of(context).pop();
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
                await widget.project.deleteUnit(unitId);
                setState(() => widget.project.units);
                if (context.mounted) Navigator.of(context).pop();
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
  Future<String> fetchImage(String layerId)
    => widget.project.getLayerImage(layerId);

  @override
  Widget build(BuildContext context) 
  {
    List<api.Layer> layers;
    List<api.Unit> units;

    layers = widget.project.layers;
    units = widget.project.units;

    return Material(child:ListView(
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
                        future: fetchImage(layers[index].id),
                        builder: (
                          BuildContext ctx, 
                          AsyncSnapshot<String> snapshot
                        )
                        {
                          if (snapshot.hasError) {
                            print(snapshot.error!.toString());
                            return Center(
                              child: Text("Error fetching layer image.")
                            );
                          }

                          if (!snapshot.hasData) {
                            return Center(child: Text("Loading image..."));
                          }

                          return Image.memory(
                            convert.base64Decode(snapshot.data!),
                            height: 300
                          );
                        }
                      ),
                      Text(
                        "Description: ${layers[index].description}",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Top Left Coordinate: ("
                        "${layers[index].corners[0].x}, "
                        "${layers[index].corners[0].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Top Right Coordinate: ("
                        "${layers[index].corners[1].x}, "
                        "${layers[index].corners[1].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Bottom Left Coordinate: ("
                        "${layers[index].corners[2].x}, "
                        "${layers[index].corners[2].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Bottom Right Coordinate: ("
                        "${layers[index].corners[3].x}, "
                        "${layers[index].corners[3].y})",
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
                          onPressed: () => deleteLayer(layers[index].id),
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
                        "Top Left Coordinate: ("
                        "${units[index].corners[0].x}, "
                        "${units[index].corners[0].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Top Right Coordinate: ("
                        "${units[index].corners[1].x}, "
                        "${units[index].corners[1].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Bottom Left Coordinate: ("
                        "${units[index].corners[2].x}, "
                        "${units[index].corners[2].y})",
                        style: TextStyle(fontSize: 15)
                      ),
                      Text(
                        "Bottom Right Coordinate: ("
                        "${units[index].corners[3].x}, "
                        "${units[index].corners[3].y})",
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
                          onPressed: () => deleteUnit(units[index].id),
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
    ));
  }
}