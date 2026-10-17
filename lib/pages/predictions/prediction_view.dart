import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import '../../api/api.dart' as api;
import '../home_page.dart';

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class PredictionView extends StatefulWidget 
{
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
class _PredictionViewState extends State<PredictionView> 
{
  @override
  Widget build(BuildContext context) {
    return ListView();
  }
}