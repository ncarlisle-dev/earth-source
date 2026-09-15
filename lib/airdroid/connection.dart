import 'dart:async';

import './encryption.dart' as airdroid_encryption;
import './schema.dart' as airdroid_schema;

import 'package:http/http.dart' as http;

/* ============================== Utility ============================== */

/// Thrown whenever a network request fails or an unexpected response is 
/// received.
class NetworkException implements Exception
{
  /// The error message.
  final String message;

  /// The status code sent back by the server, if applicable.
  final int? statusCode;

  const NetworkException(this.message, this.statusCode);

  @override
  String toString()
    => message;
}

/// The current state of a connection.
enum ConnectionStatus {
  /// Indicates the connection is heading towards [disconnected].
  disconnecting,
  /// Indicates that there is no connection and no server calls may be made.
  disconnected,
  /// Indicates the connection is heading toward [connected].
  connecting,
  /// Indicates the connection is up and running; server calls may be made.
  connected,
  /// Indicates the client is in the process of checking their status with
  /// the server.
  pinging,
}

/// Helper function that sends an HTTP GET request through a [client] to the
/// provided [requestAddress].
/// 
/// Returns the HTTP response in the form of an [http.Response].
/// 
/// Throws a [NetworkException] if the request doesn't go through or the server
/// responds with a non-200 status code.
Future<http.Response> _sendHttpGetRequest(
  http.Client client,
  String requestAddress
) async
{
  final http.Response response;

  try {
    response = await client.get(Uri.parse(requestAddress));
  } on http.ClientException {
    throw const NetworkException("Failed to send network request.", null);
  }

  if (response.statusCode != 200) {
    throw NetworkException(
      "Server returned status code ${response.statusCode}.",
      response.statusCode
    );
  }

  return response;
}

/* ============================== Connection ============================== */

/// A network/LAN connection to an AirDroid server.
/// 
/// ```dart
///   final client = AirdroidClient();
///   try {
///     await client.connect("192.168.0.1", 8888);
///     final fileContents = await client.fetchFile('/path/to/myfile.csv');
///     // ...
///     await client.disconnect();
///   } on NetworkException catch (e) {
///     // handle network errors...
///   }
/// ```
class AirdroidClient
{
  /// The connection status between client and server
  ConnectionStatus status = .disconnected;

  void Function(ConnectionStatus)? _statusListener;

  /// The AirDroid server's root URL.
  String _baseAddress = "";

  /// The auth token given by connecting to the server.
  String _authToken = "";

  /// The device key given by conncting to the server.
  String _deviceKey = "";

  /// The encryption key used by AirDroid for translating file paths into
  /// hashes.
  String _encryptionKey = "";

  /// HTTP connection to the server
  http.Client? _client;

  void setStatusListener(void Function(ConnectionStatus)? statusListener)
  {
    _statusListener = statusListener;
  }

  void _setStatus(ConnectionStatus status)
  {
    this.status = status;
    if (_statusListener != null) _statusListener!(status);
  }

  /// Returns true if the connection is active, false otherwise.
  bool isConnected()
    => status == .connected;

  /// Opens a connection to the AirDroid server with the given [ipAddress]
  /// and [port].
  /// 
  /// The client must not already be connected to a server. Make sure to call
  /// [disconnect] one you are done making requests.
  /// 
  /// ```dart
  ///   try {
  ///     await client.connect("192.168.0.1", 8888);
  ///     // ...
  ///     await client.disconnect();
  ///   } on NetworkException catch (e) {
  ///     // handle network errors...
  ///   }
  /// ```
  /// 
  /// Throws a [NetworkException] if the request fails or the server gives an
  /// unexpected response. When this happens, the client object should either
  /// attempt to call this function again or be deleted entirely.
  Future<void> connect(String ipAddress, int port) async
  {
    assert(!isConnected(), "Client is already connected to a server.");
    _setStatus(.connecting);

    // setup address
    _baseAddress = "http://$ipAddress:$port";
    final requestAddress = "$_baseAddress/sdctl/comm/lite_auth/";

    // create client
    _client = http.Client();

    // send request
    final http.Response response;

    try {
      // TODO: make this request cancelable
      response = await _client!.get(Uri.parse(requestAddress));
    } on http.ClientException {
      _closeClient();
      throw const NetworkException("Failed to send network request.", null);
    }

    if (response.statusCode != 200) {
      _closeClient();
      throw NetworkException(
        "Server returned status code ${response.statusCode}.",
        response.statusCode
      );
    }

    // TODO: create a thread that listens for server-triggered disconnection.
    // Alternatively, create a function that can ping the server and
    // check if the connection is active.

    // decode response
    final ({String deviceKey, String authToken}) connectionData;

    try {
      connectionData = airdroid_schema.extractConnectionData(response.body);
    } on airdroid_schema.TypeMismatchException catch (e) {
      _closeClient();
      throw NetworkException(
        "Server returned unexpected response body:\n$e",
        200
      );
    }
    
    _deviceKey = connectionData.deviceKey;
    _authToken = connectionData.authToken;

    _encryptionKey = airdroid_encryption.getEncryptionKey(
      _deviceKey,
      _authToken,
    );

    _setStatus(.connected);
  }

