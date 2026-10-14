import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import 'package:latlong2/latlong.dart' as latlong;
import '../../api/api.dart' as api;
import '../home_page.dart';


class PredictionView extends StatefulWidget {
  const PredictionView({super.key, required this.predictionJob, required this.layerAssignments});

  final api.PredictionJob predictionJob;
  final Map<String, String> layerAssignments;

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

class _PredictionViewState extends State<PredictionView> {
  static const List<String> jobStatusList = [
    "Starting", 
    "Running", 
    "Complete", 
    "Failed"
  ];

  String changedName = "";
  String changedDescription = "";

  bool mapDisplay = true;
  bool isNameChanged = false;
  bool isDescriptionChanged = false;

  /// Displays a pop-up dialogue box that allows the user to set a new name for
  /// the prediction job.
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
                    onSaved: (value) {
                      setState(() {
                        changedName = value!;
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
  /// description for the prediction job.
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
                    onSaved: (value) {
                      setState(() {
                        changedDescription = value!;
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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (context) => const HomePage(),
                  ),
                );
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
  Widget build(BuildContext context) {
    String jobStatus = jobStatusList[widget.predictionJob.status.index];
    
    return ListView(
      children: [
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
                "${widget.predictionJob.name}", 
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
            child: Text("Job Status: $jobStatus"))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Date Created: ${widget.predictionJob.createdAt}"))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Layer: ${widget.predictionJob.layer.name}"))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Layer Assignments: ${widget.layerAssignments}"))),
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
          child: mapDisplay ? visualizer.Visualizer(
            predictionData: [[0, 0.5, 0.7, 0.6], [0.2, 0.8, 0.6, 0.63], [0.9, 0.5, 0.72, 0.84], [0.1, 0.3, 0.4, 0.55]], 
            imageFilePath: "assets/2D_Site_Map_Test.png",
            cornerCoordinates: [
              latlong.LatLng(-6.464587823350703, -79.81167832340672), 
              latlong.LatLng(-6.464714347149058, -79.81167832340672), 
              latlong.LatLng(-6.464587823350703, -79.8115973391495), 
              latlong.LatLng(-6.464714347149058, -79.8115973391495)
            ],
            threshold: 0.5
          )
          :
          visualizer.TextDisplay(cornerCoordinates: [
              latlong.LatLng(-6.464587823350703, -79.81167832340672), 
              latlong.LatLng(-6.464714347149058, -79.81167832340672), 
              latlong.LatLng(-6.464587823350703, -79.8115973391495), 
              latlong.LatLng(-6.464714347149058, -79.8115973391495)
            ], predictionData: [[0, 0.5, 0.7, 0.6], [0.2, 0.8, 0.6, 0.63], [0.9, 0.5, 0.72, 0.84], [0.1, 0.3, 0.4, 0.55]], threshold: 0.5)
        ),
      ]
    );
  }
}