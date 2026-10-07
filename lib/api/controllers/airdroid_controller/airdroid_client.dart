import 'dart:async';

import 'encryption.dart' as ad_encryption;
import 'schema.dart' as ad_schema;
import '../../common/common.dart' as common;

import 'package:http/http.dart' as http;

/* ============================== Utility ============================== */

/// Helper function that sends an HTTP GET request through a [client] to the
/// provided [requestAddress].
/// 
/// Returns the HTTP response in the form of an [http.Response].
/// 
/// Throws a [common.AirdroidNetworkException] if the request doesn't go through
/// or the server responds with a non-200 status code.
Future<http.Response> _sendHttpGetRequest(
  http.Client client,
  String requestAddress
) async
{
  final http.Response response;

  try {
    response = await client.get(Uri.parse(requestAddress));
  } on http.ClientException {
    throw const common.AirdroidNetworkException(
      "Failed to send network request.",
      null
    );
  }

  if (response.statusCode != 200) {
    throw common.AirdroidNetworkException(
      "Server returned status code ${response.statusCode}.",
      response.statusCode
    );
  }

  return response;
}

/* ============================= AirdroidClient ============================= */

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
  common.ConnectionStatus _status = .disconnected;

  void Function(common.ConnectionStatus)? _statusListener;

  /// The connection status between client and server.
  common.ConnectionStatus get status
    => _status; // use a getter to make this property read-only

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


  /// Registers a [callback] to be called every time the connection [status] of
  /// the client changes.
  /// 
  /// [callback] must take in a [common.ConnectionStatus]. The return value is
  /// ignored. To unregister the status listener, call this function with 
  /// argument null.
  void setStatusListener(void Function(common.ConnectionStatus)? callback)
    =>_statusListener = callback;


  /// Helper function that sets the the client's [_status] and subsequently 
  /// calls its [_statusListener], if it exists.
  void _setStatus(common.ConnectionStatus status)
  {
    if (_statusListener != null && status != _status) _statusListener!(status);
    _status = status;
  }


  /// Opens a connection to the AirDroid server with the given [ipAddress]
  /// and [port].
  /// 
  /// The client must not already be connected to a server. Make sure to call
  /// [disconnect] once you are done making requests.
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
  /// Throws a [common.AirdroidNetworkException] if the request fails or the 
  /// server gives an unexpected response. When this happens, the client object
  /// should either attempt to call this function again or be deleted entirely.
  Future<void> connect(String ipAddress, int port) async
  {
    assert(_status == .disconnected, "Client isn't disconnected.");
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
      throw const common.AirdroidNetworkException(
        "Failed to send network request.",
        null
      );
    }

    if (response.statusCode != 200) {
      _closeClient();
      throw common.AirdroidNetworkException(
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
      connectionData = ad_schema.extractConnectionData(response.body);
    } on ad_schema.TypeMismatchException catch (e) {
      _closeClient();
      throw common.AirdroidNetworkException(
        "Server returned unexpected response body:\n$e",
        200
      );
    }
    
    _deviceKey = connectionData.deviceKey;
    _authToken = connectionData.authToken;

    _encryptionKey = ad_encryption.getEncryptionKey(
      _deviceKey,
      _authToken,
    );

    _setStatus(.connected);
  }


  /// Helper function used to close the client and reset all class members.
  /// 
  /// See [disconnect] for the proper method of closing connections.
  void _closeClient()
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
    assert(_status == .connected, "Client is not connected.");

    _setStatus(.disconnecting);

    try {
      await _sendHttpGetRequest(
        _client!,
        "$_baseAddress/sdctl/comm/logout/?7bb=$_authToken"
      );
    } on common.AirdroidNetworkException {
      // ignore the error
    }

    _closeClient();
    _setStatus(.disconnected);
  }


  /// Given the [filePath] to a directory, returns a list of directory's
  /// contents.
  /// 
  /// The client must be connected to a server.
  ///
  /// [filePath] must start with a '/'.
  /// 
  /// Throws a [common.AirdroidNetworkException] if the request fails or the
  /// server gives an unexpected reponse.
  Future<List<common.DirectoryItemSpec>> queryDirectory(String filePath) async
  {
    // make sure directory can be queried
    assert(_status == .connected, "Client is not connected.");
    assert(
      filePath.isNotEmpty && filePath[0] == "/",
      "filePath must start with a '/'"
    );

    // setup address
    filePath = filePath.replaceAll("/", "%2f");
    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/query?cur_path=$filePath&7bb=$_authToken";

    // send request
    final http.Response response = await _sendHttpGetRequest(
      _client!,
      requestAddress
    );

    // extract the data and return
    final List<common.DirectoryItemSpec> directoryItems;

    try {
      directoryItems = ad_schema.extractDirectoryContents(response.body);
    } on ad_schema.TypeMismatchException catch (e) {
      throw common.AirdroidNetworkException(
        "Server returned unexpected response body:\n$e",
        200
      );
    }

    return directoryItems;
  }


  /// Given a [filePath], returns the file's stringifed contents.
  /// 
  /// The client must be connected to a server.
  /// 
  /// [filePath] must start with a '/'.
  ///
  /// Throws a [common.AirdroidNetworkException] if the network request fails.
  Future<String> fetchFile(String filePath) async
  {
    // check params
    assert(_status == .connected, "Client is not connected.");

    // setup address
    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/export?pathfile="
        "${ad_encryption.getEncryptedFilePath(filePath, _encryptionKey)}"
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
    assert(_status == .connected, "Client is not connected.");

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
    bool shouldDisconnect = ad_schema.isForbiddenResponse(response.body);

    if (shouldDisconnect) {
      _closeClient();
      return false;
    }

    _setStatus(.connected);
    return true;
  }
}