  /// Helper function used to close the client and reset all class members.
  /// 
  /// See [disconnect] for the proper method of closing connections.
  Future<void> _closeClient() async
  {
    _setStatus(.disconnecting);
    try {
      _client!.close();
    } on http.ClientException {
      // ignore the error
    }

    _client = null;

    _baseAddress = "";
    _authToken = "";
    _deviceKey = "";
    _encryptionKey = "";
    _setStatus(.disconnected);
  }

  /// Disconnects the client from the currently-connected AirDroid server.
  /// 
  /// The client must be connected to a server.
  Future<void> disconnect() async
  {
    assert(isConnected(), "Client is not yet connected to a server.");
    // TODO: send the following GET request instead of just closing the client
    // http://localhost:8888/sdctl/comm/logout/?7bb=[authToken]
    _closeClient();
  }

  /// Given the [filePath] to a directory, returns a list of directory's
  /// contents.
  /// 
  /// The client must be connected to a server.
  ///
  /// [filePath] must start with a '/'.
  /// 
  /// Throws a [NetworkException] if the request fails or the server gives an
  /// unexpected reponse.
  Future<List<({String name})>> queryDirectory(String filePath) async
  {
    // make sure directory can be queried
    assert(isConnected(), "Client is not yet connected to a server.");
    assert(filePath[0] == "/", "filePath must start with a '/'");

    // setup address
    filePath = filePath.replaceAll("/", "%2f");
    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/query?cur_path=$filePath&7bb=$_authToken";

    // send request
    final http.Response response = await _sendHttpGetRequest(
      _client!,
      requestAddress
    );

    // extract the data
    return airdroid_schema.extractDirectoryContents(response.body);
  }

  /// Given a [filePath], returns the file's stringifed contents.
  /// 
  /// The client must be connected to a server.
  /// 
  /// [filePath] must start with a '/'.
  ///
  /// Throws a [NetworkException] if the network request fails.
  Future<String> fetchFile(String filePath) async
  {
    // check params
    assert(isConnected(), "Client is not yet connected to a server.");

    // setup address
    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/export?pathfile="
        "${airdroid_encryption.getEncryptedFilePath(filePath, _encryptionKey)}"
        "&7bb=$_authToken";

    // send request
    final http.Response response = await _sendHttpGetRequest(
      _client!,
      requestAddress
    );

    // return data
    return response.body;
  }

  /// Checks the connection status to the server, disconnecting if the server
  /// indicates the client is disconnected.
  /// 
  /// The client must be connected to a server.
  /// 
  /// Returns true if the client is still connected, false otherwise.
  Future<bool> updateConnectionStatus() async
  {
    // check client state
    assert(isConnected(), "Client is not yet connected to a server.");
    _setStatus(.pinging);

    // send a dummy request to the server. If it responds with "err":
    // "forbidden" in the response body, we've been disconnected.
    // - For some reason, the server still responds with a 200 status code

    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/query?cur_path=%2fsdcard&7bb=$_authToken";

    // send request
    final http.Response response = await _sendHttpGetRequest(
      _client!,
      requestAddress
    );

    // check response
    bool shouldDisconnect = airdroid_schema.isForbiddenResponse(response.body);

    if (shouldDisconnect) {
      await _closeClient();
      return false;
    }

    _setStatus(.connected);
    return true;
  }
}
