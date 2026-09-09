import './encryption.dart' as airdroid_encryption;

import 'package:http/http.dart' as http;

import 'dart:convert';

class AirdroidConnection {
  String _baseAddress = "";
  String _authToken = "";
  String _deviceKey = "";
  String _encryptionKey = "";

  bool isConnected() {
    return _authToken.isNotEmpty && _deviceKey.isNotEmpty;
  }

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
          if (entry['name'] is! String) continue;
          found.add(entry['name']);
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
