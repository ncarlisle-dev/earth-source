import { QueryCtx, MutationCtx } from "./_generated/server";
import { Id } from "./_generated/dataModel";
import { internal } from "./_generated/api";

import * as z from "zod";
import { zid } from "convex-helpers/server/zod4";

import { 
  authenticateUser,
  zodMutation,
  zodQuery,
  zodInternalMutation,
  zodAction,
  InvalidRequestError,
  ResourceNotFoundError,
  UnauthorizedError,
  zodInternalQuery,
  UnknownServerError,
} from "./helper";

import {
  zDbProject,
  zLayer,
  zUnit,
  zDbPxrfDataSpec,
  zDbTrainingDataSpec,
  zDbPredictionJob,
  zDbTrainingJob,
  DbTrainingDataSpec,
  DbProject,
  DbPxrfDataSpec,
  DbPredictionJob,
  DbTrainingJob,
  Project,
  Timestamp,
  PredictionJob,
  TrainingJob,
} from "./schema";


/* =========================== Utility functions =========================== */

/**
 * Helper function that fetches a project and validates that the user may
 * read/write to it.
 * @param ctx The Convex-provided query/mutation context.
 * @param projectId ID of the project.
 * @param userId ID of the user.
 * @returns The project associated with the inputted project ID.
 */
async function getDbProject(
  ctx: QueryCtx | MutationCtx,
  projectId: Id<"projects">,
  userId: Id<"users">,
): Promise<DbProject>
{
  const dbProject = await ctx.db.get("projects", projectId);

  if (dbProject === null)
    throw new ResourceNotFoundError(`Project with ID ${projectId} not found.`);

  if (dbProject.userId !== userId) 
    throw new UnauthorizedError(
      `User does not have access to project with ID '${projectId}'.`
    );
  
  return dbProject;
}

async function validateUpdates(updates: Record<string, any>) {
    for (const key of Object.keys(updates)) {
      if (updates[key] === undefined)
        delete updates[key];
    }

    if (Object.entries(updates).length === 0)
      throw new InvalidRequestError("No updates specified.");

    return updates;
}

/* ======================== Create/delete endpoints ======================== */

export const createProject = zodMutation({
  args: {
    name: zDbProject.shape.name,
    description: zDbProject.shape.description,
    topLeftCoords: zDbProject.shape.topLeftCoords,
    width: zDbProject.shape.width,
    height: zDbProject.shape.height,
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const timestamp = Date.now();

    const projectId = await ctx.db.insert("projects", {
      userId,
      name: args.name,
      description: args.description,
      lastUpdated: timestamp,
      topLeftCoords: args.topLeftCoords,
      width: args.width,
      height: args.height,
      layerIds: [],
      unitIds: [],
      pxrfDataSpecIds: [],
      trainingDataSpecIds: [],
      dataAssignments: {}, 
      predictionJobIds: [],
      trainingJobIds: [],
    });

    return projectId;
  }
})

export const deleteProject = zodMutation({
  args: {
    id: zid("projects"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    await getDbProject(ctx, args.id, userId);
    await ctx.db.delete("projects", args.id);
  },
});

/* =========================== Getters =========================== */

export const getDbProjectQuery = zodInternalQuery({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
  },
  handler: async (ctx, args) => {
    return await getDbProject(ctx, args.projectId, args.userId);
  }
});

export const getUserProjectSpecs = zodQuery({
  handler: async (ctx) => {
    const userId = await authenticateUser(ctx);

    const projects = await ctx.db
      .query("projects")
      .withIndex(
        "by_userId", 
        (q) => q.eq("userId", userId)
      )
      .collect();
    
    return projects.map((dbProject) => ({
      id: dbProject._id,
      name: dbProject.name,
      description: dbProject.description,
      topLeft: dbProject.topLeftCoords,
      width: dbProject.width,
      height: dbProject.height,
      lastUpdated: dbProject.lastUpdated,
      createdAt: dbProject._creationTime,
      numLayers: dbProject.layerIds.length,
      numUnits: dbProject.unitIds.length,
      numPxrfData: dbProject.pxrfDataSpecIds.length,
      numTrainingData: dbProject.trainingDataSpecIds.length,
      numPredictions: dbProject.predictionJobIds.length,
      numModels: dbProject.trainingJobIds.length,
    }));
  },
});

