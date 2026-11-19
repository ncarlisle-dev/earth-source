import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io' as io;

import '../../api/api.dart' as api;
import 'data_file.dart' as data_file;
import '../connections_page.dart';
import '../project_dashboard.dart';

/// A stateful widget for the project data spec page, which takes the id for 
/// the current project as a required field.
class DataPage extends StatefulWidget 
{
  const DataPage({super.key, required this.project});

  /// The id of the current project.
  final api.Project project;

  @override
  State<DataPage> createState() => _DataPageState();
}

/// The mutable state of the project data spec page.
class _DataPageState extends State<DataPage> 
{
  /// Id of a unit assigned to a given data spec.
  String unitAssignment = "";
  /// Id of a layer assigned to a given data spec.
  String layerAssignment = "";

  /// Marks whether a data file is currently loading.
  bool loading = false;
  /// Marks whether a data file failed to upload.
  bool uploadFailed = false;

  /// Loads a data file from the local file system and encodes it as a base 64
  /// string, taking in a given name and description for the file as arguments.
  Future<void> loadCsv(String dataName, String dataDescription) async {
    setState(() => loading = true);
    setState(() => uploadFailed = false);

    file_picker.PlatformFile? file = await file_picker.FilePicker.pickFile(
      type: file_picker.FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (file != null) {
      final filePath = file.path!;
      io.File imageFile = io.File(filePath);
      String fileString = await imageFile.readAsString();

      // Set name of file to the filepath if no name was provided.
      if (dataName == "") dataName = filePath;

      // Add encoded file to the database and update project on the frontend.
      await widget.project.addPxrfData(fileString, dataName, dataDescription);
      setState(() => widget.project.pxrfData);
      setState(() => loading = false);
    }
    // If file failed to upload, set uploadFailed to true to display a message
    // to the user.
    else {
      setState(() => uploadFailed = true);
    }
  }

  /// Allows the user to set a name and description for a data spec and upload
  /// a file from their local system.
  void addFile()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String dataName = "";
    String dataDescription = "";

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
                    decoration: InputDecoration(
                      labelText: 'Enter file name:'
                    ),
                    onSaved: (value) async {
                      dataName = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter file description:'
                    ),
                    onSaved: (value) async {
                      dataDescription = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Upload File"),
              onPressed: () async {
                formKey.currentState!.save();
                loadCsv(dataName, dataDescription);
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

  /// Allows the user to assign a data spec to a layer and unit.
  void assignData(String dataId) async
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final dropdownStateLayer = GlobalKey<FormFieldState>();
    final dropdownStateUnit = GlobalKey<FormFieldState>();

    // Obtain names of all the layers and units the project currently has.
    List<String> layerNames = [];
    List<String> unitNames = [];

    for (api.Layer layer in widget.project.layers) {
      layerNames.add(layer.name);
    }

    for (api.Unit unit in widget.project.units) {
      unitNames.add(unit.name);
    }

    // Check if the project lacks either layers or units.
    if (layerNames.isEmpty || unitNames.isEmpty)
    {
      // If so, let the user know that they cannot currently assign data until
      // their project has at least one layer and one unit.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Project must contain at least one layer and one unit before "
                "data can be assigned to a location."
              )
            ),
            actions: [
              ElevatedButton(
                child: const Text("Return to data specs page"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]
          );
        }
      );
    }
    else {
      String assignedLayer = layerNames[0];
      String assignedUnit = unitNames[0];

      // If the data spec has already been assigned to a layer and unit, find
      // that assignment to set the initial value of the dropdown menu.
      // (Otherwise, the initial value will be the first layer/unit by default.)
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
                onPressed: () async {
                  formKey.currentState!.save();

                  // Get the id of the layer and unit corresponding to the 
                  // options the user selected.
                  String layerId = (widget.project.layers.firstWhere(
                    (layer) => layer.name == assignedLayer)).id;
                  String unitId = (widget.project.units.firstWhere(
                    (unit) => unit.name == assignedUnit)).id;

                  // Assign data on the backend and set dataAssignments on the
                  // frontend.
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
  }

  /// Unassigns the given data spec if it is already assigned to a layer/unit -
  /// if not, notifies the user.
  void unassignData(String dataId) async
  {
    String assignedUnitId = "";
    String assignedLayerId = "";

    // Attempt to find the id of the layer and unit the data spec is currently
    // assigned to.
    widget.project.dataAssignments.forEach((layerId, unitAssignment) 
    {
      unitAssignment.forEach((unitId, dataSpecId)
      {
        if (dataSpecId == dataId)
        {
          assignedUnitId = unitId;
          assignedLayerId = layerId;
        }
      });
    });

    // If the data spec is not currently assigned to anything, notify the user.
    if (assignedUnitId == "" || assignedLayerId == "")
    {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "This data spec is currently not assigned to any layers or "
                "units."
              )
            ),
            actions: [
              ElevatedButton(
                child: const Text("Return to data specs page"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]
          );
        }
      );
    }

    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Are you sure you want to unassign this data spec? You "
                "will not be able to run predictions on this data until it is "
                "assigned to a layer and a unit."
              )
            ),
            actions: [
              ElevatedButton(
                child: const Text("Confirm Unassignment"),
                onPressed: () async {
                  await widget.project.unassignData(
                    assignedLayerId, 
                    assignedUnitId, 
                    dataId
                  );

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
  }

  /// Displays a form filled in with the fields for the corresponding spec that
  /// the user can choose to edit, registers which if any of the fields have 
  /// been changed, and updates information for the data spec accordingly.
  void editData(api.DataSpec dataSpec)
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool nameChanged = false;
    bool descriptionChanged = false;
    
    String dataName = dataSpec.fileName;
    String dataDescription = dataSpec.description;

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
                      labelText: "Data File Name:",
                    ),
                    initialValue: dataSpec.fileName,
                    onSaved: (value) async {
                      if (value != dataSpec.fileName)
                      {
                        dataName = value!;
                        nameChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Data File Description:",
                    ),
                    initialValue: dataSpec.description,
                    onSaved: (value) async {
                      if (value != dataSpec.description)
                      {
                        dataDescription = value!;
                        descriptionChanged = true;
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

              onPressed: () async {
                formKey.currentState!.save();
    
                // Check to see which, if any, of the fields has been changed
                // by the user and make updates accordingly.
                if (nameChanged || descriptionChanged) {
                  await widget.project.updatePxrfData(
                    dataSpec.id, 
                    fileName: dataName,
                    description: dataDescription,
                  );
                }

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
    return Material(child: Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 16.0, 
            horizontal: 20.0
          ),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => ProjectDashboard(project: widget.project),
            )),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
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
                padding: EdgeInsetsGeometry.only(top: 30.0),
                child: SizedBox(
                  height: 75,
                  child: Row(
                    crossAxisAlignment: .center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(
                          vertical: 16.0, 
                          horizontal: 20.0
                        ),
                        child: FloatingActionButton(
                          elevation: 0,
                          backgroundColor: Color.fromARGB(255, 84, 122, 149),
                          onPressed: () => addFile(),
                          child: Icon(
                            Icons.file_upload, 
                            color: Color.fromARGB(255, 232, 237, 242)
                          ),
                        )
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(
                          vertical: 16.0, 
                        ),
                        child: FloatingActionButton(
                          elevation: 0,
                          backgroundColor: Color.fromARGB(255, 84, 122, 149),
                          onPressed: () => Navigator.push(
                            context, 
                            MaterialPageRoute<void>(builder: (context) => 
                              ConnectionsPage(project: widget.project),
                            )
                          ),
                          child: Image.asset(
                            "assets/AirDroid_Icon.png", 
                            height: 40
                          ),
                        )
                      ),
                    ],
                  )
                )
              ),
            ],
          )
        ),
        loading
        ?
          Center(child: Text("Loading file . . ."))
        :
          Center(),
        uploadFailed
        ?
          Center(child: Text("File failed to upload!"))
        :
          Center(),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width, 
            height: MediaQuery.of(context).size.height - 300,
            margin: const EdgeInsets.only(
              left: 15.0, 
              right: 15.0, 
              bottom: 15.0
            ),
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
                                'Size (Bytes)', 
                                style: TextStyle(fontStyle: .italic)
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                'Number of Points', 
                                style: TextStyle(fontStyle: .italic)
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                'Assigned Layer', 
                                style: TextStyle(fontStyle: .italic)
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                'Assigned Unit', 
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
                        widget.project.pxrfData.length,
                        (int index) => DataRow(
                          cells: <DataCell>[
                          DataCell(Text(
                            widget.project.pxrfData[index].fileName
                          )),
                          DataCell(
                            Text(
                              widget.project.pxrfData[index].createdAt
                              .toString()
                            )
                          ),
                          DataCell(
                            Text(
                              widget.project.pxrfData[index].lastUpdated
                              .toString()
                            )
                          ),
                          DataCell(
                            Text(
                              widget.project.pxrfData[index].description, 
                              maxLines: 1,
                              overflow: .ellipsis
                            )
                          ),
                          DataCell(
                            Text(
                              widget.project.pxrfData[index].size.toString(), 
                            )
                          ),
                          DataCell(
                            Text(
                              widget.project.pxrfData[index].numPoints.
                              toString(), 
                            )
                          ),
                          DataCell(
                            Text(
                              getAssignments(
                                widget.project.pxrfData[index].id
                              ).$1, 
                            )
                          ),
                          DataCell(
                            Text(
                              getAssignments(
                                widget.project.pxrfData[index].id
                              ).$2, 
                            )
                          ),
                          DataCell(IconButton(
                            onPressed: () => 
                              Navigator.push(
                                context, MaterialPageRoute<void>(builder: 
                                  (context) => data_file.DataView( 
                                    project: widget.project,
                                    dataSpec: widget.project.pxrfData[index]
                                  ),
                                )
                              ),
                            icon: Icon(Icons.file_open),
                          )),
                          DataCell(IconButton(
                            onPressed: () => assignData(
                              widget.project.pxrfData[index].id
                            ),
                            icon: Icon(Icons.add),
                          )),
                           DataCell(IconButton(
                            onPressed: () => unassignData(
                              widget.project.pxrfData[index].id
                            ),
                            icon: Icon(Icons.block),
                          )),
                          DataCell(IconButton(
                            onPressed: () => editData(
                              widget.project.pxrfData[index]
                            ),
                            icon: Icon(Icons.edit),
                          )),
                          DataCell(IconButton(
                            onPressed: () => 
                              deleteData(widget.project.pxrfData[index].id),
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
