import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io' as io;

import '../../api/api.dart' as api;
import 'data_file.dart' as data_file;
import '../connections_page.dart';
import '../project_dashboard.dart';

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
      await widget.project.addPxrfData(fileString, filePath, "");
      setState(() => widget.project.pxrfData);
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
                    child: Text("Set Layer Assignment:")
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
                    child: Text("Set Unit Assignment:")
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

                await widget.project.assignData(layerId, unitId, dataId);
                setState(() => widget.project.dataAssignments);

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

  /// Given a data spec id, searches through data assignments to find the name
  /// of the layer and unit assigned to that data spec and returns both strings
  /// if found, empty strings if not.
  (String, String) getAssignments(String dataId)
  {
    String layerName = "";
    String unitName = "";

    widget.project.dataAssignments.forEach((layerId, unitAssignment) {
      unitAssignment.forEach((unitId, dataSpecId)
      {
        if (dataSpecId == dataId)
        {
          unitName =  widget.project.units.firstWhere(
            (unit) => unit.id == unitId).name;
          layerName =  widget.project.layers.firstWhere(
            (layer) => layer.id == layerId).name;
        }
      }); 
    });

    return (layerName, unitName);
  }

  /// Vertical and horizontal scroll controllers for the units data table.
  final verticalScrollController = ScrollController();
  final horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) 
  {
    List<api.PxrfDataSpec> data = widget.project.pxrfData;
    return Material(child: Column(
      children: [
        Padding (
          padding: EdgeInsetsGeometry.symmetric(vertical: 20.0),
          child: Stack(
            alignment: AlignmentGeometry.topRight,
            children: <Widget>[
              Center(child: Text(
                "Data Specs", 
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
                  onPressed: () => (),
                )
              ),
            ],
          )
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width, 
            height: MediaQuery.of(context).size.height - 300,
            margin: const EdgeInsets.all(15.0),
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true, 
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
                              child: Text(
                                '', 
                                style: TextStyle(fontStyle: .italic)
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                '', 
                                style: TextStyle(fontStyle: .italic)
                              ),
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
                          DataCell(Text(
                            calculateArea(
                              widget.project.units[index].corners
                            ).toString()
                          )),
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
        )
      )]
    ));
  }
}