export const getProjectById = zodQuery({
  args: {
    id: zid("projects"),
  },
  handler: async (ctx, args): Promise<Project> => {
    const userId = await authenticateUser(ctx);
    const dbProject = await getDbProject(ctx, args.id, userId);

    const project: Project = {
      id: dbProject._id,
      owner: dbProject.userId,
      name: dbProject.name,
      description: dbProject.description,
      topLeftCoords: dbProject.topLeftCoords,
      width: dbProject.width,
      height: dbProject.height,
      lastUpdated: dbProject.lastUpdated,
      createdAt: dbProject._creationTime,
      layers: [],
      units: [],
      pxrfData: [],
      trainingData: [],
      dataAssignments: dbProject.dataAssignments,
      predictions: [],
      models: [],
    };

    // fetch layers
    const layers = await ctx.db
      .query("layers")
      .withIndex("by_projectId", (q) => q.eq("projectId", args.id))
      .collect();
    
    project.layers = layers.map(dbLayer => ({
      id: dbLayer._id,
      name: dbLayer.name,
      description: dbLayer.description,
      createdAt: dbLayer._creationTime,
      lastUpdated: dbLayer.lastUpdated,
    }))

    // fetch units
    const units = await ctx.db
      .query("units")
      .withIndex("by_projectId", (q) => q.eq("projectId", args.id))
      .collect();
    
    project.units = units.map(dbUnit => ({
      id: dbUnit._id,
      name: dbUnit.name,
      description: dbUnit.description,
      createdAt: dbUnit._creationTime,
      lastUpdated: dbUnit.lastUpdated,
      topLeftCoords: dbUnit.topLeftCoords,
      width: dbUnit.width,
      height: dbUnit.height,
      pointInterval: dbUnit.pointInterval,
    }));

    // fetch pXRF data
    const pxrfDataSpecs = await ctx.db
      .query("dataSpecs")
      .withIndex(
        "by_projectId_kind",
        (q) => q
          .eq("projectId", args.id)
          .eq("kind", "pxrf"))
      .collect() as DbPxrfDataSpec[];
    
    project.pxrfData = pxrfDataSpecs.map(spec => ({
      id: spec._id,
      fileName: spec.fileName,
      description: spec.description,
      createdAt: spec._creationTime,
      lastUpdated: spec.lastUpdated,
      numPoints: spec.numPoints,
      size: spec.size,
    }));

    // fetch training data
    const trainingDataSpecs = await ctx.db
      .query("dataSpecs")
      .withIndex(
        "by_projectId_kind",
        (q) => q
          .eq("projectId", args.id)
          .eq("kind", "training"))
      .collect() as DbTrainingDataSpec[];
    
    project.trainingData = trainingDataSpecs.map(spec => ({
      id: spec._id,
      fileName: spec.fileName,
      description: spec.description,
      createdAt: spec._creationTime,
      lastUpdated: spec.lastUpdated,
      numPoints: spec.numPoints,
      size: spec.size,
    }));

    // fetch predictions
    const predictions = await ctx.db
      .query("jobs")
      .withIndex(
        "by_projectId_kind",
        (q) => q
          .eq("projectId", args.id)
          .eq("kind", "prediction")
      )
      .collect() as DbPredictionJob[];
    
    project.predictions = predictions.map(dbPrediction => ({
      id: dbPrediction._id,
      name: dbPrediction.name,
      description: dbPrediction.description,
      createdAt: dbPrediction._creationTime,
      lastUpdated: dbPrediction.lastUpdated,
      status: dbPrediction.status,
      layerId: dbPrediction.layerId,
      modelId: dbPrediction.modelId,
      dataAssignments: dbPrediction.dataAssignments,
      outputStorageId: dbPrediction.outputStorageId,
    }));

    // fetch models
    const models = await ctx.db
      .query("jobs")
      .withIndex(
        "by_projectId_kind",
        (q) => q
          .eq("projectId", args.id)
          .eq("kind", "training")
      )
      .collect() as DbTrainingJob[];
    
    project.models = models.map(dbModel => ({
      id: dbModel._id,
      name: dbModel.name,
      description: dbModel.description,
      createdAt: dbModel._creationTime,
      lastUpdated: dbModel.lastUpdated,
      status: dbModel.status,
      trainingDataSpecId: dbModel.trainingDataSpecId,
    }));

    // return
    return project;
  },
})

/* =========================== Setters =========================== */

export const setProjectMetadata = zodMutation({
  args: {
    id: zid("projects"),
    name: zDbProject.shape.name.optional(),
    description: zDbProject.shape.description.optional(),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    await getDbProject(ctx, args.id, userId);
    const { id, ...updates } = args;

    const safeUpdates = validateUpdates(updates);
    const timestamp = Date.now();

    await ctx.db.patch("projects", args.id, {
      ...safeUpdates,
      lastUpdated: timestamp,
    });

    return timestamp;
  },
})

