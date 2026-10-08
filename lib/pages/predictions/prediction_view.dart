import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../api/api.dart' as api;

class PredictionView extends StatefulWidget {
  const PredictionView({super.key, required this.predictionJob});

  final api.PredictionJob predictionJob;

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

  String jobStatus = jobStatusList[0];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child:
              Text("Prediction", style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold)))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Job Status: $jobStatus"))),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: something,
            child: Text("Delete Prediction"),
          )
        ),
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