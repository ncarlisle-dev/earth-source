import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'data_file.dart' as data_file;
import 'data_upload.dart';

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
  void modifyData(String dataId) async
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    /*showDialog(
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
                      labelText: 'Top-left X Coordinate:'
                    ),
                    initialValue: "${unitCorners[0].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[0].x) 
                      {
                        unitCorners[0].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-left Y Coordinate:'
                    ),
                    initialValue: "${unitCorners[0].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[0].y) 
                      {
                        unitCorners[0].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // top right corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right X Coordinate:'
                    ),
                    initialValue: "${unitCorners[1].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[1].x) 
                      {
                        unitCorners[1].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Top-right Y Coordinate:'
                    ),
                    initialValue: "${unitCorners[1].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[1].y) 
                      {
                        unitCorners[1].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // bottom left corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left X Coordinate:'
                    ),
                    initialValue: "${unitCorners[2].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[2].x) 
                      {
                        unitCorners[2].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-left Y Coordinate:'
                    ),
                    initialValue: "${unitCorners[2].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[2].y) 
                      {
                        unitCorners[2].y = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),

                  // bottom right corner
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right X Coordinate:'
                    ),
                    initialValue: "${unitCorners[3].x}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[3].x) 
                      {
                        unitCorners[3].x = double.parse(value);
                        positioningChanged = true;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Bottom-right Y Coordinate:'
                    ),
                    initialValue: "${unitCorners[3].y}",
                    onSaved: (value) {
                      if (double.parse(value!) != unitCorners[3].y) 
                      {
                        unitCorners[3].y = double.parse(value);
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
                List<({double latitude, double longitude})> corners = 
                  unitCorners.map((coord) => (
                    latitude: coord_converter.DDCoordinates
                      .fromUTM(coord)
                      .latitude, 
                    longitude: coord_converter.DDCoordinates
                      .fromUTM(coord)
                      .longitude,
                  )).toList();

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
                    corners: corners,
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
    );*/
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
            child: const Icon(Icons.add)
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
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () => modifyData(data[index].id),
                            child: Text("Modify Data Assignments"),
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