interface ConfigureProjectSiteDbResult {
  createdLayerIds: Id<"layers">[];
  createdUnitIds: Id<"units">[];
  storageIdsToDelete: Id<"_storage">[];
  timestamp: Timestamp;
}

export const configureProjectSite = zodAction({
  args: {
    projectId: zid("projects"),

    siteTopLeftCoords: zDbProject.shape.topLeftCoords.optional(),
    siteWidth: zDbProject.shape.width.optional(),
    siteHeight: zDbProject.shape.height.optional(),

    newUnits: z.array(
      zUnit.omit({
        createdAt: true,
        lastUpdated: true,
        id: true
      })
    ).optional(),

    unitUpdates: z.record(
      zid("units"),
      zUnit.omit({
        id: true,
        createdAt: true,
        lastUpdated: true,
      }).partial(),
    ).optional(),

    unitsToDelete: z.array(zid("units")).optional(),

    newLayers: z.array(
      zLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
      })
    ).optional(),

    layerUpdates: z.record(
      zid("layers"),
      zLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
      }).partial(),
    ).optional(),

    layersToDelete: z.array(zid("layers")).optional(),
  },
  handler: async (ctx, args) => {
    // authenticate user
    const userId = await authenticateUser(ctx);

    // handle database transactions
    const dbUpdateResult = await ctx.runMutation(
      internal.projects.configureProjectSiteDb,
      {
        ...args,
        userId,
      }
    ) as ConfigureProjectSiteDbResult;

    // delete files indicated by database
    const deleteFilePromises: Promise<void>[] = [];
    for (const storageId of dbUpdateResult.storageIdsToDelete)
      deleteFilePromises.push(ctx.storage.delete(storageId));

    // TODO: Resize all prediction output files

    // await and return the updates
    await Promise.all(deleteFilePromises);

    return {
      createdUnitIds: dbUpdateResult.createdUnitIds,
      createdLayerIds: dbUpdateResult.createdLayerIds,
      timestamp: dbUpdateResult.timestamp,
    };
  }
});

