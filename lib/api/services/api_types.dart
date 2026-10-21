import 'package:dzod/dzod.dart' as dzod;
import '../common/common.dart' as common;

// NOTE: This file is effectively a copy of the API types from 
//       backend/convex/schema.ts. Anytime one of those types change, this file
//       must also be updated, and vice versa.

/// Object given by [dzod] to access types.
final _z = dzod.z;

/* ================================ Utility ================================ */

/// Zard type defining a valid ID. Must be string UUID.
final zId = _z.string().uuid();

/// Zard type defining a valid timestamp. Must be an integer >= 0. Represents
/// milliseconds since epoch.
final zTimestamp = _z.integer().min(0).transform((val) => val.toInt());

/// Zard type defining a valid width value. Must be a number > 0 and <= 360.
final _zWidth = _z.number().max(360).gt(0);
/// Zard type defining a valid height value. Must be a number > 0 and <= 180.
final _zHeight = _z.number().max(180).gt(0);

/// Zard type defining a latitude value. Must be a number between -90 and 90,
/// inclusive.
final _zLatitude = _z.number().min(-90).max(90);

/// Zard type defining a longitude value. Must be a number between -180 and 180
/// inclusive.
final _zLongitude = _z.number().min(-180).max(180);

/// Zard type defining the shape of a coordinate object. Is a map containing a
/// [_zLatitude] and [_zLongitude] field.
final _zCoordinate = _z.object({
  'latitude':  _zLatitude,
  'longitude': _zLongitude
});

/* ================================== User ================================== */

class ApiUser
{
  final String id;
  final String name;

  ApiUser({ required this.id, required this.name });

  factory ApiUser.fromMap(Map<String, dynamic> map)
    => ApiUser(id: map['id'], name: map['name']);
}

final zApiUser = _z.object({
  'id':   zId,
  'name': _z.string().nonempty(),
}).transform(ApiUser.fromMap);

/* ============================ Connection spec ============================ */

class ApiConnectionSpec
{
  final String id;
  final String userId;
  final String ipAddress;
  final int    port;
  final int    createdAt;

  ApiConnectionSpec({
    required this.id,
    required this.userId,
    required this.ipAddress,
    required this.port,
    required this.createdAt,
  });

  factory ApiConnectionSpec.fromMap(Map<String, dynamic> map)
    => ApiConnectionSpec(
        id:        map['id'],
        userId:    map['userId'],
        ipAddress: map['ipAddress'],
        port:      map['port'],
        createdAt: map['createdAt'],
      );
}

final _ipv4AddrRegex = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[09][0-9]?)\.){3}'
  r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
);

final zApiConnectionSpec = _z.object({
  'id':        zId,
  'userId':    zId,
  'ipAddress': _z.string().regex(_ipv4AddrRegex),
  'port':      _z.integer().min(0).max(65535),
  'createdAt': zTimestamp,
}).transform(ApiConnectionSpec.fromMap);

/* ================================= Layer ================================= */

class ApiLayer
{
  final String id;
  final String name;
  final String description;
  final int    createdAt;
  final int    lastUpdated;

