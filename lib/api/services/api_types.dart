import 'package:dzod/dzod.dart' as dzod;
import '../common/common.dart' as common;

// NOTE: This file is effectively a copy of the API types from 
//       backend/convex/schema.ts. Anytime one of those types change, this file
//       must also be updated, and vice versa.

/// Object given by [dzod] to access types.
final _z = dzod.z;

/* ================================ Utility ================================ */

/// dzod type defining a valid ID. Must be a string.
final zId = _z.string();

/// dzod type defining a valid timestamp. Must be an integer >= 0. Represents
/// milliseconds since epoch.
final zTimestamp = _z.number().min(0).transform((val) => val.toInt());

/// dzod type defining a latitude value. Must be a number between -90 and 90,
/// inclusive.
final _zLatitude = _z.number().min(-90).max(90);

/// dzod type defining a longitude value. Must be a number between -180 and 180
/// inclusive.
final _zLongitude = _z.number().min(-180).max(180);

final _zUtmZone = _z.integer().min(0).max(60).transform((val) => val.toInt());

final _zCount = _z.integer().min(0).transform((val) => val.toInt());

/// dzod type defining the shape of a coordinate object. Is a map containing a
/// [_zLatitude] and [_zLongitude] field.
final _zCoordinate = _z.object({
  'latitude':  _zLatitude,
  'longitude': _zLongitude
}).transform((coordMap) => (
  latitude:  coordMap['latitude'] as double,
  longitude: coordMap['longitude'] as double,
));

final _zLayerDataAssignments = _z
  .record(zId.nullable())
  .keySchema(zId)
  .transform((assignmentMap) => assignmentMap.map((key, value) 
    => MapEntry(key, value as String?)
  ));

final _zProjectDataAssignments = _z
  .record(_zLayerDataAssignments)
  .keySchema(zId)
  .transform((assignmentMap) => assignmentMap.map((key, value) 
    => MapEntry(
      key,
      (value as Map<String, dynamic>).map((key, value)
        => MapEntry(key, value as String?)
      )
    )
  ));

final zJobStatus = _z
  .enum_(common.JobStatus.values.map((val) => val.name).toList())
  .transform((val) => val as common.JobStatus);

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
  final String ipAddress;
  final int    port;
  final int    createdAt;

  ApiConnectionSpec({
    required this.id,
    required this.ipAddress,
    required this.port,
    required this.createdAt,
  });

  factory ApiConnectionSpec.fromMap(Map<String, dynamic> map)
    => ApiConnectionSpec(
        id:        map['id'],
        ipAddress: map['ipAddress'],
        port:      map['port'],
        createdAt: map['createdAt'],
      );
}

final _ipv4AddrRegex = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
  r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
);

final zApiConnectionSpec = _z.object({
  'id':        zId,
  'ipAddress': _z.string().regex(_ipv4AddrRegex),
  'port':      _z.integer().min(0).max(65535).transform((val) => val.toInt()),
  'createdAt': zTimestamp,
}).transform(ApiConnectionSpec.fromMap);

/* ================================= Layer ================================= */

typedef ApiLayerImage = ({ String name, int size, DateTime uploadedAt, });

ApiLayerImage _convertApiLayerImageMapToRecord(Map<String, dynamic> map)
  => (
    name:       map['name'],
    size:       map['size'],
    uploadedAt: DateTime.fromMillisecondsSinceEpoch(map['uploadedAt']),
  );

class ApiLayer
{
  final String                  id;
  final String                  name;
  final String                  description;
  final List<common.Coordinate> corners;
  final int                     createdAt;
  final int                     lastUpdated;
  final ApiLayerImage?          image;

