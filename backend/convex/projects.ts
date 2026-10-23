import { QueryCtx, MutationCtx } from "./_generated/server";
import { Id } from "./_generated/dataModel";
import { internal, api } from "./_generated/api";

import * as z from "zod";
import { zid } from "convex-helpers/server/zod4";

import { authenticateUser } from "./auth";

import {
  zodMutation,
  zodQuery,
  zodInternalMutation,
  zodAction,
  zodInternalQuery,
} from "./builders";

import { 
  InvalidRequestError,
  ResourceNotFoundError,
  UnauthorizedError,
  UnknownServerError,
} from "./errors";

import {
  zTimestamp,
  Timestamp,
  zDbProject,
  zDbPxrfDataSpec,
  zDbTrainingDataSpec,
  zDbPredictionJob,
  zDbTrainingJob,
  DbTrainingDataSpec,
  DbProject,
  DbPxrfDataSpec,
  DbPredictionJob,
  DbTrainingJob,
  zApiLayer,
  zApiUnit,
  ApiPredictionJob,
  ApiTrainingJob,
  ApiProject,
  ApiPxrfDataSpec,
  ApiLayer,
  ApiUnit,
  DbLayer,
  DbUnit,
  zDbLayer,
} from "./schema";


/* =========================== Utility functions =========================== */

/**
 * Helper function that fetches a project and validates that the user may
 * read/write to it. Throws a {@link ResourceNotFoundError} if the project
 * doesn't exist, and an {@link UnauthorizedError} if the user is not
 * authorized to edit the project.
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

  // TODO: Only throw a ResourceNotFoundError if the user isn't authorized?

  if (dbProject.userId !== userId) 
    throw new UnauthorizedError(
      `User does not have access to project with ID '${projectId}'.`
    );
  
  return dbProject;
}

/**
 * Helper function that removes empty fields from an update object and throws
 * an {@link InvalidRequestError} if no updates were specfied.
 * @param updates The update object.
 * @returns The non-empty update fields.
 */
async function validateUpdates<R extends Record<string, any>>(updates: R): Promise<R> {
    for (const key of Object.keys(updates)) {
      if (updates[key] === undefined)
        delete updates[key];
    }

    if (Object.entries(updates).length === 0)
      throw new InvalidRequestError("No updates specified.");

    return updates;
}

/* ======================== Create/delete endpoints ======================== */

/**
 * Mutation that creates a project given its name, description, and corner 
 * points. Returns the created project.
 */
export const createProject = zodMutation({
  args: {
    name:                 zDbProject.shape.name,
    description:          zDbProject.shape.description,
    corners:              zDbProject.shape.corners,
    utmZone:              zDbProject.shape.utmZone,
    isSouthernHemisphere: zDbProject.shape.isSouthernHemisphere,
  },
  handler: async (ctx, args): Promise<ApiProject> => {
    const userId = await authenticateUser(ctx);
    const timestamp = Date.now();

    const projectId = await ctx.db.insert("projects", {
      userId:               userId,
      name:                 args.name,
      description:          args.description,
      utmZone:              args.utmZone,
      isSouthernHemisphere: args.isSouthernHemisphere,
      lastUpdated:          timestamp,
      corners:              args.corners,
      dataAssignments:      {}, 
      layerIds:             [],
      unitIds:              [],
      pxrfDataSpecIds:      [],
      trainingDataSpecIds:  [],
      predictionJobIds:     [],
      trainingJobIds:       [],
    });

    return await ctx.runQuery(
      api.projects.getProjectById,
      { id: projectId },
    );
  }
});

/** Mutation that deletes a project given its ID. */
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

/** Helper query that fetches a project given its ID and owner. */
export const getDbProjectQuery = zodInternalQuery({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
  },
  handler: async (ctx, args) => {
    return await getDbProject(ctx, args.projectId, args.userId);
  }
});

/** Query that fetches a user's projects' metadata. */
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
      id:                   dbProject._id,
      name:                 dbProject.name,
      description:          dbProject.description,
      utmZone:              dbProject.utmZone,
      isSouthernHemisphere: dbProject.isSouthernHemisphere,
      corners:              dbProject.corners,
      lastUpdated:          dbProject.lastUpdated,
      createdAt:            dbProject._creationTime,
      numLayers:            dbProject.layerIds.length,
      numUnits:             dbProject.unitIds.length,
      numPxrfData:          dbProject.pxrfDataSpecIds.length,
      numTrainingData:      dbProject.trainingDataSpecIds.length,
      numPredictions:       dbProject.predictionJobIds.length,
      numModels:            dbProject.trainingJobIds.length,
    }));
  },
});

