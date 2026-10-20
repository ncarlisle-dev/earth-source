import 'package:flutter/material.dart';
import '../../api/api.dart' as api;

/// A stateful widget for the project site map page, which takes the current 
/// project as a required field.
class MapPage extends StatefulWidget
{
  const MapPage({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<MapPage> createState() => _MapPageState();
}

/// The mutable state of the project data page.
class _MapPageState extends State<MapPage>
{
  @override
  Widget build(BuildContext context) 
  {
    return ListView();
  }
}