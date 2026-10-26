import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart' as intl;
import '../api/api.dart' as api;
import 'data/data_file.dart';

/* ============================== Utility ============================== */

/// Maps [api.ConnectionStatus]es to symbols indicating their value.
const Map<api.ConnectionStatus, material.Icon> _connectionStatusSymbols = {
  api.ConnectionStatus.disconnecting: material.Icon(
    material.Icons.circle,
    color: material.Colors.red,
    size: 16.0
  ),
  api.ConnectionStatus.disconnected: material.Icon(
    material.Icons.circle,
    color: material.Colors.grey,
    size: 16.0
  ),
  api.ConnectionStatus.connecting: material.Icon(
    material.Icons.circle,
    color: material.Colors.yellow,
    size: 16.0
  ),
  api.ConnectionStatus.connected: material.Icon(
    material.Icons.circle,
    color: material.Colors.green,
    size: 16.0
  ),
};

/// The current setState function given by the builder.
/// 
/// Some processes occur asynchronously to the build process, so this acts as
/// a pointer to the current setState() function and makes sure an outdated
/// function call isn't made.
void Function(void Function())? currSetState;

Future<List<api.ConnectionSpec>> getUserConnectionSpecs() async
{
  final airdroidController = await api.AirdroidController.getInstance();
  await pingConnections();

  return airdroidController.connections;
}

Future<List<api.ProjectSpec>> getUserProjectSpecs() async
{
  final projectController = await api.ProjectController.getInstance();
  return await projectController.getUserProjectSpecs();
}

Future<void> pingConnections() async {
  final airdroidController = await api.AirdroidController.getInstance();

  final List<Future<void>> pingFutures = [];
  for (final spec in airdroidController.connections) {
    if (spec.status == .connected) {
      pingFutures.add(airdroidController.ping(spec.id));
    }
  }

  await Future.wait(pingFutures);
}

/* ============================ Connections page ============================ */

/// Page for managing AirDroid connections.
class ConnectionsPage extends material.StatefulWidget
{
  final api.Project project;
  const ConnectionsPage({ required this.project, super.key });

  @override
  material.State<ConnectionsPage> createState()
    => _ConnectionsPageState();
}

/// State of the [ConnectionsPage].
class _ConnectionsPageState extends material.State<ConnectionsPage>
{

  @override
  material.Widget build(material.BuildContext context)
  {

    currSetState = setState;
        
    return material.Material(
      child: material.Scaffold (
        floatingActionButton: material.Row(
          mainAxisAlignment: .end,
          spacing: 10.0,
          children: [
            material.IconButton(
              onPressed: pingConnections,
              icon: const material.Icon(material.Icons.refresh),
            ),

            material.FloatingActionButton(
              onPressed: () async
              {
                final String? createdSpecId = await _showConnectionModal(
                  context
                );
                if (createdSpecId == null) return;

                await pingConnections();

                final airdroidController = await api.AirdroidController
                  .getInstance();

                airdroidController.watchConnectionStatus(
                  createdSpecId,
                  (_) => currSetState!(() {})
                );

                setState(() {});
              },
              tooltip: 'Add connection',
              child: const material.Icon(material.Icons.add),
            ),
          ],
        ),
        body: material.ListView(
          children: [
            material.Padding(
              padding: material.EdgeInsetsGeometry.symmetric(vertical: 16.0),
              child: material.FloatingActionButton(
                onPressed: () => material.Navigator.of(context).pop(),
                child: const material.Icon(material.Icons.arrow_circle_left)
              )
            ),
            material.Padding(
              padding: .symmetric(vertical: 16.0),
              child: material.Center(
                child: material.Text(
                  "AirDroid connections",
                  style: material.TextTheme.of(context).headlineLarge?.copyWith(
                    fontWeight: .bold, 
                    color: material.Colors.indigo
                  )
                )
              ), //Icon
            ),
            material.FutureBuilder(
              future: getUserConnectionSpecs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error.toString());

                  return material.Center(child: material.Text(
                    "Error occurred fetching your connections."
                  ));
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return material.Center(child: material.Text("Loading..."));
                }

                return material.Padding(
                  padding: material.EdgeInsetsGeometry.symmetric(
                    vertical: 20.0,
                    horizontal: 30.0
                  ),
                    child: material.SingleChildScrollView(
                      child: material.Column(
                        spacing: 15.0,
                        crossAxisAlignment: .stretch,
                        children: snapshot.data!.map((spec)
                          => material.Container(
                            padding: material.EdgeInsets.all(10.0),
                            decoration: material.BoxDecoration(
                              color: material.Color.fromARGB(255, 231, 231, 231),
                              borderRadius: material.BorderRadius.circular(10.0),
                            ),
                            child: material.Row(
                              spacing: 10.0,
                              children: [
                                _connectionStatusSymbols[spec.status]!,

                                material.Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    material.Text(
                                      "${spec.ipAddress}:${spec.port}",
                                      style: material.TextStyle(
                                        fontWeight: material.FontWeight.bold
                                      ),
                                    ),
                                    material.Text(
                                      "${intl.DateFormat.yMMMEd().format(spec.createdAt)} "
                                      "at ${intl.DateFormat.jm().format(spec.createdAt)}"
                                    )
                                  ]
                                ),

                                material.IconButton(
                                  icon: material.Icon(material.Icons.folder_open),
                                  onPressed: () async {
                                    await _showFileDownloadModal(
                                      context,
                                      widget.project,
                                      spec,
                                    );
                                  },
                                ),

                                material.IconButton(
                                  icon: material.Icon(material.Icons.refresh),
                                  onPressed: () async {
                                    final airdroidController = 
                                      await api.AirdroidController.getInstance();
                                    
                                    final createdSpec = await airdroidController.connect(
                                      spec.ipAddress,
                                      spec.port
                                    );

                                    airdroidController.watchConnectionStatus(
                                      createdSpec.id,
                                      (_) => currSetState!(() {})
                                    );

                                    pingConnections();

                                    setState(() {});
                                  },
                                ),
                              ]
                            )
                          )
                        ).toList().reversed.toList(),
                      ),
                    ),
                );
              }
            )
          ]
        ),
      ),
    );
  }
}

