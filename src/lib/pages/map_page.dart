import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import '../mapping/visualizer.dart' as visualizer;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io' as io; 
import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;
import 'package:coordinate_converter/coordinate_converter.dart' as coords;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_math/flutter_geo_math.dart' as flutter_geo_math;
import 'layer_page.dart';

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

  @override
  Widget build(BuildContext context) 
  {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Units"),
                Tab(text: "Layers"),
              ],
            ),
            title: Center(child: Text(
              'Site Map',
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              )
            )),
          ),
          body: TabBarView(
            children: [
              Units(project: widget.project),
              Layers(project: widget.project),
            ],
          ),
        ),
    );
  }
}

class Units extends StatefulWidget
{
  const Units({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<Units> createState() => _UnitsState();
}

/// The mutable state of the site map page.
class _UnitsState extends State<Units>
{
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

  final verticalScrollController = ScrollController();
  final horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) 
  {
    return Material(child: Column(
      children: [
        Padding (
          padding: EdgeInsetsGeometry.symmetric(vertical: 20.0),
        child: Stack(
          alignment: AlignmentGeometry.topRight,
          children: <Widget>[
            Center(
              child: Text(
                "Units", 
              style: TextTheme.of(context).headlineSmall?.copyWith(
                fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
            padding: EdgeInsetsGeometry.symmetric(
              vertical: 16.0, 
              horizontal: 20.0
            ),
            child: IconButton(
              icon: Icon(Icons.add),
              color: Color.fromARGB(255, 232, 237, 242),
              style: IconButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 84, 122, 149)
              ),
              onPressed: addUnit,
            )
          ),
          ],
        )),
        Center(
        child: Container(
          width: MediaQuery.of(context).size.width, // match the window width
          height: MediaQuery.of(context).size.height - 300,
          margin: const EdgeInsets.all(15.0),

          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true, // make the scrollbar easy to see
            controller: verticalScrollController,
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              controller: horizontalScrollController,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                controller: verticalScrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child:
                    DataTable(
                    columns: const <DataColumn>[
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Name', 
                          style: TextStyle(fontStyle: .italic)
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Created', 
                          style: TextStyle(fontStyle: .italic)
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Modified', 
                          style: TextStyle(fontStyle: .italic)
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Description', 
                          style: TextStyle(fontStyle: .italic)
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Area (m)', 
                          style: TextStyle(fontStyle: .italic)
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text('', style: TextStyle(fontStyle: .italic)),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text('', style: TextStyle(fontStyle: .italic)),
                      ),
                    ),
                  ],
                    rows: List<DataRow>.generate(
                      widget.project.units.length,
                      (int index) => DataRow(
                        cells: <DataCell>[
                        DataCell(Text(widget.project.units[index].name)),
                        DataCell(
                          Text(
                            widget.project.units[index].createdAt.toString()
                          )
                        ),
                        DataCell(
                          Text(
                            widget.project.units[index].lastUpdated.toString()
                          )
                        ),
                        DataCell(
                          Text(
                            widget.project.units[index].description, 
                            maxLines: 1,
                            overflow: .ellipsis
                          )
                        ),
                        DataCell(Text(calculateArea(widget.project.units[index].corners).toString())),
                        DataCell(IconButton(
                          onPressed: () => 
                            editUnit(widget.project.units[index]),
                          icon: Icon(Icons.edit),
                        )),
                        DataCell(IconButton(
                          onPressed: () => 
                            deleteUnit(widget.project.units[index].id),
                          icon: Icon(Icons.delete),
                        )),
                      ],
                    )
                  )
                ),
              ), 
            )
          )
        )
      ))]
    ));
  }
}

/// Calculates and returns the area of a unit, rounded to the nearest meter.
int calculateArea(List<coords.UTMCoordinates> corners)
{
  List<latlong.LatLng> coordinates = visualizer.convertCoordsUTM(corners);

  double width = flutter_geo_math.FlutterMapMath.distanceBetween(
    coordinates[0].latitude, 
    coordinates[0].longitude, 
    coordinates[1].latitude, 
    coordinates[1].longitude,
    ""
  );
  double height = flutter_geo_math.FlutterMapMath.distanceBetween(
    coordinates[0].latitude, 
    coordinates[0].longitude, 
    coordinates[2].latitude, 
    coordinates[2].longitude,
    ""
  );

  double area = width * height;
  
  return area.round();
}