export const configureProjectSiteDb = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),

    siteTopLeftCoords: zDbProject.shape.topLeftCoords.optional(),
    siteWidth: zDbProject.shape.width.optional(),
    siteHeight: zDbProject.shape.height.optional(),

    newUnits: z.array(
      zUnit.omit({
        createdAt: true,
        lastUpdated: true,
        id: true
      })
    ).optional(),

    unitUpdates: z.record(
      zid("units"),
      zUnit.omit({
        id: true,
        createdAt: true,
        lastUpdated: true,
      }).partial(),
    ).optional(),

    unitsToDelete: z.array(zid("units")).optional(),

    newLayers: z.array(
      zLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
      })
    ).optional(),

    layerUpdates: z.record(
      zid("layers"),
      zLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
      }).partial(),
    ).optional(),

    layersToDelete: z.array(zid("layers")).optional(),
  },
  handler: async (ctx, args): Promise<ConfigureProjectSiteDbResult> => {
    // verify project exists and the user is authorized
    const project = await ctx.runQuery(
      internal.projects.getDbProjectQuery,
      {
        userId: args.userId,
        projectId: args.projectId,
      }
    );

    // stop the update if any unit/layer IDs aren't in the project,
    // and make sure there are no duplicates.
    const projectLayerIds = new Set<Id<"layers">>(project.layerIds);
    const encounteredLayerIds = new Set<Id<"layers">>();
    const allRequestedLayerIds = [
      ...Object.keys(args.layerUpdates ?? {}),
      ...(args.layersToDelete ?? [])
    ] as Id<"layers">[];

    for (const layerId of allRequestedLayerIds) {
      if (!projectLayerIds.has(layerId))
        throw new InvalidRequestError(
          `Project doesn't have layer with ID '${layerId}'.`
        );

      if (encounteredLayerIds.has(layerId))
        throw new InvalidRequestError(
          `Encountered duplicate layer ID '${layerId}'.`
        );

      encounteredLayerIds.add(layerId);
    }

    const projectUnitIds = new Set<Id<"units">>(project.unitIds);
    const encounteredUnitIds = new Set<Id<"units">>();
    const allRequestedUnitIds = [
      ...Object.keys(args.unitUpdates ?? {}),
      ...(args.unitsToDelete ?? [])
    ] as Id<"units">[];

    for (const unitId of allRequestedUnitIds) {
      if (!projectUnitIds.has(unitId))
        throw new InvalidRequestError(
          `Project doesn't have unit with ID '${unitId}'.`
        );

      if (encounteredUnitIds.has(unitId))
        throw new InvalidRequestError(
          `Encountered duplicate unit ID '${unitId}'.`
        );

      encounteredUnitIds.add(unitId);
    }

    // stop the update if we are resizing the project while any predictions are
    // running.

    // TODO: find a different way of storing predictions to make this 
    //       check unnecessary

    if (args.siteWidth !== undefined || args.siteHeight !== undefined) {
      const incompleteJob = await ctx.db
        .query("jobs")
        .withIndex(
          "by_projectId_kind",
          q => q
            .eq("projectId", args.projectId)
            .eq("kind", "prediction")
        )
        .filter(q => q
          .neq(
            q.field("status"),
            "complete"
          )
        )
        .first() as DbPredictionJob;
      
      if (incompleteJob !== null)
        throw new InvalidRequestError(
          "Cannot resize project while prediction jobs are running."
        );
    }

    // stop the update if we are deleting any layers attached to a pending
    // prediction job
    const predictionJobsToDelete = await ctx.db
      .query("jobs")
      .withIndex(
        "by_projectId_kind",
        q => q
        .eq("projectId", args.projectId)
        .eq("kind", "prediction")
      )
      .filter(q => q.or(
        ...(
          (args.layersToDelete ?? []).map(
            id => q.eq(q.field("layerId"), id)
          )
        )
      ))
      .collect() as DbPredictionJob[];
    
    for (const job of predictionJobsToDelete)
      if (job.status !== 'complete')
        throw new InvalidRequestError(
          `Cannot delete a layer due to an ongoing prediction job.`
        );

    // verify the units aren't overlapping and are within site bounds

    // TODO: validate unit positions

    // begin database writes
    const timestamp = Date.now();
    const dataAssignments = project.dataAssignments;
    const storageIdsToDelete: Id<"_storage">[] = [];

    // create layers
    const createLayerPromises: Promise<Id<"layers">>[] = [];

    for (const newLayer of args.newLayers ?? []) {
      createLayerPromises.push(ctx.db.insert(
        "layers",
        {
          ...newLayer,
          projectId: args.projectId,
          lastUpdated: timestamp,
        }
      ));
    }

    // update layers
    const patchLayerPromises: Promise<void>[] = [];

    for (const [layerId, layerUpdates] of Object.entries(args.layerUpdates ?? {})) {
      // TODO: remove redundant update fields

      patchLayerPromises.push(ctx.db.patch(
        "layers",
        layerId as Id<"layers">,
        { ...layerUpdates, lastUpdated: timestamp, }
      ))
    }

    // delete layers
    const deleteLayerPromises: Promise<void>[] = [];

    for (const layerId of args.layersToDelete ?? []) {
      deleteLayerPromises.push(ctx.db.delete("layers", layerId));
      projectLayerIds.delete(layerId);
      delete dataAssignments[layerId];
    }

    const deletePredictionJobPromises: Promise<void>[] = [];
    const projectPredictionJobIds = new Set<Id<"jobs">>(
      project.predictionJobIds
    );

    for (const { _id: jobId, outputStorageId } of predictionJobsToDelete) {
      deletePredictionJobPromises.push(ctx.db.delete("jobs", jobId));
      projectPredictionJobIds.delete(jobId);
      storageIdsToDelete.push(outputStorageId!);
    }

    // create units
    const createUnitPromises: Promise<Id<"units">>[] = [];

    for (const newUnit of args.newUnits ?? []) {
      createUnitPromises.push(ctx.db.insert(
        "units",
        {
          ...newUnit,
          projectId: args.projectId,
          lastUpdated: timestamp,
        }
      ));
    }

    // update units
    const patchUnitPromises: Promise<void>[] = [];

    for (const [unitId, unitUpdates] of Object.entries(args.unitUpdates ?? {})) {
      // TODO: remove redundant update fields

      patchUnitPromises.push(ctx.db.patch(
        "units",
        unitId as Id<"units">,
        { ...unitUpdates, lastUpdated: timestamp, }
      ))
    }

    // delete units
    const deleteUnitPromises: Promise<void>[] = [];

    for (const unitId of args.unitsToDelete ?? []) {
      deleteUnitPromises.push(ctx.db.delete("units", unitId));
      projectUnitIds.delete(unitId);
    }

    for (const layerId of projectLayerIds)
      for (const unitId of args.unitsToDelete ?? [])
        delete dataAssignments[layerId][unitId];
    
    // update the project itself

    // At this point, projectLayerIds and projectUnitIds represent
    // the original site composition minus the deleted layers/units.
    // As such, we can combine them with the newly-created layer/unit
    // IDs to get the updated lists.
    const createdLayerIds = await Promise.all(createLayerPromises);
    const createdUnitIds = await Promise.all(createUnitPromises);

    const newLayerIds = [...projectLayerIds, ...createdLayerIds];
    const newPredictionIds = [...projectPredictionJobIds];
    const newUnitIds = [...projectUnitIds, ...createdUnitIds];
    
    for (const layerId of projectLayerIds)
      for (const unitId of createdUnitIds)
        dataAssignments[layerId][unitId] = null;

    for (const layerId of createdLayerIds) {
      dataAssignments[layerId] = {};

      for (const unitId of newUnitIds)
        dataAssignments[layerId][unitId] = null;
    }

    await ctx.db.patch(
      "projects",
      args.projectId,
      {
        topLeftCoords: args.siteTopLeftCoords,
        width: args.siteWidth,
        height: args.siteHeight,
        dataAssignments,
        layerIds: newLayerIds,
        predictionJobIds: newPredictionIds,
        unitIds: newUnitIds,
        lastUpdated: timestamp,
      }
    );

    // wait for any remaining updates to finish
    await Promise.all(patchLayerPromises);
    await Promise.all(deleteLayerPromises);
    await Promise.all(deletePredictionJobPromises);
    await Promise.all(patchUnitPromises);
    await Promise.all(deleteUnitPromises);

    // return
    return {
      createdLayerIds,
      createdUnitIds,
      storageIdsToDelete: predictionJobsToDelete
        .map(job => job.outputStorageId)
        .filter(id => id !== undefined) as Id<"_storage">[],
      timestamp,
    };
  }
});

