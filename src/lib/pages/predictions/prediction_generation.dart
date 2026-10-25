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
  /// Id of the corresponding layer.
  String? layerId;

  /// Form key for the prediction generation form.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Obtains the names of all the layers within the current project that have
  /// data attached.
  Future<List<api.Layer>> getLayersWithAssignments() async
  {
    final List<api.Layer> layers = [];
    final projectController = await api.ProjectController.getInstance();
    final project = await projectController.getProjectById(widget.projectId);

    // Check to make sure that a layer is only displayed in the dropdown if it
    // has assigned data.
    for (var layer in project.layers) {
      if (project.dataAssignments.containsKey(layer.id)) {
        layers.add(layer);
      }
    }

    return layers;
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      child: Padding(
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
                  future: getLayersWithAssignments(),
                  builder: (
                    BuildContext ctx, 
                    AsyncSnapshot<List<api.Layer>> snapshot
                  ) 
                    => snapshot.hasData && snapshot.data != null
                      ? 
                        snapshot.data!.isEmpty
                        ?
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            "No layers have been created yet!"
                          ),
                        )
                        : DropdownButton(
                            value: snapshot.data![0].id,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: snapshot.data!
                              .map<DropdownMenuItem<String>>((layer) {
                                return DropdownMenuItem<String>(
                                  value: layer.id,
                                  child: Text(layer.name)
                                );
                              })
                              .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                layerId = newValue!;
                              });
                            },
                          )
                      : Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            "Project layers cannot currently be accessed."
                          ),
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
                    final projectController = await api.ProjectController
                      .getInstance();
                    
                    final project = await projectController
                      .getProjectById(widget.projectId);

                    // Create a prediction job with the appropriate fields
                    // assigned.
                    final predictionJob = await project.runPredictionJob(
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
                          predictionJob: predictionJob,
                        ),
                      ));
                    }
                  },
                  child: Text("Generate Predictions"),
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  // Note that I tried to make the below its own function so
                  // there wouldn't be so much indentation here, but it gave me
                  // issues due to not having access to the context passed in
                  // to the overridden build function.
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                )
              ),
            ]
          )
        )
      ),
    );
  }
}