/** Query that fetches a project given its ID. */
export const getProjectById = zodQuery({
  args: {
    id: zid("projects"),
  },
  handler: async (ctx, args): Promise<ApiProject> => {
    const userId = await authenticateUser(ctx);
    const dbProject = await getDbProject(ctx, args.id, userId);

    const project: ApiProject = {
      id:                   dbProject._id,
      name:                 dbProject.name,
      description:          dbProject.description,
      utmZone:              dbProject.utmZone,
      isSouthernHemisphere: dbProject.isSouthernHemisphere,
      corners:              dbProject.corners,
      lastUpdated:          dbProject.lastUpdated,
      createdAt:            dbProject._creationTime,
      dataAssignments:      dbProject.dataAssignments,
      layers:               [],
      units:                [],
      pxrfData:             [],
      trainingData:         [],
      predictions:          [],
      models:               [],
    };

    // fetch layers
    const layers = await ctx.db
      .query("layers")
      .withIndex("by_projectId", (q) => q.eq("projectId", args.id))
      .collect();
    
    project.layers = layers.map(dbLayer => {
      let apiImage: ApiLayer["image"] | null = null;

      if (dbLayer.image !== null) {
        const { storageId: storageId, ...extractedFields } = dbLayer.image ?? { storageId: "" };
        apiImage = extractedFields;
      }

      return {
        id:            dbLayer._id,
        name:          dbLayer.name,
        description:   dbLayer.description,
        corners:       dbLayer.corners,
        image:         apiImage,
        createdAt:     dbLayer._creationTime,
        lastUpdated:   dbLayer.lastUpdated,
      }
    });

    // fetch units
    const units = await ctx.db
      .query("units")
      .withIndex("by_projectId", (q) => q.eq("projectId", args.id))
      .collect();
    
    project.units = units.map(dbUnit => ({
      id:            dbUnit._id,
      name:          dbUnit.name,
      description:   dbUnit.description,
      createdAt:     dbUnit._creationTime,
      lastUpdated:   dbUnit.lastUpdated,
      corners:       dbUnit.corners,
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

/**
 * Mutation that sets a project's name and description. Returns the update
 * timestamp.
 */
export const setProjectMetadata = zodMutation({
  args: {
    id: zid("projects"),
    name: zDbProject.shape.name.optional(),
    description: zDbProject.shape.description.optional(),
    utmZone: zDbProject.shape.utmZone.optional(),
    isSoutherHemisphere: zDbProject.shape.isSouthernHemisphere.optional(),
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

/**
 * Action that updates a project's location, units, and layers. Deletes any
 * jobs and files associated with deleted layers. Returns the created units' 
 * IDs, created layers' IDs, and the update timestamp.
 */
export const configureProjectSite = zodAction({
  args: {
    id: zid("projects"),

    siteCorners: zDbProject.shape.corners.optional(),

    newUnits: z.array(
      zApiUnit.omit({
        createdAt: true,
        lastUpdated: true,
        id: true
      })
    ).optional(),

    unitUpdates: z.record(
      zid("units"),
      zApiUnit.omit({
        id: true,
        createdAt: true,
        lastUpdated: true,
      }).partial(),
    ).optional(),

    unitsToDelete: z.array(zid("units")).optional(),

    newLayers: z.array(
      zApiLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
        image: true,
      })
    ).optional(),

    layerUpdates: z.record(
      zid("layers"),
      zApiLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
        image: true,
      }).partial(),
    ).optional(),

    layersToDelete: z.array(zid("layers")).optional(),
  },
  handler: async (ctx, args) => {
    // authenticate user
    const userId = await authenticateUser(ctx);

    const { id, ...siteUpdates } = args;

    // handle database transactions
    const dbUpdateResult = await ctx.runMutation(
      internal.projects.configureProjectSiteDb,
      {
        ...siteUpdates,
        projectId: id,
        userId,
      }
    ) as ConfigureProjectSiteDbResult;

    // TODO: Resize all prediction output files

    // return
    return {
      createdUnits:  dbUpdateResult.createdUnits,
      createdLayers: dbUpdateResult.createdLayers,
      timestamp:     dbUpdateResult.timestamp,
    };
  }
});

/** The return type of {@link configureProjectSiteDb}. */
interface ConfigureProjectSiteDbResult {
  createdLayers: ApiLayer[];
  createdUnits: ApiUnit[];
  timestamp: Timestamp;
}

/** Helper mutation that handles database transactions for
 * {@link configureProjectSite}. Returns a {@link ConfigureProjectSiteDbResult}.
 */
export const configureProjectSiteDb = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),

    siteCorners: zDbProject.shape.corners.optional(),

    newUnits: z.array(
      zApiUnit.omit({
        createdAt: true,
        lastUpdated: true,
        id: true
      })
    ).optional(),

    unitUpdates: z.record(
      zid("units"),
      zApiUnit.omit({
        id: true,
        createdAt: true,
        lastUpdated: true,
      }).partial(),
    ).optional(),

    unitsToDelete: z.array(zid("units")).optional(),

    newLayers: z.array(
      zApiLayer.omit({
        createdAt: true,
        lastUpdated: true,
        image: true,
        id: true,
      })
    ).optional(),

    layerUpdates: z.record(
      zid("layers"),
      zApiLayer.omit({
        createdAt: true,
        lastUpdated: true,
        id: true,
        image: true,
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

    if (args.siteCorners !== undefined) {
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
          projectId:   args.projectId,
          lastUpdated: timestamp,
          image:       null,
        },
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
    const deleteLayerImagePromises: Promise<void>[] = [];

    for (const layerId of args.layersToDelete ?? []) {
      // TODO: optimize this by putting this process in a promise array
      const layer = await ctx.db.get("layers", layerId);

      if (layer!.image !== null) 
        deleteLayerImagePromises.push(
          ctx.storage.delete(layer!.image.storageId)
        );
      
      deleteLayerPromises.push(ctx.db.delete("layers", layerId));
      projectLayerIds.delete(layerId);
      delete dataAssignments[layerId];
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
        corners: args.siteCorners ?? project.corners,
        dataAssignments,
        layerIds: newLayerIds,
        unitIds: newUnitIds,
        lastUpdated: timestamp,
      }
    );

    // get the created layers and units
    const createdDbLayerPromises: Promise<DbLayer>[] = createdLayerIds.map(async (id) => {
      const dbLayer = await ctx.db.get("layers", id)
      if (dbLayer === null)
        throw new UnknownServerError("Couldn't get created layer.");

      return dbLayer;
    });

    const createdDbUnitPromises: Promise<DbUnit>[] = createdUnitIds.map(async (id) => {
      const dbUnit = await ctx.db.get("units", id)
      if (dbUnit === null)
        throw new UnknownServerError("Couldn't get created unit.");

      return dbUnit;
    });

    // wait for any remaining updates to finish
    await Promise.all(patchLayerPromises);
    await Promise.all(deleteLayerPromises);
    await Promise.all(deleteLayerImagePromises);
    await Promise.all(patchUnitPromises);
    await Promise.all(deleteUnitPromises);

    const createdDbLayers = await Promise.all(createdDbLayerPromises)
    const createdDbUnits = await Promise.all(createdDbUnitPromises)

    // return
    return {
      createdLayers: createdDbLayers.map(dbLayer => ({
        id:            dbLayer._id,
        name:          dbLayer.name,
        description:   dbLayer.description,
        corners:       dbLayer.corners,
        image:         dbLayer.image,
        createdAt:     dbLayer._creationTime,
        lastUpdated:   dbLayer.lastUpdated,
      })),
      createdUnits: createdDbUnits.map(dbUnit => ({
        id:            dbUnit._id,
        name:          dbUnit.name,
        description:   dbUnit.description,
        corners:       dbUnit.corners,
        pointInterval: dbUnit.pointInterval,
        createdAt:     dbUnit._creationTime,
        lastUpdated:   dbUnit.lastUpdated,
      })),
      timestamp,
    };
  }
});

export const finalizeProjectLayerImageUpload = zodInternalMutation({
  args: {
    projectId: zid("projects"),
    layerId: zid("layers"),
    storageId: zid("_storage"),
    filename: zDbLayer.shape.image.unwrap().shape.name,
    fileSize: zDbLayer.shape.image.unwrap().shape.size,
    timestamp: zTimestamp,
  },
  handler: async (ctx, args): Promise<NonNullable<ApiLayer["image"]>> => {
    const image: NonNullable<DbLayer["image"]> = {
      name:       args.filename,
      size:       args.fileSize,
      storageId:  args.storageId,
      uploadedAt: args.timestamp,
    };

    await ctx.db.patch(
      "layers",
      args.layerId,
      {
        image: {
          name:       args.filename,
          size:       args.fileSize,
          storageId:  args.storageId,
          uploadedAt: args.timestamp,
        },
        lastUpdated:    args.timestamp,
      },
    );

    await ctx.db.patch(
      "projects",
      args.projectId,
      { lastUpdated: args.timestamp },
    )

    return {
      name:       image.name,
      size:       image.size,
      uploadedAt: image.uploadedAt,
    };
  },
});

export const getProjectLayerImageDownloadUrl = zodQuery({
  args: {
    projectId: zid("projects"),
    layerId: zid("layers"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    if (project.layerIds.find(id => id === args.layerId) === undefined)
      throw new InvalidRequestError(`Project does not have layer with ID '${args.layerId}'.`);

    const layer = await ctx.db.get("layers", args.layerId);
    if (layer === null)
      throw new ResourceNotFoundError(`Layer with ID '${args.layerId}' not found.`);

    if (layer.image === null)
      throw new ResourceNotFoundError(`Layer with ID '${args.layerId}' doesn't have an image.`);

    const url = await ctx.storage.getUrl(layer.image.storageId);
    if (url === null)
      throw new UnknownServerError("File couldn't be found.");
    
    return url;
  },
});

export const deleteProjectLayerImage = zodMutation({
  args: {
    projectId: zid("projects"),
    layerId: zid("layers"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    if (project.layerIds.find(id => id === args.layerId) === undefined)
      throw new InvalidRequestError(
        `Project does not have layer with ID '${args.layerId}'.`
      );

    const layer = await ctx.db.get("layers", args.layerId);
    if (layer === null)
      throw new ResourceNotFoundError(
        `Layer with ID '${args.layerId}' not found.`
      );
    
    if (layer.image === null)
      throw new ResourceNotFoundError(
        `Layer with ID '${args.layerId}' doesn't have an image.`
      );

    const timestamp = Date.now();
    await ctx.storage.delete(layer.image.storageId);
    await ctx.db.patch(
      "layers",
      args.layerId,
      { image: null, lastUpdated: timestamp },
    );
    await ctx.db.patch("projects", args.projectId, { lastUpdated: timestamp });

    return timestamp;
  },
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

/**
 * Internal mutation used by HTTP endpoints to handle pXRF file upload 
 * database transactions. Returns the data spec's ID.
 */
export const finalizePxrfFileUpload = zodInternalMutation({
  args: {
    projectId: zid("projects"),
    storageId: zid("_storage"),
    fileName: zDbPxrfDataSpec.shape.fileName,
    description: zDbPxrfDataSpec.shape.description,
    numPoints: zDbPxrfDataSpec.shape.numPoints,
    size: zDbPxrfDataSpec.shape.numPoints,
    timestamp: zTimestamp,
  },
  handler: async (ctx, args) => {
    const specId = await ctx.db.insert("dataSpecs", {
      kind: "pxrf",
      lastUpdated: args.timestamp,
      ...args,
    });

    const { pxrfDataSpecIds } = (await ctx.db.get("projects", args.projectId))!;
    pxrfDataSpecIds.push(specId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { pxrfDataSpecIds, lastUpdated: args.timestamp }
    );

    const dbSpec = await ctx.db.get("dataSpecs", specId);

    if (dbSpec === null)
      throw new UnknownServerError("Couldn't get created pXRF data spec.");

    const apiSpec: ApiPxrfDataSpec = {
      id:          dbSpec._id,
      fileName:    dbSpec.fileName,
      description: dbSpec.description,
      numPoints:   dbSpec.numPoints,
      size:        dbSpec.size,
      createdAt:   dbSpec._creationTime,
      lastUpdated: dbSpec.lastUpdated,
    };

    return apiSpec;
  }
});

/**
 * Internal mutation used by HTTP endpoints to handle training file upload
 * database transactions. Returns the data spec's ID.
 */
export const finalizeTrainingFileUpload = zodInternalMutation({
  args: {
    projectId: zid("projects"),
    storageId: zid("_storage"),
    fileName: zDbTrainingDataSpec.shape.fileName,
    description: zDbTrainingDataSpec.shape.description,
    numPoints: zDbTrainingDataSpec.shape.numPoints,
    size: zDbTrainingDataSpec.shape.numPoints,
    timestamp: zTimestamp,
  },
  handler: async (ctx, args) => {
    const specId = await ctx.db.insert("dataSpecs", {
      kind: "training",
      lastUpdated: args.timestamp,
      ...args,
    });

    const { trainingDataSpecIds } = (
      await ctx.db.get("projects", args.projectId)
    )!;

    trainingDataSpecIds.push(specId);

    await ctx.db.patch(
      "projects",
      args.projectId,
      { trainingDataSpecIds, lastUpdated: args.timestamp }
    );

    return specId;
  }
});

/* ========================= Public file endpoints ========================= */
// See http.ts for the uploading endpoints

/** Query that returns a download URL for a pXRF data spec file. */
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

/**
 * Mutation that sets a pXRF data spec's name and/or description. Returns the
 * update timestamp.
 */
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

/**
 * Mutation that deletes a pXRF data spec and its associated file.
 * Returns the deletion timestamp.
 */
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

/**
 * Mutation that assigns a project's layer and unit to a pXRF data spec.
 * Returns the update timestamp.
 */
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

/** Query that returns a download URL for a training data spec file. */
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

/**
 * Mutation that sets a training data spec's name and/or description. Returns
 * the update timestamp.
 */
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

/**
 * Mutation that deletes a pXRF data spec and its associated file. Returns
 * the deletion timestamp.
 */
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

/**
 * Helper function that checks if a project has a prediction job. If it
 * doesn't, it throws a {@link ResourceNotFoundError}.
 * @param ctx The Convex-provided query/mutation context.
 * @param project The {@link DbProject} to reference.
 * @param jobId The prediction job's ID to search for.
 * @returns The {@link DbPredictionJob} associated with the inputted ID, and the
 *          index in the project's prediction job array where the ID was found.
 */
async function assertProjectHasPredictionJob(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  jobId: Id<"jobs">
): Promise<{
  job: DbPredictionJob,
  jobIndex: number,
}>
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

/**
 * Helper function that checks if a project has a training job. If it doesn't,
 * it throws a {@link ResourceNotFoundError}.
 * @param ctx The Convex-provided query/mutation context.
 * @param project The {@link DbProject} to reference.
 * @param jobId The training job's ID to search for.
 * @returns The {@link DbTrainingJob} associated with the inputted ID, and the
 *          index in the project's training job array where the ID was found.
 */
async function assertProjectHasTrainingJob(
  ctx: QueryCtx | MutationCtx,
  project: DbProject,
  jobId: Id<"jobs">
): Promise<{
  job: DbTrainingJob,
  jobIndex: number,
}>
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

/**
 * Helper mutation used by {@link runPredictionJob} that handles database
 * transactions for creating a prediction job. Returns a
 * {@link CreateDbPredictionJobResult}.
 */
export const createDbPredictionJob = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
    name: zDbPredictionJob.shape.name,
    description: zDbPredictionJob.shape.description,
    layerId: zDbPredictionJob.shape.layerId,
    modelId: zDbPredictionJob.shape.modelId,
  },
  handler: async (ctx, args): Promise<DbPredictionJob> => {
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

    const createdJob = await ctx.db.get("jobs", jobId);
    if (createdJob === null)
      throw new UnknownServerError("Couldn't fetch created prediction job.");

    return createdJob as DbPredictionJob;
  }
});

/**
 * Action that runs a prediction job, sending an HTTP request to the batch
 * service and creating its associated database entry. Returns the job's ID and
 * creation timestamp.
 */
export const runPredictionJob = zodAction({
  args: {
    projectId: zid("projects"),
    name: zDbPredictionJob.shape.name,
    description: zDbPredictionJob.shape.description,
    layerId: zDbPredictionJob.shape.layerId,
    modelId: zDbPredictionJob.shape.modelId,
  },
  handler: async (ctx, args): Promise<ApiPredictionJob> => {
    const userId = await authenticateUser(ctx);
    const createdJob = await ctx.runMutation(
      internal.projects.createDbPredictionJob,
      {
        userId,
        ...args
      }
    );

    const baseUrl = "https://earth-source-web-server.onrender.com/run";
    const params = new URLSearchParams({
      jobId:      createdJob._id,
      projectId:  args.projectId,
      outputName: "classification",
    });

    fetch(`${baseUrl}?${params}`);

    return {
      id:              createdJob._id,
      name:            createdJob.name,
      description:     createdJob.description,
      layerId:         createdJob.layerId,
      modelId:         createdJob.modelId,
      dataAssignments: createdJob.dataAssignments,
      status:          createdJob.status,
      createdAt:       createdJob._creationTime,
      lastUpdated:     createdJob.lastUpdated,
    };
  },
});

/**
 * Mutation that sets a prediction job's name and description. Returns the
 * update timestamp.
 */
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

/** Query that fetches a project's {@link PredictionJob}. */
export const getPredictionJobStatus = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasPredictionJob(
      ctx,
      project,
      args.jobId
    );

    return job.status;
  }
});

/** Mutation that deletes a prediction job and its associated files. */
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

    if (job.status !== "complete" && job.status !== "failed")
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

export const getPredictionJobResultsDownloadUrl = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasPredictionJob(
      ctx,
      project,
      args.jobId
    );

    if (job.status !== 'complete')
      throw new InvalidRequestError("Job isn't complete.");

    if (job.outputStorageId === null)
      throw new UnknownServerError("Job is complete but doesn't have an output storage ID.");

    const url = await ctx.storage.getUrl(job.outputStorageId);

    if (url === null)
      throw new UnknownServerError("Job file couldn't be found.");
    
    return url;
  },
})

