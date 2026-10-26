import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import '../../api/api.dart' as api;
import '../home_page.dart';
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class PredictionView extends StatefulWidget {
  const PredictionView({
    super.key, 
    required this.projectId,
    required this.predictionJob
  });

  /// The id of the current project.
  final String projectId;
  /// The prediction job currently being displayed.
  final api.PredictionJob predictionJob;

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

/// The mutable state of the prediction view page.
class _PredictionViewState extends State<PredictionView> {
  /// List of job status strings corresponding to the JobStatus enum.
  static const List<String> jobStatusList = [
    "Starting", 
    "Running", 
    "Complete", 
    "Failed"
  ];

  /// Variable to store the updated name of the prediction, should the user
  /// change it.
  String changedName = "";
  /// Variable to store the updated description of the prediction, should the 
  /// user change it.
  String changedDescription = "";
  /// Tracks whether the predictions are currently being displayed as a map or
  /// as text.
  bool mapDisplay = true;
  /// Tracks whether the name of the prediction has been changed.
  bool isNameChanged = false;
  /// Tracks whether the description of a prediction has been changed.
  bool isDescriptionChanged = false;
  /// The job's layer. TODO: attach actual layer instance to the job
  api.Layer? jobLayer;

  String changedStatus = "";
  bool isStatusChanged = false;


  /// Displays a pop-up dialogue box that allows the user to set a new name for
  /// the prediction job and changes the name of the job within the appropriate
  /// project.
  void renameJob()
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
                        return 'Please enter a value for the new job name';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      // Find the appropriate project in the project controller
                      // and change the name of the corresponding prediction 
                      // job.
                      final projectController = await api.ProjectController
                        .getInstance();

                      final project = await projectController
                        .getProjectById(widget.projectId);

                      await project.setPredictionJobMetadata(
                        widget.predictionJob.id,
                        name: value!,
                      );

                      setState(() {
                        changedName = value;
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
              onPressed: () {
                formKey.currentState!.save();
                setState(() {
                  isNameChanged = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  /// Displays a pop-up dialogue box that allows the user to set a new 
  /// description for the prediction job and changes the description for the job
  /// within the appropriate project.
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
                      // Find the appropriate project in the project controller
                      // and change the description of the corresponding 
                      // prediction job.
                      final projectController = await api.ProjectController
                        .getInstance();

                      final project = await projectController
                        .getProjectById(widget.projectId);

                      await project.setPredictionJobMetadata(
                        widget.predictionJob.id,
                        description: value!,
                      );

                      setState(() {
                        changedDescription = value;
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
              onPressed: () {
                formKey.currentState!.save();
                setState(() {
                  isDescriptionChanged = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  /// Displays a pop-up dialogue box that confirms if the user wants to delete
  /// their prediction, and if so, returns them to the main page.
  void deletePrediction() async
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
                // Find the appropriate project in the project controller
                // and delete the corresponding prediction job.
                final projectController = await api.ProjectController
                  .getInstance();

                final project = await projectController
                  .getProjectById(widget.projectId);

                await project.deletePredictionJob(widget.predictionJob.id);

                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => const HomePage(),
                    ),
                  );
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

  /// Fetches the unit and data file assignments corresponding to the layer
  /// for the current prediction.
  Future<Map<String, String?>> getLayerAssignments() async
  {
    final projectController = await api.ProjectController.getInstance();
    final project = await projectController.getProjectById(widget.projectId);
    return project.dataAssignments[widget.predictionJob.layerId]!;
  }

  /// Loads both the image and the prediction results for display on the 
  /// prediction view page.
  Future<(List<coord_converter.UTMCoordinates>, List<double>, String)> 
    loadPredictionData() async
  {
    List<coord_converter.UTMCoordinates> predictionPoints = [];
    List<double> predictionValues = [];

    final projectController = await api.ProjectController.getInstance();
    final project = await projectController.getProjectById(widget.projectId);

    final List<List<double>> results = await widget.predictionJob.getResults(
      widget.projectId
    );

    final String imageContents = await project
      .getLayerImage(widget.predictionJob.layerId);

    if (results.isNotEmpty) {
      for (var i = 0; i < results.length; i++) {
        coord_converter.UTMCoordinates coords = coord_converter.UTMCoordinates(
          x: results[i][0], 
          y: results[i][1], 
          zoneNumber: project.utmZone,
          isSouthernHemisphere: project.isSouthernHemisphere
        );
        predictionPoints.add(coords);
        predictionValues.add(results[i][2]);
      }
    }

    return (predictionPoints, predictionValues, imageContents);
  }

  Future<void> _loadJobLayer() async {
    final controller = await api.ProjectController.getInstance();

    final project =
        await controller.getProjectById(widget.projectId);

    if (!mounted) return;

    setState(() {
      jobLayer = project.layers.singleWhere(
        (layer) => layer.id == widget.predictionJob.layerId,
      );
    });
  }

  Future<void> refreshPage() async {
    final controller = await api.ProjectController.getInstance();

    final project =
        await controller.getProjectById(widget.projectId);

    project.watchPredictionJobStatus(widget.predictionJob.id, callback);
  }

  void callback(api.JobStatus status) async {
    setState(() {
      isStatusChanged = true;
      changedStatus = jobStatusList[status.index];
      widget.predictionJob.setStatus(status);
    });
  }

  @override
  void initState() {
    super.initState();

    _loadJobLayer();

    refreshPage();
  }

  @override
  Widget build(BuildContext context) {
    String jobStatus = jobStatusList[widget.predictionJob.status.index];

    return Material(child: ListView(
      children: [
      Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: refreshPage,
            child: Icon(Icons.refresh),
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child:
            isNameChanged 
            ?
              Text(
                changedName, 
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.indigo
                )
              )
            :
              Text(
                widget.predictionJob.name, 
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.indigo
                )
              )
            )
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: 
            isDescriptionChanged
            ?
            Text("Description: $changedDescription")
            :
            Text("Description: ${widget.predictionJob.description}")
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: renameJob,
            child: Text("Rename Prediction"),
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: changeDescription,
            child: Text("Change Description"),
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: deletePrediction,
            child: Text("Delete Prediction"),
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Job Information", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.indigo
              )
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: 
            isStatusChanged ? Text("Job Status: $changedStatus")
            : Text("Job Status: $jobStatus")
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Date Created: ${widget.predictionJob.createdAt}"))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Layer: ${jobLayer != null ? jobLayer!.name : "Loading..."}"
            )
          )
        ), 
        FutureBuilder(
            future: getLayerAssignments(),
            builder: (BuildContext ctx, AsyncSnapshot<Map> snapshot) 
              => snapshot.hasData
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text("Layer Assignments: ${snapshot.data!}")
                    )
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text("Layer assignments could not be retrieved.")
                    )
                  )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: (() => setState(() {
              mapDisplay ? mapDisplay = false : mapDisplay = true;
            })),
            child: Text(
              mapDisplay 
              ? "Toggle text-formatted predictions" 
              : "Toggle map display"
            ),
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: FutureBuilder(
            future: loadPredictionData(),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<(
                List<coord_converter.UTMCoordinates>, 
                List<double>, 
                String
              )> snapshot
            ) 
            => !snapshot.hasData
              ? Center(child: Text("Prediction data failed to load."))
              : jobLayer == null
                ? Center(child: Text("Loading..."))
                : mapDisplay 
                    ? 
                    visualizer.Visualizer(
                      predictionCoords: snapshot.data!.$1,
                      predictionValues: snapshot.data!.$2, 
                      imageFile: snapshot.data!.$3,
                      corners: jobLayer!.corners,
                      threshold: 0.3
                    )
                    :
                    visualizer.TextDisplay(
                      predictionCoords: snapshot.data!.$1, 
                      predictionValues: snapshot.data!.$2,  
                      threshold: 0.3
                    )
          ),
        ),
      ]
    ));
  }
}