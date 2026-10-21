import 'package:flutter/material.dart';
import '../../mapping/visualizer.dart' as visualizer;
import '../../api/api.dart' as api;

/// A stateful widget for the project dashboard page, which a given project
/// as a required field.
class ProjectDashboard extends StatefulWidget 
{
  const ProjectDashboard({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

/// The mutable state of the project dashboard page.
class _ProjectDashboardState extends State<ProjectDashboard> 
{
  @override
  Widget build(BuildContext context) 
  {
    return ListView();
  }
}