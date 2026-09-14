import 'package:flutter/material.dart' as material;

/// A page for describing the project, with links to the repository and website.
class AboutPage extends material.StatefulWidget {
  const AboutPage({super.key});

  @override
  material.State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends material.State<AboutPage> {

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      body:
        material.Card(
          shadowColor: material.Colors.transparent,
          margin: const material.EdgeInsets.all(8.0),
          child: material.SizedBox.expand(
            child: material.Center(
              child: material.Text('About'),
            ),
          ),
        ),
    );
    }
}