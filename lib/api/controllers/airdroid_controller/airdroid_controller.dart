import '../../common/common.dart' as common;
import 'airdroid_client.dart';
import '../../services/network_service.dart';

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

/// A singleton AirDroid connection manager, enabling device connection,
/// file downloading, and directory querying via AirDroid.
class AirdroidController
{
  /// Singleton instance of the [AirdroidController]
  static AirdroidController? _instance;

  /// Collection of all active [AirdroidClient] objects, mapped by
  /// network address.
  final Map<String, AirdroidClient> _activeClients = {};
  final Map<
    String,
    void Function(common.ConnectionStatus)?
  > _statusListeners = {};

  /// List of all the user's [ConnectionSpec]s.
  List<common.ConnectionSpec>? connections;

  /// Internal constructor used to prevent other modules from creating a new
  /// AirdroidController instance.
  AirdroidController._()
  {
    NetworkService networkService = NetworkService.getInstance();
    networkService.getConnectionEntries()
      .then((entries) => connections = entries);
  }

  AirdroidController getInstance()
  {
    _instance ??= AirdroidController._();
    return _instance!;
  }

  void watchConnectionStatus(
    String ipAddress,
    int port,
    void Function(common.ConnectionStatus status)? callback,
  )
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");

    _statusListeners["$ipAddress:$port"] = callback;
  }

  Future<void> connect(String ipAddress, int port) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
    assert(connections != null, "Connections isn't fetched yet");

    final String clientKey = "$ipAddress:$port";
    final AirdroidClient client;

    if (_activeClients.containsKey(clientKey)) {
      client = _activeClients[clientKey]!;
    } else {
      client = AirdroidClient();
      _activeClients[clientKey] = client;
    }

    client.setStatusListener((status) {
      final entry = connections!.firstWhere(
        (entry) => ipAddress == entry.ipAddress && port == entry.port
      );

      entry.status = status;
    });

    await client.connect(ipAddress, port);
  }

  Future<common.ConnectionStatus> ping(String ipAddress, int port) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
  }

  Future<void> disconnect(String ipAddress, int port) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
  }

  Future<String> getFileContents(
    String ipAddress,
    int port,
    String filePath
  ) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
  }

  Future<List<common.DirectoryItemSpec>> getDirectoryContents(
    String ipAddress,
    int port,
    String filePath
  ) async
  {
    assert(_isValidIpAddress(ipAddress), "IP address is invalid.");
    assert(_isValidPort(port), "Port is invalid.");
  }
}

