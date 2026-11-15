import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'map_page.dart';
import 'dart:io' as io; 
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;

/// A stateful widget for the page for an individual layer, with the 
/// corresponding project and layer as a required field.
class LayerPage extends StatefulWidget 
{
  const LayerPage({super.key, required this.project, required this.layer});

  /// The current project being viewed.
  final api.Project project;
  /// The current layer being viewed.
  final api.Layer layer;

  @override
  State<LayerPage> createState() => _LayerPageState();
}

/// The mutable state of the individual layer page.
class _LayerPageState extends State<LayerPage> 
{
  /// Changed description of the layer.
  String? layerDescription;
  /// Changed name of the layer.
  String? layerName;
  /// Contents of the changed image for the layer.
  String? imageContents;

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// name for the layer.
  void changeName()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                      labelText: "Enter new name:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value for the new name';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        layerName = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                formKey.currentState!.save();
                await widget.project.updateLayer(
                  widget.layer.id, 
                  name: layerName!
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// description for the layer.
  void changeDescription()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                      labelText: "Enter new description:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value for the new description';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        layerDescription = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                formKey.currentState!.save();
                await widget.project.updateLayer(
                  widget.layer.id, 
                  description: layerDescription!
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

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

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// image for the layer.
  void changeImage()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
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
                  Text("Warning: this will delete your previous image!"),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter new layer image name:",
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
                      child: Text("Upload new image"),
                    )
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text("Save Changes"),
              onPressed: () async {
                formKey.currentState!.save();

                await widget.project.removeLayerImage(
                  widget.layer.id
                );

                // Upload layer image encoded as a string to the database.
                await widget.project.uploadLayerImage(
                  widget.layer.id,
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

  /// Returns a formatted string containing all the assignments for a layer for
  /// display.
  String formatAssignments()
  {
    String assignments = "";
    int specsAssigned = 0;

    // Check if no units have been created yet.
    if (widget.project.dataAssignments[widget.layer.id]! == {})
    {
      return ("No data assigned to this layer as of yet!");
    }

    widget.project.dataAssignments[widget.layer.id]!.forEach((unitId, dataId) {
      api.Unit unit = 
        widget.project.units.firstWhere((unit) => unit.id == unitId);
      // If data has been assigned to the current unit, add it to the 
      // assignments string.
      if (dataId != null)
      {
        specsAssigned ++;
        api.DataSpec dataSpec = 
        widget.project.pxrfData.firstWhere((dataSpec) => dataSpec.id == dataId);
        assignments += "${unit.name} - ${dataSpec.fileName},";
      }
    });

    // Check if no data has been assigned to any of the units in the layer.
    if (specsAssigned == 0)
    {
      return ("No data assigned to this layer as of yet!");
    }

    return assignments.substring(0, assignments.length - 1);
  }

  /// Returns a list of all prediction jobs associated with the current layer.
  List<api.PredictionJob> getJobs()
  {
    List<api.PredictionJob> jobs = [];
    for (var job in widget.project.predictions)
    {
      if (job.layerId == widget.layer.id) {
        jobs.add(job);
      }
    }
    return jobs;
  }

  @override
  Widget build(BuildContext context) 
  {
    String assignments = formatAssignments();
    List<api.PredictionJob> jobs = getJobs();

    return Material(child: ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 16.0, 
            horizontal: 20.0
          ),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => MapPage(index: 1, project: widget.project),
            )),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              widget.layer.name, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              )
            )
          ),
        ), 
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 20.0),
          child: Center(
            child: Text(
              widget.layer.description,
              style: TextStyle(fontSize: 15)
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.only(
            left: 20.0, 
            right: 20.0, 
            top: 5.0, 
            bottom: 20.0
          ),
          child: Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15, 
                  color: Color.fromARGB(255, 44, 57, 71)
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Assigned Data: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: assignments),
                ]
              )
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 50.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
              onPressed: changeName,
              child: ButtonContent(icon: Icons.edit, text: "Change Name"),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 50.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
              onPressed: changeDescription,
              child: ButtonContent(
                icon: Icons.edit, 
                text: "Change Description"
              ),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 50.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
              onPressed: changeImage,
              child: ButtonContent(
                icon: Icons.edit, 
                text: "Change Image"
              ),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Prediction Jobs", 
              style: TextTheme.of(context).headlineMedium?.copyWith(
                fontWeight: FontWeight.bold
              )
            )
          ),
        ), 
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width, // match the window width
            height: MediaQuery.of(context).size.height - 300,
            margin: const EdgeInsets.symmetric(horizontal: 15.0),
            child:
            jobs.isEmpty
            ?
              Center(child: Text(
                "No prediction jobs have been run on this layer yet!"
              ))
            :
              ListView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: jobs.length, 
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    margin: EdgeInsetsGeometry.only(
                      top: 20.0, 
                      left: 20.0, 
                      right: 20.0
                    ),
                    color: Color.fromARGB(255, 232, 237, 242),
                    surfaceTintColor: Color.fromARGB(255, 84, 122, 149),
                    child: Padding(
                      padding: const .all(10.0),
                      child: SizedBox(
                        height: 120, 
                        child: JobFields(
                          name: jobs[index].name, 
                          description: jobs[index].description, 
                          status: jobs[index].status, 
                          timeCreated: jobs[index].createdAt.toString(), 
                          timeUpdated: jobs[index].lastUpdated.toString(),
                        )
                      )
                    )
                  );
                }
              ),
            )
          ),
        ]
      )
    );
  }
}

/// The content of a button, containing an icon and text phrase aligned on a 
/// row.
class ButtonContent extends StatelessWidget
{
  const ButtonContent({super.key, required this.icon, required this.text});

  /// The icon contained by the button.
  final IconData icon;
  /// The text contained by the button.
  final String text;

  @override
  Widget build(BuildContext context) 
  {
    return Padding(
      padding: const .symmetric(vertical: 10.0),
      child: SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: .start,
          children: <Widget>[
            Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 25.0),
                child: Center(child: Icon(icon, size: 30))),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                child: Center(child: Text(
                  text, 
                  style: TextTheme.of(context).bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: Color.fromARGB(255, 194, 165, 109)
                  )
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget containing the text-based fields for a job.
class JobFields extends StatelessWidget {
  const JobFields({
    super.key,
    required this.name,
    required this.description,
    required this.status,
    required this.timeCreated,
    required this.timeUpdated,
  });

  /// Name of the job.
  final String name;
  /// Description of the job.
  final String description;
  /// Status of the job.
  final api.JobStatus status;
  /// Time at which the job was created.
  final String timeCreated;
  /// Time at which the job was last updated.
  final String timeUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: <Widget>[
        Text(
          name,
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontWeight: .bold, fontSize: 22.0),
        ),
        const Padding(padding: .only(bottom: 2.0)),
        Expanded(
          child: Text(
            description,
            maxLines: 1,
            overflow: .ellipsis,
            style: const TextStyle(
              fontSize: 15.0, 
              color: Color.fromARGB(255, 84, 122, 149)
            ),
          ),
        ),
        Text(
          "Status: ${api.statusList[status.index]}",
          maxLines: 1,
          overflow: .ellipsis,
          style: TextStyle(
            fontSize: 15.0, 
            color: api.statusColors[status.index]
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