import './encryption.dart' as airdroid_encryption;

import 'package:http/http.dart' as http;

import 'dart:convert';

/// Represents a network/LAN connection to the AirDroid server
class AirdroidConnection {
  /// The root address all queries go through
  String _baseAddress = "";

  /// The auth token given by connecting to the server
  String _authToken = "";

  /// The device key given by conncting to the server
  String _deviceKey = "";

  /// The encryption key used by AirDroid for translating file paths into
  /// hashes
  String _encryptionKey = "";

  /// returns true if the connection is active, false otherwise
  bool isConnected() {
    return _authToken.isNotEmpty && _deviceKey.isNotEmpty;
  }

  /// Given the IP address and port of the AirDroid server, initiates a
  /// connection to it, enabling access to file downloads.
  Future<void> initiateConnection(String ipAddress, int port) async {
    _baseAddress = "http://$ipAddress:$port";
    final String requestAddress = "$_baseAddress/sdctl/comm/lite_auth/";

    try {
      final response = await http.get(Uri.parse(requestAddress));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _authToken = data['7bb'];
        _deviceKey = data['dk'];
        _encryptionKey = airdroid_encryption.getEncryptionKey(
          _deviceKey,
          _authToken,
        );
      } else {
        print('Request failed with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  /// Given a path to a directory, returns a list of directory's contents.
  /// The function will return null if the connection isn't initiaed, the
  /// file path doesn't exist, or the HTTP request fails.
  Future<List<String>?> queryDirectory(String filePath) async {
    if (!isConnected()) return null;

    filePath = filePath.replaceAll("/", "%2f");

    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/query?cur_path=$filePath&7bb=$_authToken";

    print("querying: $requestAddress");

    try {
      final response = await http.get(Uri.parse(requestAddress));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var filesList = data['list'];

        if (filesList is! List) return null;

        final List<String> found = [];

        for (var entry in filesList) {
          if (entry['name'] is String) found.add(entry['name']);
        }

        return found;
      } else {
        print('Request failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }

  /// Given a path to a file, returns the file's stringifed contents.
  /// Returns null if the connection isn't initiated, the file doesn't exist, or
  /// the HTTP request fails.
  Future<String?> fetchFile(String filePath) async {
    if (!isConnected()) return null;

    final String requestAddress =
        "$_baseAddress/sdctl/file_v21/export?pathfile=${airdroid_encryption.getEncryptedFilePath(filePath, _encryptionKey)}&7bb=$_authToken";

    print("querying: $requestAddress");

    try {
      final response = await http.get(Uri.parse(requestAddress));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Request failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }
}
