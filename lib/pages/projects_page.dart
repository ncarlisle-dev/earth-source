import 'package:flutter/material.dart' as material;

/// A page where the user can create and access their projects.
class ProjectsPage extends material.StatefulWidget {
  const ProjectsPage({super.key});

  @override
  material.State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends material.State<ProjectsPage> {

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      body:
        material.Card(
          shadowColor: material.Colors.transparent,
          margin: const material.EdgeInsets.all(8.0),
          child: material.SizedBox.expand(
            child: material.Center(
              child: material.Text('Projects'),
            ),
          ),
        ),
    );
    }
}