import '../../common/common.dart' as common;
import 'airdroid_client.dart';
import '../../services/network_service.dart';

/* ================================ Utility ================================ */

/// Helper regex expression to match against IPv4 addresses.
final _ipv4AddrRegex = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
  r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
);

/// Helper function that returns true if the inputted [str] is a valid IPv4
/// address, false otherwise.
bool _isValidIpAddress(String str)
  => _ipv4AddrRegex.hasMatch(str);

/// Helper function that returns true if the inputted [num] is a valid port
/// number, false otherwise.
bool _isValidPort(int num)
  => num > 0;

/// Helper function that returns true if the inputted [str] is a valid file
/// path, false otherwise.
bool _isValidFilePath(String str)
  => str.isNotEmpty && str[0] == '/';

/* =========================== AirdroidController =========================== */

/// A singleton AirDroid connection manager, enabling device connection,
/// file downloading, and directory querying via AirDroid.
class AirdroidController
{
  /// Singleton instance of the [AirdroidController].
  static AirdroidController? _instance;

  /// Collection of all active [AirdroidClient] objects, mapped by
  /// connection spec IDs.
  final Map<String, AirdroidClient> _activeClients = {};

  /// Collection of status listeners, called whenever the underlying client's
  /// [common.ConnectionStatus] changes.
  final Map<String, void Function(common.ConnectionStatus)?> _statusListeners 
    = {};

  /// List of all the user's [ConnectionSpec]s.
  final List<common.ConnectionSpec> connections;


  /// Internal constructor used to prevent other modules from creating a new
  /// [AirdroidController] instance.
  AirdroidController._(this.connections);

  /// Returns the singleton [AirdroidController] instance, creating a new one
  /// if it is not yet initialized.
  static Future<AirdroidController> getInstance() async
  {
    if (_instance != null) return _instance!;

    final networkService = await NetworkService.getInstance();
    final connections = await networkService.getUserConnectionEntries();

    _instance = AirdroidController._(connections);
    return _instance!;
  }


  /// Sets a callback to be run every time the connection with the given
  /// [ipAddress] and [port] undergoes a status change.
  /// 
  /// Each connection may only have one registered callback at a time, so
  /// to unregister a callback, call this function with [null] as the callback.
  void watchConnectionStatus(
    String id,
    void Function(common.ConnectionStatus status)? callback,
  )
  {
    assert(connections.any((spec) => spec.id == id));
    _statusListeners[id] = callback;
  }


  /// Initializes a connection to the AirDroid server at the inputted
  /// [ipAddress] and [port], updates the [connections] field, and uploads the 
  /// resulting [common.ConnectionSpec] to the database.
  /// 
  /// If connection to the server succeeds but the database write fails,
  /// the connection is still maintained and must be [disconnect]ed for full
  /// cleanup.
  /// 
  /// Throws a [common.ApiNetworkException] if uploading the connection spec 
  /// fails.
  Future<common.ConnectionSpec> connect(String ipAddress, int port) async
  {
    // check params
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");

    // create connection spec
    final networkService = await NetworkService.getInstance();
    final connectionSpec = await networkService.createConnectionSpec(
      ipAddress,
      port
    );

    connections.add(connectionSpec);

    // initialize client
    final client = AirdroidClient();
    _activeClients[connectionSpec.id] = client;

    // set status lisenter
    client.setStatusListener((status) {
      if (_statusListeners.containsKey(connectionSpec.id)) {
        _statusListeners[connectionSpec.id]!(status);
      }

      connectionSpec.status = status;
    });

    // connect to the server
    try {
      client.connect(ipAddress, port);
    } on common.AirdroidNetworkException {
      client.setStatusListener(null);
      connectionSpec.status = .disconnected;
    }

    return connectionSpec;
  }


  /// Helper function that asserts a client with the given [ipAddress] and
  /// [port] exists, is connected, and is available.
  /// 
  /// Returns the [AirdroidClient] with the [ipAddress] and [port].
  AirdroidClient _assertClientIsAvailable(String id)
  {
    final client = _activeClients[id];
    assert(client != null, "Client with connection ID '$id' doesn't exist.");

    assert(
      client!.status == .connected,
      "Client under connection ID '$id' is either disconnected or busy."
    );

    return client!;
  }


  /// Pings the server at the inputted [ipAddress] and [port], updating the
  /// [common.ConnectionSpec]'s status and calling the registered status 
  /// listener if the status changed.
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  Future<void> ping(String id) async
  {
    assert(
      connections.any((spec) => spec.id == id),
      "Connection with ID '$id' not found."
    );

    final client = _assertClientIsAvailable(id);
    await client.updateConnectionStatus();
  }

  /// Disconnects the AirDroid server connection at the given [ipAddress] and
  /// [port].
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  Future<void> disconnect(String id) async
  {
    assert(
      connections.any((spec) => spec.id == id),
      "Connection with ID '$id' not found."
    );

    final client = _assertClientIsAvailable(id);
    await client.disconnect();
  }

  /// Fetches a file from the AirDroid server at the given [ipAddress], [port],
  /// and [filePath].
  /// 
  /// This is considered a "use" of the connection, so [common.ConnectionSpec]'s
  /// lastUsed field is updated on the backend.
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  /// [filePath] must start with a '/'.
  /// 
  /// Throws a [common.AirdroidNetworkException] if the network request fails.
  /// Throws a [common.ApiNetworkException] if the database's
  /// [common.ConnectionSpec] couldn't be updated.
  Future<String> getFileContents(String id, String filePath) async
  {
    assert(
      connections.any((spec) => spec.id == id),
      "Connection with ID '$id' not found."
    );
    assert(_isValidFilePath(filePath), "File path '$filePath' is invalid.");

    final client = _assertClientIsAvailable(id);
    return await client.fetchFile(filePath);
    // TODO: add and update a lastUsed field here
  }

  /// Fetches the items in an AirDroid server directory at the given
  /// [ipAddress], [port], and [filePath].
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  /// [filePath] must start with a '/'.
  /// 
  /// Throws a [common.AirdroidNetworkException] if the network request fails.
  Future<List<common.DirectoryItemSpec>> getDirectoryContents(
    String id,
    String filePath
  ) async
  {
    assert(
      connections.any((spec) => spec.id == id),
      "Connection with ID '$id' not found."
    );
    assert(_isValidFilePath(filePath), "File path is invalid.");

    final client = _assertClientIsAvailable(id);
    return await client.queryDirectory(filePath);
  }
}

