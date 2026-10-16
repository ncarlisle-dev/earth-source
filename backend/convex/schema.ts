import { defineSchema, defineTable, SystemFields } from 'convex/server';
import * as z from 'zod';
import { zid, zodOutputToConvex } from 'convex-helpers/server/zod4';
import { Id, TableNames } from './_generated/dataModel';

/* =========================== Helper types =========================== */

/**
 * Zod type defining a latitude value. Must be a number between -90 and 90,
 * inclusive.
 */
const zLatitude = z.number().gte(-90).lte(90);

/**
 * Zod type defining a longitude value. Must be a number between -180 and 180
 * inclusive.
 */
const zLongitude = z.number().gte(-180).lte(180);

/**
 * Zod type defining the shape of a coordinate object. Consists of a
 * {@link zLatitude} and {@link zLongitude} field.
 */
const zCoordinate = z.object({
  latitude: zLatitude,
  longitude: zLongitude
});

/** Zod type defining a valid width value. Must be a number > 0 and <= 360. */
const zWidth = z.number().gt(0).lte(360);
/** Zod type defining a valid height value. Must be a number > 0 and <= 180. */
const zHeight= z.number().gt(0).lte(180);

/**
 * Zod type defining a valid timestamp. Must be an integer >= 0. Represents
 * milliseconds since epoch.
 */
export const zTimestamp = z.int().gte(0);

/** The type of a timestamp, derived from {@link zTimestamp}. */
export type Timestamp = z.infer<typeof zTimestamp>;

/** Helper type that gets the Convex DB-only fields for the provided table. */
type DbFields<S extends TableNames> = SystemFields & { _id: Id<S> };

/* =========================== DB types =========================== */

/** Zod type defining a user in the database. */
export const zDbUser = z.object({
  name: z.string().nonempty(),
  token: z.string().nonempty(),
});
/** A user in the database, derived from {@link zDbUser}. */
export type DbUser = z.infer<typeof zDbUser> & DbFields<"users">;