/* ========================= File endpoint helpers ========================= */

/**
 * Helper function that makes sure the inputted pXRF data spec ID has an entry
 * in the database and said entry is associated with the inputted project.
 * @param ctx The Convex-provided query/mutation context.
 * @param project The project the check against.
 * @param specId The ID of the spec to verify.
 * @returns The data spec associated with inputted ID, and the index in the 
 *          project's list of pXRF data spec IDs where it is stored.
 */
async function assertProjectHasPxrfDataSpec(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  specId: Id<"dataSpecs">
)
{
  const dataSpecIndex = project.pxrfDataSpecIds.findIndex(
    (id) => id === specId
  );
  const dataSpec = await ctx.db.get("dataSpecs", specId);

  if (dataSpec === null || dataSpecIndex < -1 || dataSpec.kind !== "pxrf")
    throw new ResourceNotFoundError(
      `pXRF data spec with ID '${specId}' not found.`
    );
  
  return { dataSpec, dataSpecIndex, };
}

/**
 * Helper function that makes sure the inputted training data spec ID has an
 * entry in the database and said entry is associated with the inputted 
 * project.
 * @param ctx The Convex-provided query/mutation context.
 * @param project The project the check against.
 * @param specId The ID of the spec to verify.
 * @returns The data spec associated with inputted ID, and the index in the 
 *          project's list of training data spec IDs where it is stored.
 */
async function assertProjectHasTrainingDataSpec(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  specId: Id<"dataSpecs">
)
{
  const dataSpecIndex = project.trainingDataSpecIds.findIndex(
    (id) => id === specId
  );
  const dataSpec = await ctx.db.get("dataSpecs", specId);

  if (dataSpec === null || dataSpecIndex < -1 || dataSpec.kind !== "pxrf")
    throw new ResourceNotFoundError(
      `pXRF data spec with ID '${specId}' not found.`
    );
  
  return { dataSpec, dataSpecIndex, };
}

export const finalizePxrfFileUpload = zodInternalMutation({
  args: {
    projectId: zid("projects"),
    storageId: zid("_storage"),
    fileName: zDbPxrfDataSpec.shape.fileName,
    description: zDbPxrfDataSpec.shape.description,
    numPoints: zDbPxrfDataSpec.shape.numPoints,
    size: zDbPxrfDataSpec.shape.numPoints,
  },
  handler: async (ctx, args) => {
    const timestamp = Date.now();

    const specId = await ctx.db.insert("dataSpecs", {
      kind: "pxrf",
      lastUpdated: timestamp,
      ...args,
    });

    const { pxrfDataSpecIds } = (await ctx.db.get("projects", args.projectId))!;
    pxrfDataSpecIds.push(specId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { pxrfDataSpecIds, lastUpdated: timestamp }
    );
  }
});

