import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart';

/// A page providing a guide to using the app, documentation, troubleshooting
/// tips, and contact information.
class PredictionView extends StatefulWidget {
  const PredictionView({super.key});

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

/// The mutable state of the help page.
class _PredictionViewState extends State<PredictionView> {

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(
          child: Text("Prediction"),),
        Center(
          child: Text("Job Status: ", style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.teal,
            fontWeight: FontWeight.bold,),)),
        Visualizer(
          dataFilePath: "assets/ebk_mean_prediction.csv", 
          imageFilePath: "assets/2D_Site_Map_Test.png",
          cornerCoordinates: [],
        )
      ]
      );
    }
}