import 'package:flutter/material.dart' as material;
import '../airdroid/connection.dart' as airdroid_connection;
import 'package:intl/intl.dart' as intl;

class _ConnectionEntry
{
  final String ipAddress;
  final int port;
  final DateTime timeCreated;
  airdroid_connection.AirdroidClient? client;

  _ConnectionEntry(this.ipAddress, this.port, this.timeCreated, this.client);
}

class ConnectionsPage extends material.StatefulWidget
{
  const ConnectionsPage({ super.key });

  @override
  material.State<ConnectionsPage> createState()
    => _ConnectionsPageState();
}

// TODO: Save connection entries to a file and reload them on startup
final List<_ConnectionEntry> _connectionEntries = [];

class _ConnectionsPageState extends material.State<ConnectionsPage>
{
  @override
  material.Widget build(material.BuildContext context)
  {
    return material.Padding(
      padding: material.EdgeInsetsGeometry.symmetric(
        vertical: 20.0,
        horizontal: 30.0
      ),
      child: material.Scaffold(
        body: material.Column(
          spacing: 15.0,
          crossAxisAlignment: material.CrossAxisAlignment.stretch,
          children: _connectionEntries.map((entry)
            => material.Container(
              padding: material.EdgeInsets.all(10.0),
              decoration: material.BoxDecoration(
                color: material.Color.fromARGB(255, 231, 231, 231),
                borderRadius: material.BorderRadius.circular(10.0),
              ),
              child: material.Row(
                spacing: 10.0,
                children: [
                  material.Icon(
                    material.Icons.circle,
                    color: material.Colors.green,
                    size: 16.0
                  ),
                  material.Column(
                    crossAxisAlignment: material.CrossAxisAlignment.start,
                    children: [
                      material.Text(
                        "${entry.ipAddress}:${entry.port}",
                        style: material.TextStyle(
                          fontWeight: material.FontWeight.bold
                        ),
                      ),
                      material.Text(
                        "${intl.DateFormat.yMMMEd().format(entry.timeCreated)} "
                        "at ${intl.DateFormat.jm().format(entry.timeCreated)}"
                      )
                    ]
                  ),
                ]
              )
            )
          ).toList().reversed.toList(),
        ),
        floatingActionButton: material.FloatingActionButton(
          onPressed: () async
          {
            final _ConnectionEntry? entry = await _showConnectionModal(context);
            
            if (entry != null)
            {
              setState(() {
                _connectionEntries.add(entry);
              });
            }
          },
          tooltip: 'Add connection',
          child: const material.Icon(material.Icons.add),
        ),
      ),
    );
  }
}

Future<_ConnectionEntry?> _showConnectionModal(
  material.BuildContext context
) async
{
  String ipAddress = "";
  String port = "";
  bool isConnecting = false;

  airdroid_connection.AirdroidClient? client;

  final material.GlobalKey<material.FormState> formKey = 
    material.GlobalKey<material.FormState>();

  await material.showDialog(
    barrierDismissible: false,
    context: context,
    builder: (material.BuildContext context)
      => material.StatefulBuilder(
        builder: (material.BuildContext context, material.StateSetter setModalState)
          => material.AlertDialog(
            // padding: const material.EdgeInsets.all(24.0),
            content: material.Form(
              key: formKey,
              child: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                // crossAxisAlignment: material.CrossAxisAlignment.stretch,
                spacing: 10.0,
                children: [
                  const material.Text(
                    "Add connection",
                    style: material.TextStyle(fontSize: 25.0),
                  ),

                  material.TextFormField(
                    decoration: const material.InputDecoration(
                      hintText: 'IP address'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the IP address';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      ipAddress = value ?? "";
                    },
                  ),

                  material.TextFormField(
                    decoration: const material.InputDecoration(
                      hintText: 'Port number'
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the port number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      port = value ?? "";
                    },
                  ),

                  material.Padding(
                    padding: const material.EdgeInsets.symmetric(vertical: 16),
                    child: material.ElevatedButton(
                      onPressed: isConnecting
                        ? null
                        : () async
                        {
                          // validate and save the form data
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          formKey.currentState!.save();

                          // update frontend to show connection progress
                          setModalState(() {
                            isConnecting = true;
                          });

                          // create the client and connect
                          client = airdroid_connection.AirdroidClient();

                          try {
                            await client!.connect(ipAddress, int.parse(port));

                            if (context.mounted) {
                              material.Navigator.pop(context); // close modal
                            }
                          } on airdroid_connection.NetworkException {
                            print("connection couldn't be made");
                            client = null;

                            setModalState(() {
                              isConnecting = false;
                            });
                          }
                        },
                      child: material.Text(
                        isConnecting
                            ? 'Connecting... (Check your device)'
                            : 'Connect',
                      ),
                    ),
                  ),

                  material.ElevatedButton(
                    onPressed: () => material.Navigator.pop(context),
                    child: const material.Text('Close'),
                  ),
                ],
              ),
            ),
          ),
      ),
  );

  return client == null
    ? null
    : _ConnectionEntry(
      ipAddress,
      int.parse(port),
      DateTime.now(),
      client
    );
}