/// Given the current build [context], shows the connection modal enabling the
/// user to create a new connection.
/// 
/// Returns the [_ConnectionSpec] created by the user, or null if they
/// cancelled its creation.
Future<String?> _showConnectionModal(
  material.BuildContext context
) async
{
  String ipAddress = "";
  String port = "";
  bool isConnecting = false;
  String? specId;

  final material.GlobalKey<material.FormState> formKey = 
    material.GlobalKey<material.FormState>();

  await material.showDialog(
    barrierDismissible: false,
    context: context,
    builder: (material.BuildContext context)
      => material.StatefulBuilder(
        builder: (
          material.BuildContext context,
          material.StateSetter setModalState
        )
          => material.AlertDialog(
            // padding: const material.EdgeInsets.all(24.0),
            content: material.Form(
              key: formKey,
              child: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                crossAxisAlignment: material.CrossAxisAlignment.stretch,
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

                  // TODO: make this field number-only
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
                    padding: .only(top: 15.0),
                    child: material.Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        material.ElevatedButton(
                          onPressed: () => material.Navigator.pop(context),
                          child: const material.Text('Cancel'),
                        ),

                        // TODO: add another button that cancels the connection
                        // request instead of also closing the modal

                        material.ElevatedButton(
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
                              setModalState(() { isConnecting = true; });

                              // connect
                              final airdroidController = 
                                await api.AirdroidController.getInstance();

                              try {
                                specId = (await airdroidController.connect(
                                  ipAddress,
                                  int.parse(port)
                                )).id;

                                if (context.mounted) {
                                  // close modal
                                  material.Navigator.pop(context);
                                }
                              } on api.AirdroidNetworkException {
                                // TODO: handle connection failure better
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
  );

  return specId;
}

Future<List<api.DirectoryItemSpec>> _getDirectoryItems(
  String specId,
  String filePath
) async
{
  final airdroidController = await api.AirdroidController.getInstance();
  return await airdroidController.getDirectoryContents(specId, filePath);
}

Future<void> _showFileDownloadModal(
  material.BuildContext pageContext,
  api.Project           project,
  api.ConnectionSpec    connectionSpec,
) async
{
  String currFilePath = "/sdcard";
  bool selectedFile = false;

  await material.showDialog(
    barrierDismissible: !selectedFile,
    context: pageContext,
    builder: (material.BuildContext context) => material.StatefulBuilder(
      builder: (
        material.BuildContext context,
        material.StateSetter setModalState
      )
      => material.AlertDialog(
        content: material.SingleChildScrollView(
          child: material.Column(
            children: [
              material.Text(currFilePath),
              selectedFile
              ? material.Center(
                  child: material.Text("Fetching $currFilePath...")
                )
              : material.FutureBuilder(
                  future: _getDirectoryItems(connectionSpec.id, currFilePath),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print(snapshot.error.toString());
                      return material.Center(child: material.Text(
                        "Failed to fetch items."
                      ));
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return material.Center(child: material.Text(
                        "Getting items..."
                      ));
                    }

                    return material.Column(
                      spacing: 15.0,
                      crossAxisAlignment: .stretch,
                      children: snapshot.data!.map((item) => material.InkWell(
                        onTap: () async {
                          setModalState(() {
                            currFilePath += "/${item.name}";
                            selectedFile = item.isFile;
                          });

                          if (!item.isFile) return;

                          final airdroidController = 
                            await api.AirdroidController.getInstance();

                          final fileContents = await airdroidController
                            .getFileContents(
                              connectionSpec.id,
                              currFilePath,
                            );
                          
                          final dataSpec = await project.addPxrfData(
                            fileContents,
                            currFilePath,
                            "",
                          );

                          if (pageContext.mounted) {
                            material.Navigator.of(pageContext).pop();

                            await material.Navigator.pushReplacement(
                              pageContext,
                              material.MaterialPageRoute(
                                builder: (_) => DataView(
                                  project: project,
                                  dataSpec: dataSpec,
                                )
                              ),
                            );
                          }
                        },
                        child: material.Row(
                          spacing: 10.0,
                          children: [
                            item.isFile
                              ? material.Icon(material.Icons.description)
                              : material.Icon(material.Icons.folder),
                            material.Text(item.name),
                            material.Text("${item.size} bytes"),
                            material.Text(
                              "${intl.DateFormat.yMMMEd().format(item.lastModified)}, "
                              "${intl.DateFormat.jm().format(item.lastModified)}"
                            ),
                          ],
                        ),
                      )).toList()
                    );
                  }
              ),
            ],
          )
        ),
      ),
    ),
  );
}