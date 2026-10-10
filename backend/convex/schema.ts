import { defineSchema, defineTable, SystemFields } from 'convex/server';
import * as z from 'zod';
import { zid, zodOutputToConvex } from 'convex-helpers/server/zod4';
import { Id, TableNames } from './_generated/dataModel';

/* =========================== Helper types =========================== */

const zLatitude = z.number().gte(-90).lte(90);
const zLongitude = z.number().gte(-180).lte(180);
const zCoordinate = z.object({
  latitude: zLatitude,
  longitude: zLongitude
});

const zWidth = z.number().gt(0).lte(360);
const zHeight= z.number().gt(0).lte(180);

export const zTimestamp = z.int().gte(0);
export type Timestamp = z.infer<typeof zTimestamp>;

/** Helper type that gets the Convex DB fields for a given table. */
type DbFields<S extends TableNames> = SystemFields & { _id: Id<S> };

/* =========================== DB types =========================== */

export const zDbUser = z.object({
  name: z.string().nonempty(),
  token: z.string().nonempty(),
});
export type DbUser = z.infer<typeof zDbUser> & DbFields<"users">;


export const zDbConnectionSpec = z.object({
  userId: zid("users"),
  ipAddress: z.string().regex(/^(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$/), // IPv4 regex
  port: z.int().gte(0).lte(65535),
});
export type DbConnectionSpec = z.infer<typeof zDbConnectionSpec> & DbFields<"connectionSpecs">;


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
export type DbUnit = z.infer<typeof zDbUnit> & DbFields<"units">;


export const zDbLayer = z.object({
  projectId: zid("projects"),
  name: z.string(),
  description: z.string(),
  lastUpdated: zTimestamp,
});
export type DbLayer = z.infer<typeof zDbLayer> & DbFields<"layers">;


const zDbBaseDataSpec = z.object({
  projectId: zid("projects"),
  storageId: zid("_storage"),
  fileName: z.string().nonempty(),
  description: z.string(),
  lastUpdated: zTimestamp,
  numPoints: z.int().gte(0),
  size: z.int().gte(0),
});

export const zDbPxrfDataSpec = zDbBaseDataSpec.extend({
  kind: z.literal("pxrf"),
});
export type DbPxrfDataSpec = z.infer<typeof zDbPxrfDataSpec> & DbFields<"dataSpecs">;

export const zDbTrainingDataSpec = zDbBaseDataSpec.extend({
  kind: z.literal("training"),
});
export type DbTrainingDataSpec = z.infer<typeof zDbTrainingDataSpec> & DbFields<"dataSpecs">;

const zDbDataSpec = z.discriminatedUnion("kind", [zDbPxrfDataSpec, zDbTrainingDataSpec]);
export type DbDataSpec = z.infer<typeof zDbDataSpec> & DbFields<"dataSpecs">;


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

export const zDbPredictionJob = zDbBaseJob.extend({
  kind: z.literal("prediction"),
  layerId: zid("layers"),
  modelId: zid("jobs"),
  dataAssignments: z.record(zid("units"), zid("dataSpecs").nullable()),
});
export type DbPredictionJob = z.infer<typeof zDbPredictionJob> & DbFields<"jobs">;

export const zDbTrainingJob = zDbBaseJob.extend({
  kind: z.literal("training"),
  trainingDataSpecId: zid("dataSpecs"),
});
export type DbTrainingJob = z.infer<typeof zDbTrainingJob> & DbFields<"jobs">;

export const zDbJob = z.discriminatedUnion(
  "kind",
  [zDbPredictionJob, zDbTrainingJob]
);
export type DbJob = z.infer<typeof zDbJob> & DbFields<"jobs">


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

export type DbProject = z.infer<typeof zDbProject> & DbFields<"projects">;

/* =========================== Frontend types =========================== */

export const zUser = zDbUser
  .omit({ token: true })
  .extend({ id: zid("users") });
export type User = z.infer<typeof zUser>;

export const zLayer = zDbLayer
  .omit({
    projectId: true,
  })
  .extend({
    id: zid("layers"),
    createdAt: zTimestamp,
  });
export type Layer = z.infer<typeof zLayer>;

export const zUnit = zDbUnit
  .omit({
    projectId: true,
  })
  .extend({
    id: zid("units"),
    createdAt: zTimestamp,
  });
export type Unit = z.infer<typeof zUnit>;

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
export type PxrfDataSpec = z.infer<typeof zPxrfDataSpec>;

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
export type TrainingDataSpec = z.infer<typeof zTrainingDataSpec>;

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
export type PredictionJob = z.infer<typeof zPredictionJob>;

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
export type TrainingJob = z.infer<typeof zTrainingJob>;

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
    owner: zDbProject.shape.userId,
    createdAt: zTimestamp,
    layers: z.array(zLayer),
    units: z.array(zUnit),
    pxrfData: z.array(zPxrfDataSpec),
    trainingData: z.array(zTrainingDataSpec),
    predictions: z.array(zPredictionJob),
    models: z.array(zTrainingJob),
  })
export type Project = z.infer<typeof zProject>;

/* ============================ Begin schema ============================ */

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