/** Zod type defining a connection spec in the database. */
export const zDbConnectionSpec = z.object({
  userId: zid("users"),
  ipAddress: z.string().regex(/^(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$/), // IPv4 regex
  port: z.int().gte(0).lte(65535),
});
/** A connection spec in the database, derived from {@link zDbConnectionSpec}. */
export type DbConnectionSpec = z.infer<typeof zDbConnectionSpec> & DbFields<"connectionSpecs">;


/** Zod type defining a unit in the database. */
export const zDbUnit = z.object({
  projectId: zid("projects"),
  name: z.string(),
  description: z.string(),
  lastUpdated: zTimestamp,
  topLeftCoords: zCoordinate,
  width: zWidth,
  height: zHeight,
  pointInterval: z.number().gt(0),
});
/** A unit in the database derived from {@link zDbUnit}. */
export type DbUnit = z.infer<typeof zDbUnit> & DbFields<"units">;


/** Zod type defining a layer in the database. */
export const zDbLayer = z.object({
  projectId: zid("projects"),
  name: z.string(),
  description: z.string(),
  lastUpdated: zTimestamp,
});
/** A layer in the database, derived from {@link zDbLayer}. */
export type DbLayer = z.infer<typeof zDbLayer> & DbFields<"layers">;


/**
 * Zod type defining the minimum fields required for a data spec in the 
 * database.
 */
const zDbBaseDataSpec = z.object({
  projectId: zid("projects"),
  storageId: zid("_storage"),
  fileName: z.string().nonempty(),
  description: z.string(),
  lastUpdated: zTimestamp,
  numPoints: z.int().gte(0),
  size: z.int().gte(0),
});

/** Zod type defining a pXRF data spec in the database. */
export const zDbPxrfDataSpec = zDbBaseDataSpec.extend({
  kind: z.literal("pxrf"),
});
/** A pXRF data spec in the database, derived from {@link zDbPxrfDataSpec}. */
export type DbPxrfDataSpec = z.infer<typeof zDbPxrfDataSpec> & DbFields<"dataSpecs">;

/** Zod type defining a training data spec in the database. */
export const zDbTrainingDataSpec = zDbBaseDataSpec.extend({
  kind: z.literal("training"),
});
/** A training data spec in the database, derived from {@link zDbTrainingDataSpec}. */
export type DbTrainingDataSpec = z.infer<typeof zDbTrainingDataSpec> & DbFields<"dataSpecs">;

/**
 * Zod type defining a data spec in the database. A discriminated union on the
 * "kind" field is used to differentiate subtypes.
 */
const zDbDataSpec = z.discriminatedUnion("kind", [zDbPxrfDataSpec, zDbTrainingDataSpec]);
/** A data spec in the database, derived from {@link zDbDataSpec}. */
export type DbDataSpec = z.infer<typeof zDbDataSpec> & DbFields<"dataSpecs">;


/** Zod type defining the minimum fields required for a job in the database. */
const zDbBaseJob = z.object({
  projectId: zid("projects"),
  outputStorageId: zid("_storage").nullable(),
  name: z.string(),
  description: z.string(),
  lastUpdated: zTimestamp,
  status: z.union([
    z.literal("starting"),
    z.literal("running"),
    z.literal("complete"),
    z.literal("failed"),
  ]),
});

/** Zod type defining a prediction job in the database. */
export const zDbPredictionJob = zDbBaseJob.extend({
  kind: z.literal("prediction"),
  layerId: zid("layers"),
  modelId: zid("jobs"),
  dataAssignments: z.record(zid("units"), zid("dataSpecs").nullable()),
});
/** A prediction job in the database, dervied from {@link zDbPredictionJob}. */
export type DbPredictionJob = z.infer<typeof zDbPredictionJob> & DbFields<"jobs">;

/** Zod type defining a training job in the database. */
export const zDbTrainingJob = zDbBaseJob.extend({
  kind: z.literal("training"),
  trainingDataSpecId: zid("dataSpecs"),
});
/** A training job in the database, dervied from {@link zDbTrainingJob}. */
export type DbTrainingJob = z.infer<typeof zDbTrainingJob> & DbFields<"jobs">;

/**
 * Zod type defining a job in the database. A discriminated union on the "kind"
 * field is used to differentiate subtypes.
 */
export const zDbJob = z.discriminatedUnion(
  "kind",
  [zDbPredictionJob, zDbTrainingJob]
);
/** A job in the databse, derived from {@link zDbJob}. */
export type DbJob = z.infer<typeof zDbJob> & DbFields<"jobs">


/** Zod type defining a project in the database. */
export const zDbProject = z.object({
  userId: zid("users"),
  name: z.string(),
  description: z.string(),
  lastUpdated: zTimestamp,
  topLeftCoords: zCoordinate,
  width: zWidth,
  height: zHeight,
  layerIds: z.array(zid("layers")),
  unitIds: z.array(zid("units")),
  pxrfDataSpecIds: z.array(zid("dataSpecs")),
  trainingDataSpecIds: z.array(zid("dataSpecs")),
  dataAssignments: z.record(zid("layers"), z.record(zid("units"), zid("dataSpecs").nullable())), 
  predictionJobIds: z.array(zid("jobs")),
  trainingJobIds: z.array(zid("jobs")),
});
/** A project in the database, derived from {@link zDbProject}. */
export type DbProject = z.infer<typeof zDbProject> & DbFields<"projects">;

/* =========================== Frontend types =========================== */

/** Zod type defining a user to be returned by the API. */
export const zUser = zDbUser
  .omit({ token: true })
  .extend({ id: zid("users") });
/** A user as returned by the API. Derived from {@link zUser}. */
export type User = z.infer<typeof zUser>;

/** Zod type defining a layer to be returned by the API. */
export const zLayer = zDbLayer
  .omit({
    projectId: true,
  })
  .extend({
    id: zid("layers"),
    createdAt: zTimestamp,
  });
/** A layer as returned by the API. Derived from {@link zLayer}. */
export type Layer = z.infer<typeof zLayer>;

/** Zod type defining a layer to be returned by the API. */
export const zUnit = zDbUnit
  .omit({
    projectId: true,
  })
  .extend({
    id: zid("units"),
    createdAt: zTimestamp,
  });
/** A unit as returned by the API. Derived from {@link zUnit}. */
export type Unit = z.infer<typeof zUnit>;

/** Zod type defining a pXRF data spec to be returned by the API. */
export const zPxrfDataSpec = zDbPxrfDataSpec
  .omit({
    kind: true,
    projectId: true,
    storageId: true,
  })
  .extend({
    id: zid("dataSpecs"),
    createdAt: zTimestamp,
  });
/**
 * A pXRF data spec as returned by the API. Derived from
 * {@link zPxrfDataSpec}.
 */
export type PxrfDataSpec = z.infer<typeof zPxrfDataSpec>;

/** Zod type defining a training data spec to be returned by the API. */
export const zTrainingDataSpec = zDbTrainingDataSpec
  .omit({
    kind: true,
    projectId: true,
    storageId: true,
  })
  .extend({
    id: zid("dataSpecs"),
    createdAt: zTimestamp,
  });
/**
 * A training data spec as returned by the API. Derived from
 * {@link zTrainingDataSpec}.
 */
export type TrainingDataSpec = z.infer<typeof zTrainingDataSpec>;

/** Zod type defining a prediction job to be returned by the API. */
export const zPredictionJob = zDbPredictionJob
  .omit({
    projectId: true,
    kind: true,
    outputStorageId: true,
  })
  .extend({
    id: zid("jobs"),
    createdAt: zTimestamp,
  });
/**
 * A prediction job as returned by the API. Derived from
 * {@link zPredictionJob}.
 */
export type PredictionJob = z.infer<typeof zPredictionJob>;

/** Zod type defining a training job to be returned by the API. */
export const zTrainingJob = zDbTrainingJob
  .omit({
    projectId: true,
    kind: true,
    outputStorageId: true,
  })
  .extend({
    id: zid("jobs"),
    createdAt: zTimestamp,
  });
/**
 * A training job as returned by the API. Derived from {@link zTrainingJob}.
 */
export type TrainingJob = z.infer<typeof zTrainingJob>;

/**
 * Zod type defining a project to be returned by the API. The primary
 * difference is that ID fields are replaced with actual DB instances.
 */
export const zProject = zDbProject
  .pick({
    name: true,
    description: true,
    lastUpdated: true,
    width: true,
    height: true,
    topLeftCoords: true,
    dataAssignments: true,
  })
  .extend({
    id: zid("projects"),
    createdAt: zTimestamp,
    layers: z.array(zLayer),
    units: z.array(zUnit),
    pxrfData: z.array(zPxrfDataSpec),
    trainingData: z.array(zTrainingDataSpec),
    predictions: z.array(zPredictionJob),
    models: z.array(zTrainingJob),
  })
/** A project as returned by the API. Derived from {@link zProject}. */
export type Project = z.infer<typeof zProject>;

/* ============================ Begin schema ============================ */

// define and export the schema to Convex
export default defineSchema({
  users: defineTable(zodOutputToConvex(zDbUser))
    .index("by_token", ["token"]),

  projects: defineTable(zodOutputToConvex(zDbProject))
    .index("by_userId", ["userId"]),

  units: defineTable(zodOutputToConvex(zDbUnit))
    .index("by_projectId", ["projectId"]),

  layers: defineTable(zodOutputToConvex(zDbLayer))
    .index("by_projectId", ["projectId"]),
  
  dataSpecs: defineTable(zodOutputToConvex(zDbDataSpec))
    .index("by_projectId", ["projectId"])
    .index("by_projectId_kind", ["projectId", "kind"]),

  connectionSpecs: defineTable(zodOutputToConvex(zDbConnectionSpec))
    .index("by_userId", ["userId"]),
  
  jobs: defineTable(zodOutputToConvex(zDbJob))
    .index("by_projectId", ["projectId"])
    .index("by_projectId_status", ["projectId", "status"])
    .index("by_projectId_kind", ["projectId", "kind"])
});