export const finalizeTrainingFileUpload = zodInternalMutation({
  args: {
    projectId: zid("projects"),
    storageId: zid("_storage"),
    fileName: zDbTrainingDataSpec.shape.fileName,
    description: zDbTrainingDataSpec.shape.description,
    numPoints: zDbTrainingDataSpec.shape.numPoints,
    size: zDbTrainingDataSpec.shape.numPoints,
  },
  handler: async (ctx, args) => {
    const timestamp = Date.now();

    const specId = await ctx.db.insert("dataSpecs", {
      kind: "training",
      lastUpdated: timestamp,
      ...args,
    });

    const { trainingDataSpecIds } = (
      await ctx.db.get("projects", args.projectId)
    )!;

    trainingDataSpecIds.push(specId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { trainingDataSpecIds, lastUpdated: timestamp }
    );
  }
});

/* ========================= Public file endpoints ========================= */
// See http.ts for the uploading endpoints

export const getProjectPxrfDataUrl = zodQuery({
  args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { dataSpec } = await assertProjectHasPxrfDataSpec(
      ctx,
      project,
      args.specId
    );

    const url = await ctx.storage.getUrl(dataSpec.storageId);
    if (url === null)
      throw new UnknownServerError("File couldn't be found.");
    
    return url;
  }
});

export const setProjectPxrfDataMetadata = zodMutation({
 args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
    fileName: zDbPxrfDataSpec.shape.fileName.optional(),
    description: zDbPxrfDataSpec.shape.description.optional(),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    await assertProjectHasPxrfDataSpec(ctx, project, args.specId);

    const { projectId, specId, ...updates } = args;

    const safeUpdates = validateUpdates(updates);
    const timestamp = Date.now();

    await ctx.db.patch(
      "dataSpecs",
      args.specId,
      { ...safeUpdates, lastUpdated: timestamp }
    );

    await ctx.db.patch(
      "projects",
      project._id,
      { lastUpdated: timestamp },
    );

    return timestamp;
  }
});

export const deleteProjectPxrfData = zodMutation({
  args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);

    const { dataSpec, dataSpecIndex } = await assertProjectHasPxrfDataSpec(
      ctx,
      project,
      args.specId
    );

    const timestamp = Date.now();

    await ctx.db.delete("dataSpecs", args.specId);
    await ctx.storage.delete(dataSpec.storageId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { 
        pxrfDataSpecIds: project.pxrfDataSpecIds.toSpliced(dataSpecIndex, 1),
        lastUpdated: timestamp
      }
    );

    return timestamp;
  }
});

export const assignProjectPxrfData = zodMutation({
  args: {
    projectId: zid("projects"),
    layerId: zid("layers"),
    unitId: zid("units"),
    specId: zid("dataSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);

    if (!project.layerIds.includes(args.layerId))
      throw new InvalidRequestError(
        `Project doesn't have layer with ID '${args.layerId}'.`
      );

    if (!project.unitIds.includes(args.unitId))
      throw new InvalidRequestError(
        `Project doesn't have unit with ID '${args.unitId}'.`
      );

    await assertProjectHasPxrfDataSpec(ctx, project, args.specId);

    // TODO: assert the referenced data spec fits inside the specified unit

    const timestamp = Date.now();
    project.dataAssignments[args.layerId][args.unitId] = args.specId;

    await ctx.db.patch(
      "projects",
      args.projectId,
      {
        dataAssignments: project.dataAssignments,
        lastUpdated: timestamp,
      },
    );

    return timestamp;
  },
});

export const getProjectTrainingDataUrl = zodQuery({
  args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { dataSpec } = await assertProjectHasTrainingDataSpec(
      ctx,
      project,
      args.specId
    );

    const url = await ctx.storage.getUrl(dataSpec.storageId);
    if (url === null)
      throw new UnknownServerError("File couldn't be found.");
    
    return url;
  },
});

export const setProjectTrainingDataMetadata = zodMutation({
 args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
    fileName: zDbTrainingDataSpec.shape.fileName.optional(),
    description: zDbTrainingDataSpec.shape.description.optional(),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    await assertProjectHasTrainingDataSpec(ctx, project, args.specId);

    const { projectId, specId, ...updates } = args;

    const safeUpdates = validateUpdates(updates);
    const timestamp = Date.now();

    await ctx.db.patch(
      "dataSpecs",
      args.specId,
      { ...safeUpdates, lastUpdated: timestamp }
    );

    await ctx.db.patch(
      "projects",
      project._id,
      { lastUpdated: timestamp },
    );

    return timestamp;
  }
});

