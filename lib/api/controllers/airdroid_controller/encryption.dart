import 'dart:convert' as convert;
import 'dart:typed_data' as types;
import 'package:pointycastle/export.dart' as pointy_castle;

/// Converts a given [hex] string to an array of bytes.
types.Uint8List _convertHexToByteArray(String hex)
{
  final result = types.Uint8List(hex.length ~/ 2);

  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i*2, i*2 + 2), radix: 16);
  }

  return result;
}

/// Converts a given array of [bytes] to a hex string.
String _convertByteArrayToHex(types.Uint8List bytes)
  => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

/// Computes and returns an AirDroid encryption key based on the client's
/// assigned [deviceKey] and [authToken].
/// 
/// Runs an XOR cipher over the [deviceKey] using [authToken] as a source of
/// randomness.
///
/// [deviceKey] and [authToken] must be hex strings.
/// 
/// The returned encryption key is a 16 character-long hex string, encoding 8 
/// bytes' worth of data.
String getEncryptionKey(String deviceKey, String authToken)
{
  final types.Uint8List keyBytes = _convertHexToByteArray(deviceKey);
  final types.Uint8List authTokenBytes = _convertHexToByteArray(
    authToken.substring(3, 7),
  );

  for (int i = 0; i < keyBytes.length; i++) {
    keyBytes[i] = keyBytes[i] ^ authTokenBytes[i % authTokenBytes.length];
  }

  return _convertByteArrayToHex(keyBytes);
}

/// Computes and returns an [filePath]'s AirDroid hash.
///
/// Runs a DES + ECB + PKCS7 encryption algorithm on the [filePath] using an 
/// encryption [key] to get the final hash.
/// 
/// [filePath] must start with '/'.
/// [key] must be a be a hex string with 8 bytes' worth of data (16 characters);
/// see [getEncryptionKey] for details.
String getEncryptedFilePath(String filePath, String key)
{
  // check parameters
  assert(key.length == 16, "Encryption key must be 16 characters long.");

  // generate key
  // (raw DES isn't supported, so we need to append the key to itself two times)
  final keyBytes = _convertHexToByteArray(key);

  final tripleKey = types.Uint8List(24);
  tripleKey.setRange(0, 8, keyBytes);
  tripleKey.setRange(8, 16, keyBytes);
  tripleKey.setRange(16, 24, keyBytes);

  // create the cipher
  final cipher = pointy_castle.PaddedBlockCipherImpl(
    pointy_castle.PKCS7Padding(),
    pointy_castle.ECBBlockCipher(pointy_castle.DESedeEngine()),
  );

  cipher.init(
    true,
    pointy_castle.PaddedBlockCipherParameters<pointy_castle.KeyParameter, Null>(
      pointy_castle.KeyParameter(tripleKey),
      null,
    ),
  );

  // run the cipher and return the data
  final fetchedData = cipher.process(types.Uint8List.fromList(
    convert.utf8.encode(filePath)
  ));

  return fetchedData.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Tests the encryption functions in this file by printing to console.
/// 
/// Currently unused as everything is working as intended.
// void printTests()
// {
//   String deviceKey = "4A61D90A5071C3D3";
//   String authToken = "cc32ed7e89e1cde5152b723544dec5bf";
//   String key = "64b6f7dd7ea6ed04";

//   String dataToEncrypt = "/sdcard/Download/a";
//   String encryptedData = "b047d685f9bd8b9d92ae0d2e604470cdf0277458989b0e15";

//   print(
//     "Generating device key (expecting $key): "
//     "${getEncryptionKey(deviceKey, authToken)}"
//   );

//   print(
//     "Encrypting filepath '$dataToEncrypt' (expecting $encryptedData): "
//     "${getEncryptedFilePath(dataToEncrypt, key)}"
//   );
// }