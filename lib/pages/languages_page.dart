import 'package:flutter/material.dart' as material;

/// A page enabling the user to change between languages.
class LanguagesPage extends material.StatefulWidget {
  const LanguagesPage({super.key});

  @override
  material.State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends material.State<LanguagesPage> {

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      body:
        material.Card(
          shadowColor: material.Colors.transparent,
          margin: const material.EdgeInsets.all(8.0),
          child: material.SizedBox.expand(
            child: material.Center(
              child: material.Text('Languages'),
            ),
          ),
        ),
    );
    }
}