import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_generation.dart';

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class PredictionsPage extends StatefulWidget 
{
  const PredictionsPage({super.key, required this.projectId});

  /// The id of the current project.
  final String projectId;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the prediction view page.
class _PredictionsPageState extends State<PredictionsPage> 
{
  int i = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Positioned(
          top: 0.0,
          child: Center(child: Text("Predictions", style: TextTheme.of(context).headlineLarge?.copyWith(fontWeight: FontWeight.bold, 
                  color: Colors.indigo))), //Icon
        ), 
        GridView.count(
          // Create a grid with 2 columns.
          // If you change the scrollDirection to horizontal,
          // this produces 2 rows.
          crossAxisCount: 2,
          // Generate 100 widgets that display their index in the list.
          children: List.generate(100, (index) {
            return Center(
              child: Text(
                'Item $index',
                style: TextTheme.of(context).headlineSmall,
              ),
            );
          }),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute<void>(builder: 
                (context) => PredictionGeneration(projectId: widget.projectId)
              )
            ),
            child: const Icon(Icons.add)
          )
        ),
      ],
    );
  }
}