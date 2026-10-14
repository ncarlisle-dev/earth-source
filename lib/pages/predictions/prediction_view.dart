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
   
  void something()
  {

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
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Visualizer(
            dataFilePath: "assets/ebk_mean_prediction.csv", 
            imageFilePath: "assets/2D_Site_Map_Test.png",
            cornerCoordinates: [
              latlong.LatLng(-6.464587823350703, -79.81167832340672), 
              latlong.LatLng(-6.464714347149058, -79.81167832340672), 
              latlong.LatLng(-6.464587823350703, -79.8115973391495), 
              latlong.LatLng(-6.464714347149058, -79.8115973391495)
            ],
            threshold: 0.5
          )
        ),
      ]
      );
    }
}