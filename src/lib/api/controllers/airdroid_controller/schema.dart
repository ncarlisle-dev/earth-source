import '../../common/common.dart' as common;
import 'package:dzod/dzod.dart' as dzod;
import 'dart:convert' as convert;

final _z = dzod.z;

/* ============================== Types ============================== */

/// Regular expression for validating hex strings
// final _hexRegex = RegExp(r'^[0-9a-fA-F]+$');

final _zAuthResponse = _z.object({
  '7bb': _z.string().length(32).hex(),
  'dk':  _z.string().length(16).hex(),
});

final _zCount = _z.integer().min(0).transform((val) => val.toInt());

final _zDirectoryContentsResponse = _z.object({
  'list': _z.array(_z.object({
    'name':          _z.string(),
    'type':          _zCount,
    'size':          _zCount,
    'last_modified': _zCount,
  })),
});

/* ============================== Utility ============================== */

/// Thrown when data doesn't match the expected type/schema.
class TypeMismatchException implements Exception
{
  /// The error message.
  final String message;

  const TypeMismatchException(this.message);

  @override
  String toString()
    => message;
}

/* ============================== Functions ============================== */

/// Given a [jsonStr] (most often returned by an AirDroid server connection
/// response), validates that the parsed JSON has the required fields and 
/// returns them in the form of a record.
/// 
/// Throws a [TypeMismatchException] if [jsonStr] doesn't match the expected
/// schema.
({String authToken, String deviceKey}) extractConnectionData(String jsonStr)
{
  final dynamic jsonData = convert.jsonDecode(jsonStr);

  final validationResult = _zAuthResponse.validate(jsonData);
  
  if (validationResult.isFailure) {
    throw TypeMismatchException(validationResult.errors?.formattedErrors ?? "");
  }

  return (
    authToken: validationResult.data!['7bb'],
    deviceKey: validationResult.data!['dk'],
  );
}

/// Given a [jsonStr] (most often returned by an AirDroid directory query
/// response), validates that the parsed JSON has the expected structure
/// returns a list of directory items, each in the form of a record.
/// 
/// Throws a [TypeMismatchException] if [jsonStr] doesn't match the expected
/// schema.
List<common.DirectoryItemSpec> extractDirectoryContents(String jsonStr)
{
  // parse json
  final dynamic jsonData = convert.jsonDecode(jsonStr);
  final validationResult = _zDirectoryContentsResponse.validate(jsonData);
  
  if (validationResult.isFailure) {
    throw TypeMismatchException(validationResult.errors?.formattedErrors ?? "");
  }

  // populate list and return
  final List<common.DirectoryItemSpec> directoryItems = [];

  for (final dynamic item in validationResult.data!['list']) {
    directoryItems.add(common.DirectoryItemSpec(
      item['name'],
      item['type'] == 0,
      item['size'],
      DateTime.fromMillisecondsSinceEpoch(item['last_modified']),
    ));
  }

  return directoryItems;
}

/// Given a [jsonStr] (most often given by an AirDroid response), checks if
/// parsed JSON contains a "forbidden access" error.
/// 
/// Returns true if [jsonStr] has the error, false otherwise.
bool isForbiddenResponse(String jsonStr)
{
  final Map<String, dynamic> jsonData = convert.jsonDecode(jsonStr);
  return jsonData.containsKey('err') && jsonData['err'] == 'forbidden';
}