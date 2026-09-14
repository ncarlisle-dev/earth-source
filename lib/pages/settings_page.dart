import 'package:flutter/material.dart' as material;

/// A page allowing the user to adjust app settings.
class SettingsPage extends material.StatefulWidget {
  const SettingsPage({super.key});

  @override
  material.State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends material.State<SettingsPage> {

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
       body:
        material.Card(
          shadowColor: material.Colors.transparent,
          margin: const material.EdgeInsets.all(8.0),
          child: material.SizedBox.expand(
            child: material.Center(
              child: material.Text('Settings'),
            ),
          ),
        ),
    );
    }
}