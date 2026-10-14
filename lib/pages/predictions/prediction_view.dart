import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../api/api.dart' as api;



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

  bool mapDisplay = true;

  void something()
  {
    setState(() {
      mapDisplay ? mapDisplay = false : mapDisplay = true;
    });
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
              Text("${widget.predictionJob.name}", style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.indigo)))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Description: ${widget.predictionJob.description}"))),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: something,
            child: Text("Rename Prediction"),
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: something,
            child: Text("Change Description"),
          )
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: something,
            child: Text("Delete Prediction"),
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child:
              Text("Job Information", style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.indigo)))),
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
            child: Text(mapDisplay ? "Toggle text-formatted predictions" : "Toggle map display"),
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: mapDisplay ? Visualizer(
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
          TextDisplay(cornerCoordinates: [
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