export const deleteProjectTrainingData = zodMutation({
  args: {
    projectId: zid("projects"),
    specId: zid("dataSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const timestamp = Date.now();

    const { dataSpec, dataSpecIndex } = await assertProjectHasTrainingDataSpec(
      ctx,
      project,
      args.specId
    );

    await ctx.db.delete("dataSpecs", args.specId);
    await ctx.storage.delete(dataSpec.storageId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { 
        trainingDataSpecIds: project.trainingDataSpecIds.toSpliced(
          dataSpecIndex,
          1
        ),
        lastUpdated: timestamp
      }
    );

    return timestamp;
  }
});

/* ============================= Job endpoints ============================= */

async function assertProjectHasPredictionJob(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  jobId: Id<"jobs">
)
{
  const job = await ctx.db.get("jobs", jobId);
  const jobIndex = project.predictionJobIds.findIndex(
    id => id === jobId,
  );

  if (
    job === null 
    || jobIndex < -1
    || job.kind !== "prediction"
  )
    throw new ResourceNotFoundError(
      `Prediction job with ID '${jobId}' not found.`
    );
    
  return { job, jobIndex };
}

async function assertProjectHasTrainingJob(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  jobId: Id<"jobs">
)
{
  const job = await ctx.db.get("jobs", jobId);
  const jobIndex = project.trainingJobIds.findIndex(
    id => id === jobId,
  );

  if (
    job === null 
    || jobIndex < -1
    || job.kind !== "training"
  )
    throw new ResourceNotFoundError(
      `Training job with ID '${jobId}' not found.`
    );
    
  return { job, jobIndex };
}

interface CreateDbPredictionJobResult {
  jobId: Id<"jobs">;
  timestamp: Timestamp;
};

export const createDbPredictionJob = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
    name: zDbPredictionJob.shape.name,
    description: zDbPredictionJob.shape.description,
    layerId: zDbPredictionJob.shape.layerId,
    modelId: zDbPredictionJob.shape.modelId,
  },
  handler: async (ctx, args): Promise<CreateDbPredictionJobResult> => {
    const { predictionJobIds, dataAssignments } = await getDbProject(
      ctx,
      args.projectId,
      args.userId
    );

    const timestamp = Date.now();

    // TODO: Verify that a job can be run
    // - Look at dataAssignments

    const jobId = await ctx.db.insert("jobs", {
      kind: "prediction",
      status: "starting",
      projectId: args.projectId,
      name: args.name,
      description: args.description,
      layerId: args.layerId,
      modelId: args.modelId,
      dataAssignments: dataAssignments[args.layerId],
      lastUpdated: timestamp,
      outputStorageId: null,
    });

    predictionJobIds.push(jobId);
    await ctx.db.patch(
      "projects",
      args.projectId,
      { predictionJobIds, lastUpdated: timestamp }
    );

    return {
      jobId,
      timestamp,
    };
  }
});

export const runPredictionJob = zodAction({
  args: {
    projectId: zid("projects"),
    name: zDbPredictionJob.shape.name,
    description: zDbPredictionJob.shape.description,
    layerId: zDbPredictionJob.shape.layerId,
    modelId: zDbPredictionJob.shape.modelId,
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const dbUpdateResult = await ctx.runMutation(
      internal.projects.createDbPredictionJob,
      {
        userId,
        ...args
      }
    ) as CreateDbPredictionJobResult;

    // TODO: send HTTP request with job ID

    return {
      id: dbUpdateResult.jobId,
      timestamp: dbUpdateResult.timestamp,
    };
  },
});

export const setPredictionJobMetadata = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
    name: zDbPredictionJob.shape.name.optional(),
    description: zDbPredictionJob.shape.description.optional(),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    await assertProjectHasPredictionJob(ctx, project, args.jobId);

    const { projectId, jobId, ...updates } = args;

    const safeUpdates = validateUpdates(updates);
    const timestamp = Date.now();

    await ctx.db.patch(
      "jobs",
      args.jobId,
      { ...safeUpdates, lastUpdated: timestamp }
    );

    await ctx.db.patch(
      "projects",
      project._id,
      { lastUpdated: timestamp },
    );

    return timestamp;
  },
});

