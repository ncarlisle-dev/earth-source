import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_generation.dart';
import 'prediction_view.dart';
import '../project_dashboard.dart';

const possibleJobStatuses = api.JobStatus.values;

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
  bool isJobRunning = false;
  bool hasJobFailed = false;

  String currentPrediction = "";
  String jobFailedMessage = "";

  Future<void> runJob(
    String jobName, 
    String jobDescription, 
    String layerId
  ) async
  {
    print(jobName);

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

  void addPrediction() async
  {
    setState(() => hasJobFailed = false);

    String jobName = "";
    String jobDescription = "";
    String layerId;

    List<api.Layer> layersWithData = [];

    // Attempt to find the id of the layer and unit the data spec is currently
    // assigned to.
    widget.project.dataAssignments.forEach((layerId, unitAssignment) 
    {
      unitAssignment.forEach((unitId, dataSpecId)
      {
        if (dataSpecId != null)
        {
          api.Layer currentLayer = widget.project.layers.firstWhere((layer) => layer.id == layerId);
          if (!layersWithData.contains(currentLayer))
          {
            layersWithData.add(currentLayer);
          }
        }
      });
    });

    // If the data spec is not currently assigned to anything, notify the user.
    if (widget.project.layers.isEmpty || widget.project.units.isEmpty || layersWithData.isEmpty)
    {
      String userDialogue;

      if (widget.project.layers.isEmpty) {
        userDialogue = "Project must have at least one layer before predictions can be run!";
      }
      else if (widget.project.units.isEmpty) {
        userDialogue = "Project must have at least one unit before predictions can be run!";
      }
      else {
        userDialogue = "Project must have at least one data file assigned to a layer and unit before predictions can be run!";
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
                decoration: const InputDecoration(hintText: 'Prediction Name'),
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
            ])),
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
        isJobRunning
        ?
          Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 10.0), child: Center(child: Text("Running prediction job $currentPrediction - prediction will appear below when ready!")))
        :
          Center(),
        hasJobFailed
        ?
          Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 10.0), child: Center(child: Text("Error: prediction job $currentPrediction failed to run.")))
        :
          Center(),
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
                    predictionJob: widget.project.predictions[index],)
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
                    child: Padding(
                      padding: const .all(10.0),
                      child: SizedBox(
                        height: 140, 
                        child: JobFields(
                  name: widget.project.predictions[index].name,
                  description: widget.project.predictions[index].description,
                  timeCreated: 
                    widget.project.predictions[index].createdAt.toString(),
                  timeUpdated: 
                    widget.project.predictions[index].lastUpdated.toString(),
                  status: widget.project.predictions[index].status,
                  layerName: widget.project.layers.firstWhere((layer)
                   => layer.id == widget.project.predictions[index].layerId).name
                  ),
                )
            )));
          }
        ),))
      ],
    ));
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
                style: TextStyle(fontSize: 15.0, color: Color.fromARGB(255, 44, 57, 71))
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
      ],
    );
  }
}