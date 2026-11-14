import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'project_settings.dart';
import 'predictions/predictions_page.dart';
import 'data/data_page.dart';
import 'map_page.dart';
import 'projects_page.dart';
import 'home_page.dart';
import 'dart:io' as io; 
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;

/// A stateful widget for the project dashboard page, with a given project
/// as a required field.
class LayerPage extends StatefulWidget 
{
  const LayerPage({super.key, required this.project, required this.layer});

  /// The current project being viewed.
  final api.Project project;

  final api.Layer layer;

  @override
  State<LayerPage> createState() => _LayerPageState();
}

/// The mutable state of the project dashboard page.
class _LayerPageState extends State<LayerPage> 
{
  /// Description of the project
  String? layerDescription;
  String? layerName;
  String? imageContents;

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// description for the project.
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
                await widget.project.updateLayer(widget.layer.id, name: layerName!);

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
  /// description for the project.
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
                await widget.project.updateLayer(widget.layer.id, description: layerDescription!);

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

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

  void changeImage()
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: loadImage,
                      child: Text("Upload new layer image (warning: this will delete your previous image!)"),
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
                  "unnamed image" // TODO: create an input for this
                );

                api.LayerImages layerImageController = 
                  await api.LayerImages.getInstance();

                layerImageController.addImage(widget.project.id, imageContents!);

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
    return Material(child: Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder:
                (context) => MapPage(project: widget.project),
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
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
              onPressed: changeName,
              child: ButtonContent(icon: Icons.edit, text: "Edit Name"),
            )
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
              onPressed: changeDescription,
              child: ButtonContent(
                icon: Icons.edit, 
                text: "Edit Description"
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
            height: 100.0,
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
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 5.0, 
            horizontal: 20.0
          ),
          child: SizedBox(
            height: 100.0,
            width: MediaQuery.of(context).size.width - 50,
            child: FloatingActionButton(
                onPressed: () => deleteLayer(widget.layer.id),
              child: ButtonContent(
                icon: Icons.delete, 
                text: "Delete Layer"
              ),
            )
          )
        ),
      ]
    ));
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
        height: 100,
        child: Row(
          crossAxisAlignment: .start,
          children: <Widget>[
            Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 25.0),
                child: Center(child: Icon(icon, size: 75))),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(20.0, 0.0, 2.0, 0.0),
                child: Center(child: Text(
                  text, 
                  style: TextTheme.of(context).headlineMedium?.copyWith(
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