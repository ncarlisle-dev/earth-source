import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import '../../api/api.dart' as api;
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;
import 'predictions_page.dart';

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class PredictionView extends StatefulWidget {
  const PredictionView({
    super.key, 
    required this.project,
    required this.predictionJob
  });

  /// The current project being viewed.
  final api.Project project;
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
                      // Change the name of the corresponding prediction 
                      // job.
                      await widget.project.setPredictionJobMetadata(
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
                  widget.predictionJob.name = changedName;
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
                      // Change the description of the corresponding 
                      // prediction job.
                      await widget.project.setPredictionJobMetadata(
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
                  widget.predictionJob.description = changedDescription;
                });
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  /// Loads both the image and the prediction results for display on the 
  /// prediction view page.
  Future<(List<coord_converter.UTMCoordinates>, List<double>, String)> 
    loadPredictionData() async
  {
    List<coord_converter.UTMCoordinates> predictionPoints = [];
    List<double> predictionValues = [];

    final List<List<double>> results = await widget.predictionJob.getResults(
      widget.project.id
    );

    final String imageContents = await widget.project
      .getLayerImage(widget.predictionJob.layerId);

    if (results.isNotEmpty) {
      for (var i = 0; i < results.length; i++) {
        coord_converter.UTMCoordinates coords = coord_converter.UTMCoordinates(
          x: results[i][0], 
          y: results[i][1], 
          zoneNumber: widget.project.utmZone,
          isSouthernHemisphere: widget.project.isSouthernHemisphere
        );
        predictionPoints.add(coords);
        predictionValues.add(results[i][2]);
      }
    }

    return (predictionPoints, predictionValues, imageContents);
  }

  /// Callback function which is called when the status of a prediction job 
  /// changes and sets the state of the page using the new status.
  void callback(api.JobStatus status) async {
    final jobIndex = widget.project.predictions.indexWhere(
      (prediction) => prediction.id == widget.predictionJob.id);
    widget.project.predictions[jobIndex].setStatus(status);

    setState(() {
      widget.predictionJob.setStatus(status);
    });
  }

  /// Returns a formatted string containing all the assignments for a layer for
  /// display.
  String formatAssignments()
  {
    String assignments = "";
    
    widget.project.dataAssignments[widget.predictionJob.layerId]!.forEach(
      (unitId, dataId) {
      
      int unitIndex = 
        widget.project.units.indexWhere((unit) => unit.id == unitId);
      
      // If data has been assigned to the current unit, add it to the 
      // assignments string.
      if (dataId != null && unitIndex != -1)
      {
        api.DataSpec dataSpec = 
        widget.project.pxrfData.firstWhere((dataSpec) => dataSpec.id == dataId);
        assignments += "${widget.project.units[unitIndex].name} -"
        " ${dataSpec.fileName},";
      }
    }); 

    return assignments.substring(0, assignments.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    String assignments = formatAssignments();
    String jobStatus = jobStatusList[widget.predictionJob.status.index];

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Column(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(5.0),
                child: FloatingActionButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => PredictionsPage(project: widget.project),
                  )),
                  child: const Icon(Icons.arrow_circle_left)
                )
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    widget.predictionJob.name, 
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
                    widget.predictionJob.description,
                    style: TextStyle(fontSize: 15)
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 5.0, horizontal: 20.0),
                child: Center(
                  child: Text(
                    "Status: $jobStatus",
                    style: TextStyle(fontSize: 15, color: api.statusColors[widget.predictionJob.status.index])
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.only(
                  left: 20.0, 
                  right: 20.0, 
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
                    onPressed: renameJob,
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
              TabBar(
                tabs: [
                  Tab(text: 'Map View'),
                  Tab(text: 'Text View'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
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
                          ? Center(child: Text("Error: prediction data failed "
                          "to load."))
                          : snapshot.data!.$1.isEmpty 
                            ? Center(child: Text("No predictions to display at "
                            "the moment!"))
                            :
                              visualizer.Visualizer(
                                predictionCoords: snapshot.data!.$1,
                                predictionValues: snapshot.data!.$2, 
                                imageFile: snapshot.data!.$3,
                                corners: widget.project.corners,
                                threshold: 0.3
                              )
                      ),
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
                          : snapshot.data!.$1.isEmpty 
                            ? Center(child: Text("No predictions to display at the moment!"))
                            : 
                              visualizer.TextDisplay(
                                predictionCoords: snapshot.data!.$1, 
                                predictionValues: snapshot.data!.$2,  
                                threshold: 0.3
                              )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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