import 'package:json_schema/json_schema.dart' as json_schema;
import 'dart:convert' as convert;

/* ============================== Constants ============================== */

final _hexRegex = RegExp(r'^[0-9a-fA-F]+$');

const _authTokenJsonKey = '7bb';
const _deviceKeyJsonKey = 'dk';
const _directoryContentsJsonKey = 'list';
const _directoryItemNameJsonKey = 'name';

const _authTokenFormatName = 'auth-token';
const _deviceKeyFormatName = 'device-key';

/* ============================== Classes ============================== */

class TypeMismatchException implements Exception
{
  final String message;
  const TypeMismatchException(this.message);

  @override
  String toString()
    => message;
}

/* ============================== Validators ============================== */

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

const _customFormats = {
  _deviceKeyFormatName: _deviceKeyValidator,
  _authTokenFormatName: _authTokenValidator,
};

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

bool isForbiddenResponse(String jsonStr)
{
  final Map<String, dynamic> jsonData = convert.jsonDecode(jsonStr);
  return jsonData.containsKey('err') && jsonData['err'] == 'forbidden';
}