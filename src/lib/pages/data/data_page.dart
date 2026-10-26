import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'data_file.dart' as data_file;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io' as io;

/// A stateful widget for the project predictions page, which takes the id for 
/// the current project as a required field.
class DataPage extends StatefulWidget 
{
  const DataPage({super.key, required this.project});

  /// The id of the current project.
  final api.Project project;

  @override
  State<DataPage> createState() => _DataPageState();
}

/// The mutable state of the project predictions page.
class _DataPageState extends State<DataPage> 
{
  String unitAssignment = "";
  String layerAssignment = "";

  /// Loads an image from the local file system and encodes it as a base 64
  /// string.
  Future<void> loadCsv() async {
    file_picker.PlatformFile? file = await file_picker.FilePicker.pickFile(
      type: file_picker.FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (file != null) {
      final filePath = file.path!;
      io.File imageFile = io.File(filePath);
      String fileString = await imageFile.readAsString();
      widget.project.addPxrfData(fileString, filePath, "");
    }
  }

  void modifyData(String dataId) async
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final dropdownStateLayer = GlobalKey<FormFieldState>();
    final dropdownStateUnit = GlobalKey<FormFieldState>();

    List<String> layerNames = [];
    List<String> unitNames = [];

    for (api.Layer layer in widget.project.layers) {
      layerNames.add(layer.name);
    }

    for (api.Unit unit in widget.project.units) {
      unitNames.add(unit.name);
    }

    String assignedLayer = layerNames[0];
    String assignedUnit = unitNames[0];

    widget.project.dataAssignments.forEach((layerId, assignment) => 
      assignment.forEach((unitId, dataSpec) {
        if (dataSpec == dataId) {
          assignedLayer = (widget.project.layers.firstWhere(
            (layer) => layer.id == layerId)).name;
          assignedUnit = (widget.project.units.firstWhere(
            (unit) => unit.id == unitId)).name;
        }
      })
    );

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
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Change Layer Assignment:")
                  ),
                  DropdownButtonFormField(
                    key: dropdownStateLayer,
                    initialValue: assignedLayer,
                    items: layerNames.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        assignedLayer = value!;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Change Unit Assignment:")
                  ),
                  DropdownButtonFormField(
                    key: dropdownStateUnit,
                    initialValue: assignedUnit,
                    items: unitNames.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        assignedUnit = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Submit Assignment"),
              // Access project controller and add new project before navigating
              // to project dashboard.
              onPressed: () async {
                formKey.currentState!.save();
                String layerId = (widget.project.layers.firstWhere(
                  (layer) => layer.name == assignedLayer)).id;
                String unitId = (widget.project.units.firstWhere(
                  (unit) => unit.name == assignedUnit)).id;

                widget.project.assignData(layerId, unitId, dataId);

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
  /// Deletes the given data spec from the project and updates what is 
  /// displayed.
  void deleteData(String dataId) async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Are you sure you want to remove this data file?")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                await widget.project.removePxrfData(dataId);
                setState(() => widget.project.pxrfData);
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

  @override
  Widget build(BuildContext context) 
  {
    List<api.PxrfDataSpec> data = widget.project.pxrfData;
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
              "Data Specs", 
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
            onPressed: () => {},
            child: Text("Upload data via AirDroid")
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => loadCsv(),
            child: Text("Upload data from local files")
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: ListView.builder(
            itemCount: data.length, 
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
                          data[index].fileName,
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Number of points: "
                            "${data[index].numPoints}",
                          style: TextStyle(fontSize: 15)
                        ),
                        Text(
                          "Size: "
                            "${data[index].size}",
                          style: TextStyle(fontSize: 15)
                        ),
                        Text(
                          "Date Created: "
                            "${data[index].createdAt}",
                          style: TextStyle(fontSize: 15)
                        ),
                        Text(
                          "Last Updated: "
                            "${data[index].lastUpdated}",
                          style: TextStyle(fontSize: 15)
                        ),
                        // Button which navigates to the data view page for the
                        // selected file.
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute<void>(
                                  builder: (context) 
                                    => data_file.DataView(
                                      project: widget.project,
                                      dataSpec: data[index],
                                    )
                                )
                              );
                            },
                            child: Text("View Data File")
                          ),
                        ),
                        widget.project.layers.isEmpty || 
                        widget.project.units.isEmpty
                        ?
                        Center(child: 
                          Text("Add layers and units to the project to be able "
                            "to assign data specs!"
                          )
                        )
                        :
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () => modifyData(data[index].id),
                            child: Text("Assign Layers/Units"),
                          ),
                        ), 
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () => deleteData(data[index].id),
                            child: Text("Delete Data File"),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ]
    ));
  }
}
