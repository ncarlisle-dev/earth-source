import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_view.dart';
import '../project_dashboard.dart';

/// A stateful widget for the project predictions page, which takes the id for 
/// the current project as a required field.
class PredictionsPage extends StatefulWidget 
{
  const PredictionsPage({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the project predictions page.
class _PredictionsPageState extends State<PredictionsPage> 
{
  /// Tracks whether a job is currently running but has not yet been created.
  bool isJobRunning = false;
  /// Tracks whether a job has failed to be created.
  bool hasJobFailed = false;

  /// Stores the name of the current prediction for display.
  String currentPrediction = "";

  /// Attempts to run a prediction job when given a name, description, and ID
  /// for the corresponding job layer.
  Future<void> runJob(
    String jobName, 
    String jobDescription, 
    String layerId
  ) async
  {
    setState(() => currentPrediction = jobName);
    setState(() => isJobRunning = true);

    try 
    {
      await widget.project.runPredictionJob(
        jobName,
        jobDescription,
        layerId,
        null
      );
    }
    catch (error) {
      print(error);
      setState(() {
        hasJobFailed = true; 
        isJobRunning = false;
        currentPrediction = jobName;
    });
    }

    setState(() { 
      widget.project.predictions;
      isJobRunning = false;
      currentPrediction = jobName;
  });
  }

  /// Displays a modal that allows the user to generate a prediction and select
  /// a layer to run the prediction over if assigned data is available to run
  /// predictions on - if not, displays an appropriate message to the user and
  /// takes them back to the predictions page.
  void addPrediction() async
  {
    setState(() => hasJobFailed = false);

    String jobName = "";
    String jobDescription = "";
    String layerId;

    List<api.Layer> layersWithData = [];

    // Find all the layers in the project that currently have data assigned to
    // them and add them to a list for display.
    widget.project.dataAssignments.forEach((layerId, unitAssignment) 
    {
      unitAssignment.forEach((unitId, dataSpecId)
      {
        if (dataSpecId != null)
        {
          api.Layer currentLayer = widget.project.layers.firstWhere((layer) => 
            layer.id == layerId);
          if (!layersWithData.contains(currentLayer))
          {
            layersWithData.add(currentLayer);
          }
        }
      });
    });

    // Check if either the project lacks layers/units or no data has been 
    // assigned to any layers and display appropriate user message.
    if (widget.project.layers.isEmpty || widget.project.units.isEmpty || 
    layersWithData.isEmpty)
    {
      String userDialogue;

      if (widget.project.layers.isEmpty) {
        userDialogue = "Project must have at least one layer before predictions"
        " can be run!";
      }
      else if (widget.project.units.isEmpty) {
        userDialogue = "Project must have at least one unit before predictions "
        "can be run!";
      }
      else {
        userDialogue = "Project must have at least one data file assigned to a "
        "layer and unit before predictions can be run!";
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(userDialogue)
            ),
            actions: [
              ElevatedButton(
                child: const Text("Return to predictions page"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]
          );
        }
      );
    }

    else {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();

      // Set starting layer ID to first layer found with assigned data.
      layerId = layersWithData[0].id;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            content: Form(
              key: formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Prediction Name'
                    ),
                    validator: (String? value) {
                    if (value == null || value.isEmpty) {
                        return 'Please enter the prediction name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        jobName = value!;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Prediction Description'
                    ),
                    onSaved: (value) {
                      setState(() {
                        jobDescription = value!;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text("Select layer:")
                  ),
                  DropdownButton(
                    value: layerId,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: layersWithData
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
                ]
              )
            ),
            actions: [
              ElevatedButton(
                child: const Text("Run Prediction Job"),
                onPressed: () async {
                  formKey.currentState!.save();
                  runJob(jobName, jobDescription, layerId);
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

  /// Displays a pop-up dialogue box that confirms if the user wants to delete
  /// their prediction, and if so, returns them to the main page.
  void deletePrediction(String predictionJobId) async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Are you sure you want to delete this prediction?")
          ),
          actions: [
            ElevatedButton(
              child: const Text("Confirm Deletion"),
              onPressed: () async {
                // Delete the corresponding prediction job.
                await widget.project.deletePredictionJob(predictionJobId);

                if (context.mounted) {
                  setState(() => widget.project.predictions);
                  Navigator.of(context).pop();
                }
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
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Predictions", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              )
            )
          ), //Icon
        ), 
        Padding(
          padding: EdgeInsetsGeometry.all(16.0),
          child: FloatingActionButton(
            onPressed: () => addPrediction(),
            child: const Icon(Icons.add)
          )
        ),
        !isJobRunning
        ?
          Center()
        :
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 10.0), 
            child: Center(
              child: Text(
                "Running prediction job $currentPrediction - prediction will "
                "appear below when ready!"
              )
            )
          ),
        !hasJobFailed
        ?
          Center()
        :
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 10.0), 
            child: Center(
              child: Text(
                "Error: prediction job $currentPrediction failed to run."
              )
            )
          ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width, // match the window width
            height: MediaQuery.of(context).size.height - 300,
            margin: const EdgeInsets.symmetric(horizontal: 15.0),
            child:
            widget.project.predictions.isEmpty
            ?
              Center(child: Text("No predictions running yet!"))
            :
              ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: widget.project.predictions.length, 
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute<void>(
                        builder: (context) => PredictionView(
                          project: widget.project, 
                          predictionJob: widget.project.predictions[index]
                        )
                      ));
                    },
                    child: Card(
                      margin: EdgeInsetsGeometry.only(
                        top: 20.0, 
                        left: 20.0, 
                        right: 20.0
                      ),
                      color: Color.fromARGB(255, 232, 237, 242),
                      surfaceTintColor: Color.fromARGB(255, 84, 122, 149),
                      child:Stack(
                        alignment: AlignmentGeometry.bottomRight,
                        children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child:
                       Padding(
                        padding: const .all(10.0),
                        child: SizedBox(
                          height: 176, 
                          child: JobFields(
                            name: widget.project.predictions[index].name,
                            description: 
                              widget.project.predictions[index].description,
                            timeCreated: 
                              widget.project.predictions[index].createdAt
                              .toString(),
                            timeUpdated: 
                              widget.project.predictions[index].lastUpdated
                              .toString(),
                            status: widget.project.predictions[index].status,
                            layerName: widget.project.layers.firstWhere(
                              (layer) => layer.id == 
                              widget.project.predictions[index].layerId).name
                          ),
                        )
                      ),),
                      Padding(
                            padding: EdgeInsetsGeometry.only(
                              top: 16.0, 
                              left: 20.0, 
                              right: 20.0,
                              bottom: 16.0,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.delete),
                              color: Color.fromARGB(255, 232, 237, 242),
                              style: IconButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                  255, 84, 122, 149
                                )
                              ),
                              onPressed: () => 
                                deletePrediction(widget.project.layers[index].id),
                              )
                          ),
                        ]
                      )
                    )
                  );
                }
              )
            )
          )
        ],
      )
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
    required this.layerName,
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
  /// Layer over which the job is run.
  final String layerName;

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
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Status: ",
                style: TextStyle(
                  fontSize: 15.0, 
                  color: Color.fromARGB(255, 44, 57, 71)
                )
              ),
              WidgetSpan(
                child: Icon(
                  Icons.circle, 
                  size: 16, 
                  color: api.statusColors[status.index]
                ),
              ),
            ],
          ),
        ),
        Text(
          "Created At: $timeCreated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Last Updated: $timeUpdated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Layer: $layerName",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(""),
        Text(""),
      ],
    );
  }
}