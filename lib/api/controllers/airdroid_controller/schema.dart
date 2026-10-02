import 'package:json_schema/json_schema.dart' as json_schema;
import 'dart:convert' as convert;

/* ============================== Constants ============================== */

/// Regular expression for validating hex strings
final _hexRegex = RegExp(r'^[0-9a-fA-F]+$');

/// Key to access within AirDroid's connection response to get the auth token
const _authTokenJsonKey = '7bb';
/// Key to access within AirDroid's connection response to get the device key
const _deviceKeyJsonKey = 'dk';
/// Key to access within AirDroid's directory query response to get the list of
/// directory contents
const _directoryContentsJsonKey = 'list';
/// Key to access within AirDroid's directory query response to get the name of
/// each item within a directory
const _directoryItemNameJsonKey = 'name';

/// Name of the format used internally by [json_schema] for auth token type
/// validation.
const _authTokenFormatName = 'auth-token';
/// Name of the format used internally by [json_schema] for device key type
/// validation.
const _deviceKeyFormatName = 'device-key';

/* ============================== Classes ============================== */

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

/* ============================== Validators ============================== */

/// [json_schema] validator function that checks if the inputted string is a 
/// 32-character long hex string
json_schema.ValidationContext _authTokenValidator(
  json_schema.ValidationContext context,
  String instanceData
)
{
  if (instanceData.length != 32 || !_hexRegex.hasMatch(instanceData)) {
    context.addError(
      "'$_authTokenFormatName' format not accepted on '$instanceData'."
    );
  }

  return context;
}

/// [json_schema] validator function that checks if the inputted string is a 
/// 16-character long hex string
json_schema.ValidationContext _deviceKeyValidator(
  json_schema.ValidationContext context,
  String instanceData
)
{
  if (instanceData.length != 16 || !_hexRegex.hasMatch(instanceData)) {
    context.addError(
      "'$_deviceKeyFormatName' format not accepted on '$instanceData'."
    );
  }

  return context;
}

/* ============================== Schemas ============================== */

/// Map of custom formats/validators to pass to [json_schema] for custom
/// validation.
const _customFormats = {
  _deviceKeyFormatName: _deviceKeyValidator,
  _authTokenFormatName: _authTokenValidator,
};

/// The expected AirDroid connection response schema
final _connectionResponseSchema = json_schema.JsonSchema.create(
  {
    'type': 'object',
    'properties': {
      _deviceKeyJsonKey: {
        'type': 'string',
        'format': _deviceKeyFormatName,
      },
      _authTokenJsonKey: {
        'type': 'string',
        'format': _authTokenFormatName,
      },
    },
    'required': [_deviceKeyJsonKey, _authTokenJsonKey]
  },
  customFormats: _customFormats,
);

/// The expected AirDroid directory query response schema
final _listDirectorySchema = json_schema.JsonSchema.create(
  {
    'type': 'object',
    'properties': {
      _directoryContentsJsonKey: {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            _directoryItemNameJsonKey: {
              'type': 'string'
            },
          },
          'required': [_directoryItemNameJsonKey]
        },
      },
    },
    'required': [_directoryContentsJsonKey],
  },
);

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

  final json_schema.ValidationResults validationResult = 
    _connectionResponseSchema.validate(jsonData);
  
  if (!validationResult.isValid) {
    throw TypeMismatchException(validationResult.errors[0].message);
  }

  return (
    authToken: jsonData[_authTokenJsonKey],
    deviceKey: jsonData[_deviceKeyJsonKey],
  );
}

/// Given a [jsonStr] (most often returned by an AirDroid directory query
/// response), validates that the parsed JSON has the expected structure
/// returns a list of directory items, each in the form of a record.
/// 
/// Throws a [TypeMismatchException] if [jsonStr] doesn't match the expected
/// schema.
List<({String name})> extractDirectoryContents(String jsonStr)
{
  // parse json
  final dynamic jsonData = convert.jsonDecode(jsonStr);

  final json_schema.ValidationResults validationResult = 
    _listDirectorySchema.validate(jsonData);
  
  if (!validationResult.isValid) {
    throw TypeMismatchException(validationResult.errors[0].message);
  }

  // populate list and return
  final List<({String name})> directoryItems = [];

  for (final dynamic item in jsonData[_directoryContentsJsonKey]) {
    directoryItems.add((
      name: item[_directoryItemNameJsonKey],
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