class Layers extends StatefulWidget
{
  const Layers({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<Layers> createState() => _LayersState();
}

/// The mutable state of the site map page.
class _LayersState extends State<Layers>
{
  /// String to store the encoded contents of an image file.
  String? imageContents;

  bool imageLoaded = false;

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
    String? imageName;

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
                    decoration: const InputDecoration(
                      labelText: "Enter a name for the layer image:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the layer image.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      imageName = value!;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: loadImage,
                      child: Text("Upload layer image:"),
                    )
                  ),
                  !imageLoaded
                    ?
                    Center()
                    :
                    Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text("Image has been uploaded!"),
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

                // Access project controller and add new layer to the project.
                final createdLayer = await widget.project.createLayer(
                  layerName!, 
                  layerDescription!, 
                );

                // Upload layer image encoded as a string to the database.
                await widget.project.uploadLayerImage(
                  createdLayer.id,
                  imageContents!,
                  imageName!
                );

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

  /// Fetches the image corresponding to a layer from the cache for display.
  Future<String> fetchImage(String layerId) async
  {
    return widget.project.getLayerImage(layerId);
  }

  @override
  Widget build(BuildContext context) 
  {
    return Material(child: Column(
      children: [
        Padding (
          padding: EdgeInsetsGeometry.symmetric(vertical: 20.0),
          child: Stack(
            alignment: AlignmentGeometry.topRight,
            children: <Widget>[
              Center(
                child: Text(
                  "Layers", 
                  style: TextTheme.of(context).headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  vertical: 16.0, 
                  horizontal: 20.0
                ),
                child: IconButton(
                  icon: Icon(Icons.add),
                  color: Color.fromARGB(255, 232, 237, 242),
                  style: IconButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 84, 122, 149)
                  ),
                  onPressed: addLayer,
                )
              )
            ]
          )
        ),
        widget.project.layers.isEmpty
          ?
          Center(child: Text(
            "No layers created yet!"
          ))
          :
          ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: widget.project.layers.length, 
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => LayerPage(
                      project: widget.project, 
                      layer: widget.project.layers[index]
                    )
                  ));
                },
                child: Card(
                  margin: 
                    EdgeInsetsGeometry.only(
                      top: 20.0, 
                      left: 20.0, 
                      right: 20.0
                    ),
                  color: Color.fromARGB(255, 232, 237, 242),
                  surfaceTintColor: Color.fromARGB(255, 84, 122, 149),
                  child: LayerItem(
                    name: widget.project.layers[index].name,
                    description: widget.project.layers[index].description,
                    timeCreated: 
                      widget.project.layers[index].createdAt.toString(),
                    timeUpdated: 
                      widget.project.layers[index].lastUpdated.toString(),
                    thumbnail: 
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                            horizontal: 10.0),
                    child: FutureBuilder(
                    future: fetchImage(widget.project.layers[index].id),
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
                    ),
                  )
              ));
            }
          ),
        ]));
  }
}

/// Widget containing the text-based fields for a project.
class LayerFields extends StatelessWidget {
  const LayerFields({
    super.key,
    required this.name,
    required this.description,
    required this.timeCreated,
    required this.timeUpdated,
  });

  /// Name of the project.
  final String name;
  /// Description of the project.
  final String description;
  /// Time at which the project was created.
  final String timeCreated;
  /// Time at which the project was last updated.
  final String timeUpdated;

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
      ],
    );
  }
}

/// Widget representing a single project spec, contained in a row in which the
/// image for the topmost layer is displayed to the left and the text-based
/// fields are displayed to the right.
class LayerItem extends StatelessWidget {
  const LayerItem({
    super.key,
    required this.name,
    required this.description,
    required this.timeCreated,
    required this.timeUpdated,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 10.0),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: .start,
          children: <Widget>[
            AspectRatio(aspectRatio: 1.0, child: thumbnail),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                child: LayerFields(
                  name: name,
                  description: description,
                  timeCreated: timeCreated,
                  timeUpdated: timeUpdated,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}