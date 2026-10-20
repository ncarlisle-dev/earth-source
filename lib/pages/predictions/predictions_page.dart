import 'package:flutter/material.dart';
import '../../api/api.dart' as api;

/// A stateful widget for the project predictions page, which takes the id for 
/// the current project as a required field.
class PredictionsPage extends StatefulWidget
{
  const PredictionsPage({super.key, required this.projectId});

  /// The id of the current project.
  final String projectId;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the project predictions page.
class _PredictionsPageState extends State<PredictionsPage>
{
  @override
  Widget build(BuildContext context) 
  {
    return ListView();
  }
}