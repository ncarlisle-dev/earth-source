import '../../common/common.dart' as common;
import 'airdroid_client.dart';
import '../../services/network_service.dart';

/* ================================ Utility ================================ */

/// Helper regex expression to match against IPv4 addresses.
final _ipv4AddrRegex = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[09][0-9]?)\.){3}'
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

/// Helper function that constructs a uniquely-identifiable key from the
/// inputted [ipAddress] and [port].
String convertAddressToKey(String ipAddress, int port)
  => "$ipAddress:$port";

/* =========================== AirdroidController =========================== */

/// A singleton AirDroid connection manager, enabling device connection,
/// file downloading, and directory querying via AirDroid.
class AirdroidController
{
  /// Singleton instance of the [AirdroidController].
  static AirdroidController? _instance;

  /// Collection of all active [AirdroidClient] objects, mapped by
  /// network address.
  final Map<String, AirdroidClient> _activeClients = {};

  /// Collection of status listeners, called whenever the underlying client's
  /// [common.ConnectionStatus] changes.
  final Map<String, void Function(common.ConnectionStatus)?> _statusListeners 
    = {};

  /// List of all the user's [ConnectionSpec]s.
  List<common.ConnectionSpec>? connections;


  /// Internal constructor used to prevent other modules from creating a new
  /// [AirdroidController] instance.
  AirdroidController._()
  {
    NetworkService networkService = NetworkService.getInstance();
    networkService.getConnectionEntries()
      .then((entries) => connections = entries);
  }


  /// Returns the singleton [AirdroidController] instance, creating a new one
  /// if it is not yet initialized.
  AirdroidController getInstance()
  {
    _instance ??= AirdroidController._();
    return _instance!;
  }


  /// Sets a callback to be run every time the connection with the given
  /// [ipAddress] and [port] undergoes a status change.
  /// 
  /// Each connection may only have one registered callback at a time, so
  /// to unregister a callback, call this function with [null] as the callback.
  void watchConnectionStatus(
    String ipAddress,
    int port,
    void Function(common.ConnectionStatus status)? callback,
  )
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");

    _statusListeners[convertAddressToKey(ipAddress, port)] = callback;
  }


  /// Initializes a connection to the AirDroid server at the inputted
  /// [ipAddress] and [port], updates the [connections] field, and uploads the 
  /// resulting [common.ConnectionSpec] to the database.
  /// 
  /// If connection to the server succeeds but the database write fails,
  /// the connection is still maintained and must be [disconnect]ed for full
  /// cleanup.
  /// 
  /// Throws a [common.AirdroidNetworkException] if connecting to the AirDroid 
  /// server fails. Throws a [common.ApiNetworkException] if uploading the 
  /// connection spec fails.
  Future<void> connect(String ipAddress, int port) async
  {
    // check params
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
    assert(connections != null, "Connections isn't fetched yet.");

    // initialize client
    final String clientKey = convertAddressToKey(ipAddress, port);
    final AirdroidClient client;

    if (_activeClients.containsKey(clientKey)) {
      client = _activeClients[clientKey]!;
    } else {
      client = AirdroidClient();
      _activeClients[clientKey] = client;
    }

    // set connection spec
    final common.ConnectionSpec connSpec;
    int existingConnSpecIndex = connections!.indexWhere(
      (spec) => spec.ipAddress == ipAddress && spec.port == port
    );

    if (existingConnSpecIndex > 0) {
      connSpec = connections![existingConnSpecIndex];
    } else {
      connSpec = common.ConnectionSpec(
        ipAddress,
        port,
        DateTime.now(),
        DateTime.now(),
        client.status,
      );
    }

    connections!.add(connSpec);

    // set status lisenter
    client.setStatusListener((status) {
      if (
        _statusListeners.containsKey(clientKey)
        && _statusListeners[clientKey] != null
      ) {
        _statusListeners[clientKey]!(status);
      }

      connSpec.status = status;
    });

    // connect to the server
    try {
      await client.connect(ipAddress, port);
    } on common.ApiNetworkException {
      connections!.removeLast();
      client.setStatusListener(null);
    }

    // upload the connection spec
    final networkService = NetworkService.getInstance();
    await networkService.uploadConnectionSpec(connSpec);
  }


  /// Helper function that asserts a client with the given [ipAddress] and
  /// [port] exists, is connected, and is available.
  /// 
  /// Returns the [AirdroidClient] with the [ipAddress] and [port].
  AirdroidClient _assertClientIsAvailable(String ipAddress, int port)
  {
    final String clientKey = convertAddressToKey(ipAddress, port);

    assert(
      _activeClients.containsKey(clientKey),
      "Client with key '$clientKey' doesn't exist."
    );

    final AirdroidClient client = _activeClients[clientKey]!;

    assert(
      client.status == .connected,
      "Client with key '$clientKey' is either disconnected or busy."
    );

    return client;
  }


  /// Pings the server at the inputted [ipAddress] and [port], updating the
  /// [common.ConnectionSpec]'s status and calling the registered status 
  /// listener if the status changed.
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  Future<void> ping(String ipAddress, int port) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");

    final AirdroidClient client = _assertClientIsAvailable(ipAddress, port);
    await client.updateConnectionStatus();
  }

  /// Disconnects the AirDroid server connection at the given [ipAddress] and
  /// [port].
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  Future<void> disconnect(String ipAddress, int port) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");

    final AirdroidClient client = _assertClientIsAvailable(ipAddress, port);
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
  Future<String> getFileContents(
    String ipAddress,
    int port,
    String filePath
  ) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
    assert(_isValidFilePath(filePath), "File path is invalid.");

    final AirdroidClient client = _assertClientIsAvailable(ipAddress, port);
    return await client.fetchFile(filePath);
    // TODO: update the lastUsed in the connection spec
  }

  /// Fetches the items in an AirDroid server directory at the given
  /// [ipAddress], [port], and [filePath].
  /// 
  /// There must be an active [connect]ion under the [ipAddress] and [port].
  /// [filePath] must start with a '/'.
  /// 
  /// Throws a [common.AirdroidNetworkException] if the network request fails.
  Future<List<common.DirectoryItemSpec>> getDirectoryContents(
    String ipAddress,
    int port,
    String filePath
  ) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
    assert(_isValidFilePath(filePath), "File path is invalid.");

    final AirdroidClient client = _assertClientIsAvailable(ipAddress, port);
    return await client.queryDirectory(filePath);
  }
}

