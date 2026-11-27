import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../api/api.dart' as api;

/* ============================== Utility ============================== */

/// Maps [api.ConnectionStatus]es to symbols indicating their value.
const Map<api.ConnectionStatus, Icon> _connectionStatusSymbols = {
  api.ConnectionStatus.disconnecting: Icon(
    Icons.circle,
    color: Colors.orange,
    size: 16.0
  ),
  api.ConnectionStatus.disconnected: Icon(
    Icons.circle,
    color: Colors.grey,
    size: 16.0
  ),
  api.ConnectionStatus.connecting: Icon(
    Icons.circle,
    color: Colors.yellow,
    size: 16.0
  ),
  api.ConnectionStatus.connected: Icon(
    Icons.circle,
    color: Colors.green,
    size: 16.0
  ),
  api.ConnectionStatus.failed: Icon(
    Icons.circle,
    color: Colors.red,
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
class ConnectionsPage extends StatefulWidget
{
  final api.Project project;
  const ConnectionsPage({ required this.project, super.key });

  @override
  State<ConnectionsPage> createState()
    => _ConnectionsPageState();
}

/// State of the [ConnectionsPage].
class _ConnectionsPageState extends State<ConnectionsPage>
{

  @override
  Widget build(BuildContext context)
  {

    currSetState = setState;
        
    return Material(
      child: Scaffold (
        floatingActionButton: Row(
          mainAxisAlignment: .end,
          spacing: 10.0,
          children: [
            Padding(padding: .only(bottom: 50), child:
            FloatingActionButton(
              onPressed: pingConnections,
              tooltip: 'Refresh connections',
              child: const Icon(Icons.refresh),
            ),),
            Padding(padding: .only(bottom: 50), child:
            FloatingActionButton(
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
              child: const Icon(Icons.add),
            ),),
          ],
        ),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
              child: FloatingActionButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_circle_left)
              )
            ),
            Padding(
              padding: .symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  "AirDroid Connections",
                  style: TextTheme.of(context).headlineLarge?.copyWith(
                    fontWeight: .bold, 
                  )
                )
              ), //Icon
            ),
            FutureBuilder(
              future: getUserConnectionSpecs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error.toString());

                  return Center(child: Text(
                    "Error occurred fetching your connections."
                  ));
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text("Loading..."));
                }

                return Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    vertical: 20.0,
                    horizontal: 30.0
                  ),
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 15.0,
                        crossAxisAlignment: .stretch,
                        children: snapshot.data!.map((spec)
                          => Container(
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 231, 231, 231),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              crossAxisAlignment: .end,
                              spacing: 10.0,
                              children: [
                                Padding(padding: .only(bottom: 15), child:
                                _connectionStatusSymbols[spec.status]!),

                                Expanded(child: Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    Text(
                                      "${spec.ipAddress}:${spec.port}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    ),
                                    Text(
                                      "${intl.DateFormat.yMMMEd().format(spec.createdAt)} "
                                      "at ${intl.DateFormat.jm().format(spec.createdAt)}",
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    )
                                  ]
                                )),

                                spec.status == .connected
                                ?
                                  IconButton(
                                    icon: Icon(Icons.folder_open),
                                    tooltip: "Open Filesystem",
                                    onPressed: () async {
                                      await _showFileDownloadModal(
                                        context,
                                        widget.project,
                                        spec,
                                      );
                                    },
                                  )
                                :
                                  Center(),
                                IconButton(
                                  icon: Icon(Icons.repeat_rounded),
                                  tooltip: "Retry Connection",
                                  onPressed: () async {
                                    final airdroidController = 
                                      await 
                                      api.AirdroidController.getInstance();
                                    
                                    final createdSpec = 
                                      await airdroidController.connect(
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
  BuildContext context
) async
{
  String ipAddress = "";
  String port = "";
  bool isConnecting = false;
  String? specId;

  final GlobalKey<FormState> formKey = 
    GlobalKey<FormState>();

  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context)
      => StatefulBuilder(
        builder: (
          BuildContext context,
          StateSetter setModalState
        )
          => AlertDialog(
            // padding: const material.EdgeInsets.all(24.0),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Add connection",
                    style: TextStyle(fontSize: 25.0),
                  ),

                  TextFormField(
                    readOnly: isConnecting? true : false,
                    decoration: const InputDecoration(
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
                  TextFormField(
                    readOnly: isConnecting? true : false,
                    decoration: const InputDecoration(
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

                  Padding(
                    padding: .only(top: 15.0),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),

                        // TODO: add another button that cancels the connection
                        // request instead of also closing the modal

                        ElevatedButton(
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
                                  Navigator.pop(context);
                                }
                              } on api.AirdroidNetworkException {
                                // TODO: handle connection failure better
                                setModalState(() {
                                  isConnecting = false;
                                });
                              }
                            },
                          child: Text(
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
  BuildContext pageContext,
  api.Project           project,
  api.ConnectionSpec    connectionSpec,
) async
{
  String currFilePath = "/sdcard";
  bool selectedFile = false;

  await showDialog(
    barrierDismissible: !selectedFile,
    context: pageContext,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (
        BuildContext context,
        StateSetter setModalState
      )
      => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(currFilePath),
              selectedFile
              ? Center(
                  child: Text("Fetching $currFilePath...")
                )
              : FutureBuilder(
                  future: _getDirectoryItems(connectionSpec.id, currFilePath),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print(snapshot.error.toString());
                      return Center(child: Text(
                        "Failed to fetch items."
                      ));
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return Center(child: Text(
                        "Getting items..."
                      ));
                    }

                    return Column(
                      spacing: 15.0,
                      crossAxisAlignment: .stretch,
                      children: snapshot.data!.map((item) => InkWell(
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
                            Navigator.of(pageContext).pop();

                          }
                        },
                        child: Row(
                          spacing: 10.0,
                          children: [
                            item.isFile
                              ? Icon(Icons.description)
                              : Icon(Icons.folder),
                            Text(item.name),
                            Text("${item.size} bytes"),
                            Text(
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