import 'package:flutter/material.dart' as material;

/// A page providing a guide to using the app, documentation, troubleshooting
/// tips, and contact information.
class HelpPage extends material.StatefulWidget {
  const HelpPage({super.key});

  @override
  material.State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends material.State<HelpPage> {

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      body:
        material.Card(
          shadowColor: material.Colors.transparent,
          margin: const material.EdgeInsets.all(8.0),
          child: material.SizedBox.expand(
            child: material.Center(
              child: material.Text('Help'),
            ),
          ),
        ),
    );
    }
}