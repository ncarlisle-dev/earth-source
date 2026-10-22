import 'package:flutter/material.dart';
import 'prediction_view.dart';
import '../../api/api.dart' as api;

/// A page for generating predictions that takes in the current project Id as
/// a required field.
class PredictionGeneration extends StatefulWidget {
  const PredictionGeneration({super.key, required this.projectId});

  /// Id of the current project.
  final String projectId;

  @override
  State<PredictionGeneration> createState() => PredictionGenerationState();
}

/// The mutable state of the prediction generation page, which tracks the name
/// and description of the created job as well as the name of the assigned 
/// layer.
class PredictionGenerationState extends State<PredictionGeneration>
{
  /// Given name of the job.
  String? jobName;
  /// Given description of the job.
  String? jobDescription;
  /// Given name of the corresponding layer.
  String? layerName;
  /// Id of the corresponding layer.
  String? layerId;

  /// Form key for the prediction generation form.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Obtains the names of all the layers within the current project that have
  /// data attached.
  Future<List<String>> getLayerNames() async
  {
    List<String> layerNames = [];
    api.ProjectController projectController = 
      await api.ProjectController.getInstance();
    int projectIndex = projectController.userProjects.indexWhere(
      (project) => project.id == widget.projectId);
    // Check to make sure that a layer is only displayed in the dropdown if it
    // has assigned data.
    for (var layer in projectController.userProjects[projectIndex].layers) {
      if (projectController.userProjects[projectIndex].dataAssignments.
      containsKey(layer.id)) {
        layerNames.add(layer.name);
      }
    }
    return layerNames;
  }

  @override
  Widget build(BuildContext context)
  {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(hintText: 'Prediction Name'),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the prediction name.';
                }
                return null;
              },
              onSaved: (value) {
                setState(() {
                  jobName = value;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Prediction Description'
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the prediction description.';
                }
                return null;
              },
              onSaved: (value) {
                setState(() {
                  jobDescription = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Select layer:")
            ),
            FutureBuilder(
                future: getLayerNames(),
                builder: (
                  BuildContext ctx, 
                  AsyncSnapshot<List> snapshot
                ) 
                => snapshot.hasData
              ?
              DropdownButton(
                value: snapshot.data![0] as String,
                icon: const Icon(Icons.keyboard_arrow_down),
                items:
                    (snapshot.data! as List<String>).
                      map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>
                      (value: value, child: Text(value));
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    layerName = newValue!;
                  });
                },
              )
              :
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Project layers cannot currently be accessed.")
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                // Note that I tried to make the below its own function so
                // there wouldn't be so much indentation here, but it gave me
                // issues due to not having access to the context passed in
                // to the overridden build function.
                onPressed: () async {
                  _formKey.currentState!.save();
                  api.ProjectController projectController = 
                    await api.ProjectController.getInstance();
                  int projectIndex = projectController.userProjects.indexWhere(
                    (project) => project.id == widget.projectId);

                  // Find the id of the layer corresponding to the layer name
                  // selected by the user.
                  String? layerId;
                  for (var layer in projectController.
                  userProjects[projectIndex].layers) {
                    if (layer.name == layerName) {
                      layerId = layer.id;
                    }
                  }

                  // Create a prediction job with the appropriate fields
                  // assigned.
                  api.PredictionJob predictionJob = await projectController
                    .userProjects[projectIndex]
                    .runPredictionJob(
                      jobName!,
                      jobDescription!,
                      layerId!,
                      null
                    );

                  // Navigate to the prediction view page, passing along the
                  // created job.
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (context) => PredictionView(
                        projectId: widget.projectId, 
                        predictionJob: predictionJob
                      ),
                    ));
                  }
                },
                child: Text("Generate Predictions"),
              )
            ),
          ]
        )
      )
    );
  }
}