  ApiLayer({
    required this.id,
    required this.name,
    required this.description,
    required this.corners,
    required this.image,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ApiLayer.fromMap(Map<String, dynamic> map)
    => ApiLayer(
        id:           map['id'],
        name:         map['name'],
        description:  map['description'],
        corners:      map['corners'],
        image:        map['image'],
        createdAt:    map['createdAt'],
        lastUpdated:  map['lastUpdated'],
      );
}

final zApiImage = _z.object({
  'name':       _z.string(),
  'size':       _zCount,
  'uploadedAt': zTimestamp,
}).transform(_convertApiLayerImageMapToRecord);

final zApiLayer = _z.object({
  'id':           zId,
  'corners':      _z.array(_zCoordinate).length(4),
  'name':         _z.string(),
  'description':  _z.string(),
  'image':        zApiImage.nullable(),
  'createdAt':    zTimestamp,
  'lastUpdated':  zTimestamp,
}).transform(ApiLayer.fromMap);

/* ================================= Unit ================================= */

class ApiUnit
{
  final String                  id;
  final String                  name;
  final String                  description;
  final List<common.Coordinate> corners;
  final double                  pointInterval;
  final int                     createdAt;
  final int                     lastUpdated;

  ApiUnit({
    required this.id,
    required this.name,
    required this.description,
    required this.corners,
    required this.pointInterval,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ApiUnit.fromMap(Map<String, dynamic> map)
    => ApiUnit(
        id:             map['id'],
        name:           map['name'],
        description:    map['description'],
        pointInterval:  map['pointInterval'],
        corners:        map['corners'],
        createdAt:      map['createdAt'],
        lastUpdated:    map['lastUpdated'],
      );
}

final zApiUnit = _z.object({
  'id':            zId,
  'name':          _z.string(),
  'description':   _z.string(),
  'pointInterval': _z.number().min(0),
  'createdAt':     zTimestamp,
  'lastUpdated':   zTimestamp,
  'corners':       _z.array(_zCoordinate).length(4),
}).transform(ApiUnit.fromMap);

/* ============================ Data spec (base) ============================ */

abstract class _ApiDataSpec
{
  final String id;
  final String fileName;
  final String description;
  final int    numPoints;
  final int    size;
  final int    createdAt;
  final int    lastUpdated;

  _ApiDataSpec({
    required this.id,
    required this.fileName,
    required this.description,
    required this.numPoints,
    required this.size,
    required this.createdAt,
    required this.lastUpdated,
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
    required super.createdAt,
    required super.lastUpdated,
  });

  factory ApiPxrfDataSpec.fromMap(Map<String, dynamic> map)
    => ApiPxrfDataSpec(
      id:          map['id'],
      fileName:    map['fileName'],
      description: map['description'],
      numPoints:   map['numPoints'],
      size:        map['size'],
      createdAt:   map['createdAt'],
      lastUpdated: map['lastUpdated'],
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
    required super.createdAt,
    required super.lastUpdated,
  });

  factory ApiTrainingDataSpec.fromMap(Map<String, dynamic> map)
    => ApiTrainingDataSpec(
      id:          map['id'],
      fileName:    map['fileName'],
      description: map['description'],
      numPoints:   map['numPoints'],
      size:        map['size'],
      createdAt:   map['createdAt'],
      lastUpdated: map['lastUpdated'],
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
  final common.JobStatus status;
  final int              createdAt;
  final int              lastUpdated;

  _ApiJob({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
  });
}

final _zApiJob = _z.object({
  'id':          zId,
  'name':        _z.string(),
  'description': _z.string(),
  'createdAt':   zTimestamp,
  'lastUpdated': zTimestamp,
  'status':      zJobStatus,
});

/* ============================= Prediction job ============================= */

class ApiPredictionJob extends _ApiJob
{
  final String               layerId;
  final String?              modelId;
  final Map<String, String?> dataAssignments;

  ApiPredictionJob({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required this.layerId,
    required this.modelId,
    required this.dataAssignments,
    required super.createdAt,
    required super.lastUpdated,
  });

  factory ApiPredictionJob.fromMap(Map<String, dynamic> map)
    => ApiPredictionJob(
      id:              map['id'],
      name:            map['name'],
      description:     map['description'],
      status:          map['status'],
      layerId:         map['layerId'],
      modelId:         map['modelId'],
      dataAssignments: map['dataAssignments'],
      createdAt:       map['createdAt'],
      lastUpdated:     map['lastUpdated'],
    );
}

final zApiPredictionJob = _zApiJob.extend({
  'layerId':         zId,
  'modelId':         zId.nullable(),
  'dataAssignments': _zLayerDataAssignments,
}).transform(ApiPredictionJob.fromMap);

/* ============================== Training job ============================== */

class ApiTrainingJob extends _ApiJob
{
  final String trainingDataSpecId;

  ApiTrainingJob({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required this.trainingDataSpecId,
    required super.createdAt,
    required super.lastUpdated,
  });

  factory ApiTrainingJob.fromMap(Map<String, dynamic> map)
    => ApiTrainingJob(
      id:                 map['id'],
      name:               map['name'],
      description:        map['description'],
      status:             map['status'],
      trainingDataSpecId: map['trainingDataSpecId'],
      createdAt:          map['createdAt'],
      lastUpdated:        map['lastUpdated'],
    );
}

final zApiTrainingJob = _zApiJob.extend({
  'trainignDataSpecId': zId,
}).transform(ApiTrainingJob.fromMap);

/* ============================== ProjectSpec ============================== */
class ApiProjectSpec
{
  final String                  id;
  final String                  name;
  final String                  description;
  final int                     utmZone;
  final bool                    isSouthernHemisphere;
  final List<common.Coordinate> corners;
  final int                     numLayers;
  final int                     numUnits;
  final int                     numPxrfData;
  final int                     numTrainingData;
  final int                     numPredictions;
  final int                     numModels;
  final int                     createdAt;
  final int                     lastUpdated;

  ApiProjectSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.utmZone,
    required this.isSouthernHemisphere,
    required this.corners,
    required this.numLayers,
    required this.numUnits,
    required this.numPxrfData,
    required this.numTrainingData,
    required this.numPredictions,
    required this.numModels,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ApiProjectSpec.fromMap(Map<String, dynamic> map)
    => ApiProjectSpec(
      id:                   map['id'],
      name:                 map['name'],
      description:          map['description'],
      utmZone:              map['utmZone'],
      isSouthernHemisphere: map['isSouthernHemisphere'],
      corners:              map['corners'],
      numLayers:            map['numLayers'],
      numUnits:             map['numUnits'],
      numPxrfData:          map['numPxrfData'],
      numTrainingData:      map['numTrainingData'],
      numPredictions:       map['numPredictions'],
      numModels:            map['numModels'],
      createdAt:            map['createdAt'],
      lastUpdated:          map['lastUpdated'],
    );
}

final zApiProjectSpec = _z.object({
  'id':                   zId,
  'name':                 _z.string(),
  'description':          _z.string(),
  'utmZone':              _zUtmZone,
  'isSouthernHemisphere': _z.boolean(),
  'corners':              _z.array(_zCoordinate).length(4),
  'numLayers':            _zCount,
  'numUnits':             _zCount,
  'numPxrfData':          _zCount,
  'numTrainingData':      _zCount,
  'numPredictions':       _zCount,
  'numModels':            _zCount,
  'createdAt':            zTimestamp,
  'lastUpdated':          zTimestamp,
}).transform(ApiProjectSpec.fromMap);

/* ================================ Project ================================ */

class ApiProject
{
  final String                            id;
  final String                            name;
  final String                            description;
  final int                               utmZone;
  final bool                              isSouthernHemisphere;
  final List<common.Coordinate>           corners;
  final Map<String, Map<String, String?>> dataAssignments;
  final List<ApiLayer>                    layers;
  final List<ApiUnit>                     units;
  final List<ApiPxrfDataSpec>             pxrfData;
  final List<ApiTrainingDataSpec>         trainingData;
  final List<ApiPredictionJob>            predictions;
  final List<ApiTrainingJob>              models;
  final int                               lastUpdated;
  final int                               createdAt;
  
  ApiProject({
    required this.id,
    required this.name,
    required this.description,
    required this.utmZone,
    required this.isSouthernHemisphere,
    required this.lastUpdated,
    required this.corners,
    required this.dataAssignments,
    required this.layers,
    required this.units,
    required this.pxrfData,
    required this.trainingData,
    required this.predictions,
    required this.models,
    required this.createdAt,
  });

  factory ApiProject.fromMap(Map<String, dynamic> map)
    => ApiProject(
      id:                   map['id'],
      name:                 map['name'],
      description:          map['description'],
      utmZone:              map['utmZone'],
      isSouthernHemisphere: map['isSouthernHemisphere'],
      corners:              map['corners'],
      dataAssignments:      map['dataAssignments'],
      layers:               map['layers'],
      units:                map['units'],
      pxrfData:             map['pxrfData'],
      trainingData:         map['trainingData'],
      predictions:          map['predictions'],
      models:               map['models'],
      lastUpdated:          map['lastUpdated'],
      createdAt:            map['createdAt'],
    );
}

final zApiProject = _z.object({
  'id':                   zId,
  'name':                 _z.string(),
  'description':          _z.string(),
  'utmZone':              _z.integer()
                            .min(0)
                            .max(60)
                            .transform((val) => val.toInt()),
  'isSouthernHemisphere': _z.boolean(),
  'corners':              _z.array(_zCoordinate).length(4),
  'dataAssignments':      _zProjectDataAssignments,
  'layers':               _z.array(zApiLayer),
  'units':                _z.array(zApiUnit),
  'pxrfData':             _z.array(zApiPxrfDataSpec),
  'trainingData':         _z.array(zApiTrainingDataSpec),
  'predictions':          _z.array(zApiPredictionJob),
  'models':               _z.array(zApiTrainingJob),
  'lastUpdated':          zTimestamp,
  'createdAt':            zTimestamp,
}).transform(ApiProject.fromMap);