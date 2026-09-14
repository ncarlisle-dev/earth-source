import 'package:flutter/material.dart' as material;

class ConnectionsPage extends material.StatefulWidget {
  const ConnectionsPage({ super.key });

  @override
  material.State<ConnectionsPage> createState()
    => _ConnectionsPageState();
}

class _ConnectionsPageState extends material.State<ConnectionsPage> {
  @override
  material.Widget build(material.BuildContext context)
  {
    return material.Card(
      shadowColor: material.Colors.transparent,
      margin: const material.EdgeInsets.all(8.0),
      child: material.SizedBox.expand(
        child: material.Center(
          child: material.Text('Connections page'),
        )
      )
    );
  }
}