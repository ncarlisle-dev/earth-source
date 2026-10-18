import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import '../../api/api.dart' as api;

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class ProjectDashboard extends StatefulWidget 
{
  const ProjectDashboard({super.key, required this.project});

  /// The id of the current project.
  final api.Project project;

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

/// The mutable state of the prediction view page.
class _ProjectDashboardState extends State<ProjectDashboard> 
{
  @override
  Widget build(BuildContext context) {
    return ListView();
  }
}