  ApiLayer({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ApiLayer.fromMap(Map<String, dynamic> map)
    => ApiLayer(
        id:          map['id'],
        name:        map['name'],
        description: map['description'],
        createdAt:   map['createdAt'],
        lastUpdated: map['lastUpdated'],
      );
}

final zApiLayer = _z.object({
  'id':          zId,
  'createdAt':   zTimestamp,
  'lastUpdated': zTimestamp,
  'name':        _z.string(),
  'description': _z.string(),
}).transform(ApiLayer.fromMap);

/* ================================= Unit ================================= */

class ApiUnit
{
  final String                                  id;
  final String                                  name;
  final String                                  description;
  final ({ double latitude, double longitude }) topLeftCoords;
  final double                                  width;
  final double                                  height;
  final double                                  pointInterval;
  final int                                     createdAt;
  final int                                     lastUpdated;

  ApiUnit({
    required this.id,
    required this.name,
    required this.description,
    required this.topLeftCoords,
    required this.width,
    required this.height,
    required this.pointInterval,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ApiUnit.fromMap(Map<String, dynamic> map)
    => ApiUnit(
        id:            map['id'],
        name:          map['name'],
        description:   map['description'],
        width:         map['width'],
        height:        map['height'],
        pointInterval: map['pointInterval'],
        createdAt:     map['createdAt'],
        lastUpdated:   map['lastUpdated'],
        topLeftCoords: (
          latitude:    map['topLeftCoords']['latitude'],
          longitude:   map['topLeftCoords']['longitude'],
        ),
      );
}

final zApiUnit = _z.object({
  'id':            zId,
  'name':          _z.string(),
  'description':   _z.string(),
  'width':         _zWidth,
  'height':        _zHeight,
  'pointInterval': _z.number().min(0),
  'createdAt':     zTimestamp,
  'lastUpdated':   zTimestamp,
  'topLeftCoords': _zCoordinate,
}).transform(ApiUnit.fromMap);

/* ============================ Data spec (base) ============================ */

abstract class _ApiDataSpec
{
  final String id;
  final String fileName;
  final String description;
  final int    numPoints;
  final int    size;
  final int    lastUpdated;
  final int    createdAt;

  _ApiDataSpec({
    required this.id,
    required this.fileName,
    required this.description,
    required this.numPoints,
    required this.size,
    required this.lastUpdated,
    required this.createdAt,
  });
}

final _zApiDataSpec = _z.object({
  'id':          zId,
  'fileName':    _z.string().nonempty(),
  'description': _z.string(),
  'numPoints':   _z.integer().min(0),
  'size':        _z.integer().min(0),
  'lastUpdated': zTimestamp,
  'createdAt':   zTimestamp,
});

/* ============================= pXRF data spec ============================= */

class ApiPxrfDataSpec extends _ApiDataSpec
{
  ApiPxrfDataSpec({
    required super.id,
    required super.fileName,
    required super.description,
    required super.numPoints,
    required super.size,
    required super.lastUpdated,
    required super.createdAt,
  });

  factory ApiPxrfDataSpec.fromMap(Map<String, dynamic> map)
    => ApiPxrfDataSpec(
      id:          map['id'],
      fileName:    map['fileName'],
      description: map['description'],
      numPoints:   map['numPoints'],
      size:        map['size'],
      lastUpdated: map['lastUpdated'],
      createdAt:   map['createdAt'],
    );
}

final zApiPxrfDataSpec = _zApiDataSpec
  .extend({})
  .transform(ApiPxrfDataSpec.fromMap);

/* =========================== Training data spec =========================== */

class ApiTrainingDataSpec extends _ApiDataSpec
{
  ApiTrainingDataSpec({
    required super.id,
    required super.fileName,
    required super.description,
    required super.numPoints,
    required super.size,
    required super.lastUpdated,
    required super.createdAt,
  });

  factory ApiTrainingDataSpec.fromMap(Map<String, dynamic> map)
    => ApiTrainingDataSpec(
      id:          map['id'],
      fileName:    map['fileName'],
      description: map['description'],
      numPoints:   map['numPoints'],
      size:        map['size'],
      lastUpdated: map['lastUpdated'],
      createdAt:   map['createdAt'],
    );
}

final zApiTrainingDataSpec = _zApiDataSpec
  .extend({})
  .transform(ApiTrainingDataSpec.fromMap);

/* =============================== Job (base) =============================== */

abstract class _ApiJob
{
  final String           id;
  final String           name;
  final String           description;
  final int              createdAt;
  final int              lastUpdated;
  final common.JobStatus status;

  _ApiJob({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastUpdated,
    required this.status,
  });
}

final _zApiJob = _z.object({
  'id':          zId,
  'name':        _z.string(),
  'description': _z.string(),
  'createdAt':   zTimestamp,
  'lastUpdated': zTimestamp,
  'status':      _z.enum_(common.JobStatus.values as List<String>),
});

/* ============================= Prediction job ============================= */

class ApiPredictionJob extends _ApiJob
{
  final String layerId;
  final String modelId;
  final Map<String, Map<String, ApiPxrfDataSpec?>> dataAssignments;

  ApiPredictionJob({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
    required super.lastUpdated,
    required super.status,
    required this.layerId,
    required this.modelId,
    required this.dataAssignments,
  });

  factory ApiPredictionJob.fromMap(Map<String, dynamic> map)
    => ApiPredictionJob(
      id:              map['id'],
      name:            map['name'],
      description:     map['description'],
      createdAt:       map['createdAt'],
      lastUpdated:     map['lastUpdated'],
      status:          map['status'],
      layerId:         map['layerId'],
      modelId:         map['modelId'],
      dataAssignments: map['dataAssignments'],
    );
}

final zApiPredictionJob = _zApiJob.extend({
  'layerId':         zId,
  'modelId':         zId,
  'dataAssignments': _z.record(
    _z.record(zId.nullable()).keySchema(zId)
  ).keySchema(zId),
});

/* ============================== Training job ============================== */

class ApiTrainingJob extends _ApiJob
{
  final String trainingDataSpecId;

  ApiTrainingJob({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
    required super.lastUpdated,
    required super.status,
    required this.trainingDataSpecId,
  });

  factory ApiTrainingJob.fromMap(Map<String, dynamic> map)
    => ApiTrainingJob(
      id:                 map['id'],
      name:               map['name'],
      description:        map['description'],
      createdAt:          map['createdAt'],
      lastUpdated:        map['lastUpdated'],
      status:             map['status'],
      trainingDataSpecId: map['trainingDataSpecId'],
    );
}

final zApiTrainingJob = _zApiJob.extend({
  'trainignDataSpecId': zId,
});

/* ================================ Project ================================ */

class ApiProject
{
  final String                                  id;
  final String                                  name;
  final String                                  description;
  final double                                  width;
  final double                                  height;
  final ({ double latitude, double longitude }) topLeftCoords;
  final Map<String, Map<String, String>>        dataAssignments;
  final List<ApiLayer>                          layers;
  final List<ApiUnit>                           units;
  final List<ApiPxrfDataSpec>                   pxrfData;
  final List<ApiTrainingDataSpec>               trainingData;
  final List<ApiPredictionJob>                  predictions;
  final List<ApiTrainingJob>                    models;
  final int                                     lastUpdated;
  final int                                     createdAt;
  
  ApiProject({
    required this.id,
    required this.name,
    required this.description,
    required this.width,
    required this.height,
    required this.topLeftCoords,
    required this.dataAssignments,
    required this.layers,
    required this.units,
    required this.pxrfData,
    required this.trainingData,
    required this.predictions,
    required this.models,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory ApiProject.fromMap(Map<String, dynamic> map)
    => ApiProject(
      id:              map['id'],
      name:            map['name'],
      description:     map['description'],
      width:           map['width'],
      height:          map['height'],
      topLeftCoords:   (
        latitude:      map['topLeftCoords']['latitude'],
        longitude:     map['topLeftCoords']['longitude'],
      ),
      dataAssignments: map['dataAssignments'],
      layers:          map['layers'],
      units:           map['units'],
      pxrfData:        map['pxrfData'],
      trainingData:    map['trainingData'],
      predictions:     map['predictions'],
      models:          map['models'],
      lastUpdated:     map['lastUpdated'],
      createdAt:       map['createdAt'],
    );
}

final zApiProject = _z.object({
  'id':              zId,
  'name':            _z.string(),
  'description':     _z.string(),
  'width':           _zWidth,
  'height':          _zHeight,
  'topLeftCoords':   _zCoordinate,
  'dataAssignments': _z.record(_z.record(zId)),
  'layers':          _z.array(zApiLayer),
  'units':           _z.array(zApiUnit),
  'pxrfData':        _z.array(zApiPxrfDataSpec),
  'trainingData':    _z.array(zApiTrainingDataSpec),
  'predictions':     _z.array(zApiPredictionJob),
  'models':          _z.array(zApiTrainingJob),
  'lastUpdated':     zTimestamp,
  'createdAt':       zTimestamp,
}).transform(ApiProject.fromMap);