export const getPredictionJob = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args): Promise<PredictionJob> => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasPredictionJob(
      ctx,
      project,
      args.jobId
    );

    return {
      id: job._id,
      name: job.name,
      description: job.description,
      createdAt: job._creationTime,
      lastUpdated: job.lastUpdated,
      dataAssignments: job.dataAssignments,
      status: job.status,
      layerId: job.layerId,
      modelId: job.modelId,
    };
  }
})

export const deletePredictionJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job, jobIndex } = await assertProjectHasPredictionJob(
      ctx,
      project,
      args.jobId
    );

    if (job.status !== "complete")
      throw new InvalidRequestError(
        `Prediction job with ID '${args.jobId}' is still ongoing.`
      );
    
    const timestamp = Date.now();
    
    await ctx.db.delete("jobs", args.jobId);
    await ctx.storage.delete(job.outputStorageId!);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { 
        predictionJobIds: project.predictionJobIds.toSpliced(jobIndex, 1),
        lastUpdated: timestamp
      }
    );

    return timestamp;
  },
});

interface CreateDbTrainingJobResult {
  jobId: Id<"jobs">;
  timestamp: Timestamp;
};

export const createDbTrainingJob = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
    name: zDbTrainingJob.shape.name,
    description: zDbTrainingJob.shape.description,
    trainingDataSpecId: zDbTrainingJob.shape.trainingDataSpecId,
  },
  handler: async (ctx, args): Promise<CreateDbTrainingJobResult> => {
    const { trainingJobIds, dataAssignments } = await getDbProject(
      ctx,
      args.projectId,
      args.userId
    );

    const timestamp = Date.now();

    // TODO: Verify that a job can be run
    // - Look at dataAssignments

    const jobId = await ctx.db.insert("jobs", {
      kind: "training",
      status: "starting",
      projectId: args.projectId,
      name: args.name,
      description: args.description,
      trainingDataSpecId: args.trainingDataSpecId,
      lastUpdated: timestamp,
      outputStorageId: null,
    });

    trainingJobIds.push(jobId);
    await ctx.db.patch(
      "projects",
      args.projectId,
      { trainingJobIds, lastUpdated: timestamp }
    );

    return {
      jobId,
      timestamp,
    };
  }
});

export const runTrainingJob = zodAction({
  args: {
    projectId: zid("projects"),
    name: zDbTrainingJob.shape.name,
    description: zDbTrainingJob.shape.description,
    trainingDataSpecId: zDbTrainingJob.shape.trainingDataSpecId,
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const dbUpdateResult = await ctx.runMutation(
      internal.projects.createDbTrainingJob,
      {
        userId,
        ...args
      }
    ) as CreateDbTrainingJobResult;

    // TODO: send HTTP request with job ID

    return {
      id: dbUpdateResult.jobId,
      timestamp: dbUpdateResult.timestamp,
    };
  },
});

export const setTrainingJobMetadata = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
    name: zDbTrainingJob.shape.name.optional(),
    description: zDbTrainingJob.shape.description.optional(),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    await assertProjectHasTrainingJob(ctx, project, args.jobId);

    const { projectId, jobId, ...updates } = args;

    const safeUpdates = validateUpdates(updates);
    const timestamp = Date.now();

    await ctx.db.patch(
      "jobs",
      args.jobId,
      { ...safeUpdates, lastUpdated: timestamp }
    );

    await ctx.db.patch(
      "projects",
      project._id,
      { lastUpdated: timestamp },
    );

    return timestamp;
  },
});

export const getTrainingJob = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args): Promise<TrainingJob> => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasTrainingJob(
      ctx,
      project,
      args.jobId
    );

    return {
      id: job._id,
      name: job.name,
      description: job.description,
      createdAt: job._creationTime,
      lastUpdated: job.lastUpdated,
      trainingDataSpecId: job.trainingDataSpecId,
      status: job.status,
    };
  }
})

export const deleteTrainingJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job, jobIndex } = await assertProjectHasTrainingJob(
      ctx,
      project,
      args.jobId
    );

    if (job.status !== "complete")
      throw new InvalidRequestError(
        `Training job with ID '${args.jobId}' is still ongoing.`
      );
    
    const timestamp = Date.now();
    
    await ctx.db.delete("jobs", args.jobId);
    await ctx.storage.delete(job.outputStorageId!);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { 
        trainingJobIds: project.trainingJobIds.toSpliced(jobIndex, 1),
        lastUpdated: timestamp
      }
    );

    return timestamp;
  },
});