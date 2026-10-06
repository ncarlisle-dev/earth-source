import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/* ============================= Utility types ============================= */

const unitSpec = {
  name: v.string(),
  description: v.string(),
  lastUpdated: v.number(),
  topLeftCoords: v.object({
    x: v.number(),
    y: v.number(),
  }),
  width: v.number(),
  height: v.number(),
  pointIntervale: v.number(),
};

const layerSpec = {
  name: v.string(),
  description: v.string(),
  lastUpdated: v.number(),
};

const dataSpec = {
  fileName: v.string(),
  numPoints: v.number(),
  size: v.number(),
};

const job = {
  projectId: v.id("projects"),
  name: v.string(),
  description: v.string(),
  status: v.union(
    v.literal("starting"),
    v.literal("running"),
    v.literal("complete"),
    v.literal("failed"),
  ),
};

const trainingJob = {
  ...job,
};

const predictionJob = {
  ...job,
  layer: v.string(),
  modelId: v.string(),
};

/* ============================ Begin schema ============================ */

export default defineSchema({
  users: defineTable({
    name: v.string(),
    token: v.string(),
  })
    .index("by_token", ["token"]),

  projects: defineTable({
    userId: v.id("users"),
    name: v.string(),
    description: v.string(),
    layers: v.array(v.object(layerSpec)),
    units: v.array(v.object(unitSpec)),
    pxrfData: v.array(v.object(dataSpec)),
    trainingData: v.array(v.object(dataSpec)),
    dataAssignments: v.record(v.string(), v.record(v.string(), v.string())), 
    predictions: v.array(v.id("predictionJobs")),
    models: v.array(v.id("trainingJobs")),
  })
    .index("by_userId", ["userId"]),

  connectionSpecs: defineTable({
    userId: v.id("users"),
    ipAddress: v.string(),
    port: v.number(),
  })
    .index("by_userId", ["userId"])
    .index("by_userId_ipAddress_port", ["userId", "ipAddress", "port"]),
  
  predictionJobs: defineTable(predictionJob).index("by_projectId", ["projectId"]),
  trainingJobs: defineTable(trainingJob).index("by_projectId", ["projectId"]),
});
