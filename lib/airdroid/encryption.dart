import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Converts a given hexadecimal string to an array of bytes
Uint8List _convertHexToByteArray(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

/// Converts a given array of bytes to a hexadecimal string
String _convertByteArrayToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// Returns the encryption key (as hex) that should be used when encrypting
/// Airdroid file paths.
///
/// Runs an XOR cipher using the device key as a base and a substring of the
/// auth token as a source of randomness.
///
/// Both [deviceKey] and [authToken] should be hex.
String getEncryptionKey(String deviceKey, String authToken) {
  // Airdroid seems to use an XOR cipher

  final Uint8List keyBytes = _convertHexToByteArray(deviceKey);
  final Uint8List authTokenBytes = _convertHexToByteArray(
    authToken.substring(3, 7),
  );

  for (int i = 0; i < keyBytes.length; i++) {
    keyBytes[i] = keyBytes[i] ^ authTokenBytes[i % authTokenBytes.length];
  }

  return _convertByteArrayToHex(keyBytes);
}

/// Returns a file path's AirDroid hash.
///
/// Runs a DES + ECB + PKCS7 encryption algorithm on the filepath, returning
/// the "pathfile" HTTP query parameter required by AirDroid when downloading
/// files.
///
/// [filePath] must start with '/' to get the correct return value.
/// [key] must be a be a hexadecimal string with 8 bytes.
String getEncryptedFilePath(String filePath, String key) {
  // generate key
  // (raw DES isn't supported, so need to append the key to itself two times)

  final keyBytes = _convertHexToByteArray(key);

  final tripleKey = Uint8List(24);
  tripleKey.setRange(0, 8, keyBytes);
  tripleKey.setRange(8, 16, keyBytes);
  tripleKey.setRange(16, 24, keyBytes);

  // create the cipher

  final cipher = PaddedBlockCipherImpl(
    PKCS7Padding(),
    ECBBlockCipher(DESedeEngine()),
  );

  cipher.init(
    true,
    PaddedBlockCipherParameters<KeyParameter, Null>(
      KeyParameter(tripleKey),
      null,
    ),
  );

  // run the cipher and return the data

  final fetchedData = cipher.process(Uint8List.fromList(utf8.encode(filePath)));

  return fetchedData.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void printTests() {
  String deviceKey = "4A61D90A5071C3D3";
  String authToken = "cc32ed7e89e1cde5152b723544dec5bf";
  String key = "64b6f7dd7ea6ed04";

  String dataToEncrypt = "/sdcard/Download/a";
  String encryptedData = "b047d685f9bd8b9d92ae0d2e604470cdf0277458989b0e15";

  print(
    "Generating device key (expecting $key): ${getEncryptionKey(deviceKey, authToken)}",
  );

  print(
    "Encrypting filepath '$dataToEncrypt' (expecting $encryptedData): ${getEncryptedFilePath(dataToEncrypt, key)}",
  );
}
