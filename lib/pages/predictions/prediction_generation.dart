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
  @override
  Widget build(BuildContext context)
  {

    return Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text(widget.projectId));
  }
}