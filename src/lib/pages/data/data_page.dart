import 'package:flutter/material.dart';
import '../../api/api.dart' as api;

/// A stateful widget for the project data page, which takes the current project
/// as a required field.
class DataPage extends StatefulWidget
{
  const DataPage({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<DataPage> createState() => _DataPageState();
}

/// The mutable state of the project data page.
class _DataPageState extends State<DataPage>
{
  @override
  Widget build(BuildContext context) 
  {
    return ListView();
  }
}