/**
 * Helper mutation used by {@link runTrainingJob} that handles database
 * transactions for creating a training job. Returns a
 * {@link CreateDbTrainingJobResult}.
 */
export const createDbTrainingJob = zodInternalMutation({
  args: {
    userId: zid("users"),
    projectId: zid("projects"),
    name: zDbTrainingJob.shape.name,
    description: zDbTrainingJob.shape.description,
    trainingDataSpecId: zid("dataSpecs"),
  },
  handler: async (ctx, args): Promise<DbTrainingJob> => {
    const { trainingJobIds } = await getDbProject(
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

    const createdJob = await ctx.db.get("jobs", jobId);
    if (createdJob === null)
      throw new UnknownServerError("Couldn't fetch created training job.");

    return createdJob as DbTrainingJob;
  }
});

/**
 * Action that runs a training job, sending an HTTP request to the batch
 * service and creating its associated database entry. Returns the job's ID and
 * creation timestamp.
 */
export const runTrainingJob = zodAction({
  args: {
    projectId: zid("projects"),
    name: zDbTrainingJob.shape.name,
    description: zDbTrainingJob.shape.description,
    trainingDataSpecId: zid("dataSpecs"),
  },
  handler: async (ctx, args): Promise<ApiTrainingJob> => {
    const userId = await authenticateUser(ctx);
    const createdJob = await ctx.runMutation(
      internal.projects.createDbTrainingJob,
      {
        userId,
        ...args
      }
    );

    // TODO: send HTTP request with job ID

    return {
      id:                 createdJob._id,
      name:               createdJob.name,
      description:        createdJob.description,
      trainingDataSpecId: createdJob.trainingDataSpecId,
      status:             createdJob.status,
      createdAt:          createdJob._creationTime,
      lastUpdated:        createdJob.lastUpdated,
    };
  },
});

/**
 * Mutation that sets a training job's name and description. Returns the
 * update timestamp.
 */
export const setTrainingJobMetadata = zodMutation({
  args: {
    projectId:   zid("projects"),
    jobId:       zid("jobs"),
    name:        zDbTrainingJob.shape.name.optional(),
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

/** Query that fetches a project's {@link TrainingJob}. */
export const getTrainingJobStatus = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasTrainingJob(
      ctx,
      project,
      args.jobId,
    );

    return job.status;
  }
});

/** Mutation that deletes a training job and its associated files. */
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

    if (job.status !== "complete" && job.status !== "failed")
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
        lastUpdated: timestamp,
      }
    );

    return timestamp;
  },
});

export const getTrainingJobResultsDownloadUrl = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);
    const project = await getDbProject(ctx, args.projectId, userId);
    const { job } = await assertProjectHasTrainingJob(
      ctx,
      project,
      args.jobId
    );

    if (job.status !== 'complete')
      throw new InvalidRequestError("Job isn't complete.");

    if (job.outputStorageId === null)
      throw new UnknownServerError("Job is complete but doesn't have an output storage ID.");

    const url = await ctx.storage.getUrl(job.outputStorageId);

    if (url === null)
      throw new UnknownServerError("Job file couldn't be found.");
    
    return url;
  },
});