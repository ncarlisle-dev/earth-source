import { zodMutation, zodQuery } from "./builders";
import { ApiPredictionJob, ApiTrainingJob, Corners, DbPxrfDataSpec, DbUnit, JobStatus, PointInterval } from "./schema";
import { InvalidRequestError, ResourceNotFoundError, UnauthorizedError, UnknownServerError } from "./errors";

import { zid } from "convex-helpers/server/zod4";
import { api } from "./_generated/api";
import { Id } from "./_generated/dataModel";
import { MutationCtx } from "./_generated/server";

// TODO: Add authentication to only allow the batch server to run these endpoints

/* ============================ Prediction jobs ============================ */

/** Object returned by the {@link getPredictionJobParameters} endpoint. */
interface PredictionJobParams {
  modelDownloadUrl: string | null,
  siteCorners:      Corners,
  unitMetadata:     {
    corners:          Corners,
    pointInterval:    PointInterval,
    dataDownloadUrl:  string,
  }[],
};

/** Endpoint for fetching a prediction job's parameters. */
export const getPredictionJobParameters = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args): Promise<PredictionJobParams> => {
    // get job
    const job = await ctx.db.get("jobs", args.jobId);

    if (job === null || job.kind !== "prediction")
      throw new ResourceNotFoundError(
        `Prediction job with ID '${args.jobId}' not found.`
      );

    // get project
    const project = await ctx.db.get("projects", args.projectId);

    if (project === null)
      throw new ResourceNotFoundError(
        `Project with ID '${args.projectId}' not found.`
      );
    
    // get unit info
    const units: Record<Id<"units">, DbUnit & { dataDownloadUrl: string }> = {};
    const dataSpecs: Record<Id<"dataSpecs">, DbPxrfDataSpec> = {};
    const downloadUrls: Record<Id<"_storage">, string> = {};

    for (const [unitId, specId] of Object.entries(job.dataAssignments)) {
      // check IDs
      if (specId === null) continue;
      const safeSpecId = specId as Id<"dataSpecs">;
      const safeUnitId = unitId as Id<"units">;

      // get data spec
      if (!dataSpecs[safeSpecId]) {
        const spec = await ctx.db.get("dataSpecs", safeSpecId);
        if (spec === null || spec.kind !== "pxrf")
          throw new UnknownServerError(
            `pXRF spec with ID '${specId}' not found.`
          );
        
        dataSpecs[safeSpecId] = spec;
      }

      // get download URL
      const storageId = dataSpecs[safeSpecId].storageId;
      if (!downloadUrls[storageId]) {
        const downloadUrl = await ctx.storage.getUrl(storageId);
        if (downloadUrl === null)
          throw new UnknownServerError(
            `pXRF data with ID '${specId}' not found.`
          );
        
        downloadUrls[storageId] = downloadUrl;
      }

      // get unit
      const unit = await ctx.db.get("units", safeUnitId);
      if (unit === null)
        throw new UnknownServerError(
          `Unit with ID '${unitId}' not found.`
        );

      units[safeUnitId] = {
        ...unit,
        dataDownloadUrl: downloadUrls[storageId],
      };
    }

    // get model download URL
    let modelDownloadUrl: string | null = null;
    if (job.modelId !== null) {
      const trainingJob = await ctx.db.get("jobs", job.modelId);
      if (
        trainingJob === null 
        || trainingJob.kind !== "training" 
        || trainingJob.status !== "complete"
        || trainingJob.outputStorageId === null
      )
        throw new UnknownServerError(
          `Complete training job with ID ${job.modelId} not found.`
        );

      modelDownloadUrl = await ctx.storage.getUrl(trainingJob.outputStorageId);
      if (modelDownloadUrl === null)
        throw new UnknownServerError(
          `Training job output not found (job ID = '${job.modelId}').`
        );
    }

    // return
    return {
      modelDownloadUrl:  modelDownloadUrl,
      siteCorners:       project.corners,
      unitMetadata:      Object.values(units).map(unit => ({
        corners:         unit.corners,
        pointInterval:   unit.pointInterval,
        dataDownloadUrl: unit.dataDownloadUrl,
      })),
    };
  }
})

async function updatePredictionJob(
  ctx: MutationCtx,
  projectId: Id<"projects">,
  jobId: Id<"jobs">,
  requiredStatus: JobStatus,
  status: JobStatus,
  storageId?: Id<"_storage">,
)
{
  const currStatus = await ctx.runQuery(
    api.projects.getPredictionJobStatus,
    { projectId, jobId },
  );

  if (currStatus !== requiredStatus)
    throw new InvalidRequestError(
      `Job may not be set to '${status}'; it needs to be '${requiredStatus}' first.`
    );

  const timestamp = Date.now();

  await ctx.db.patch(
    "jobs",
    jobId,
    { status, outputStorageId: storageId, lastUpdated: timestamp },
  );

  await ctx.db.patch("projects", projectId, { lastUpdated: timestamp });
}

export const claimPredictionJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    await updatePredictionJob(
      ctx,
      args.projectId,
      args.jobId,
      "starting",
      "running"
    );
  }
});


export const failPredictionJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    await updatePredictionJob(
      ctx,
      args.projectId,
      args.jobId,
      "running",
      "failed"
    );
  }
});

export const completePredictionJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
    storageId: zid("_storage"),
  },
  handler: async (ctx, args) => {
    // TODO: Add authentication to only allow the batch server to do this
    await updatePredictionJob(
      ctx,
      args.projectId,
      args.jobId,
      "running",
      "complete",
      args.storageId,
    );
  }
});

export const getPredictionJobResultsUploadUrl = zodMutation({
  args: {
    // Job ID is technically unnecessary, but we keep it in case
    // future services require it.
    jobId: zid("jobs"), 
  },
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  }
});

/* ============================ Training jobs ============================ */

export const getTrainingJobParams = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    const job = await ctx.db.get("jobs", args.jobId);

    if (job === null || job.kind !== "training")
      throw new ResourceNotFoundError(
        `Training job with ID '${args.jobId}' not found.`
      );
    
    const dataSpec = await ctx.db.get("dataSpecs", job.trainingDataSpecId);
    if (dataSpec === null)
      throw new UnknownServerError(
        `Training data spec with ID '${job.trainingDataSpecId}' not found.`
      );
    
    const downloadUrl = await ctx.storage.getUrl(dataSpec.storageId);
    if (downloadUrl === null)
      throw new UnknownServerError(`Training data with ID '${dataSpec.storageId}' not found.`);

    return {
      dataDownloadUrl: downloadUrl,
    };
  }
});

async function updateTrainingJob(
  ctx: MutationCtx,
  projectId: Id<"projects">,
  jobId: Id<"jobs">,
  requiredStatus: JobStatus,
  status: JobStatus,
  storageId?: Id<"_storage">,
)
{
  const currStatus = await ctx.runQuery(
    api.projects.getTrainingJobStatus,
    { projectId, jobId },
  );

  if (currStatus !== requiredStatus)
    throw new InvalidRequestError(
      `Job may not be set to '${status}'; it needs to be '${requiredStatus}' first.`
    );

  const timestamp = Date.now();

  await ctx.db.patch(
    "jobs",
    jobId,
    { status, outputStorageId: storageId, lastUpdated: timestamp },
  );

  await ctx.db.patch("projects", projectId, { lastUpdated: timestamp });
}

export const claimTrainingJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    await updateTrainingJob(
      ctx,
      args.projectId,
      args.jobId,
      "starting",
      "running"
    );
  }
});


export const failTrainingJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args) => {
    await updateTrainingJob(
      ctx,
      args.projectId,
      args.jobId,
      "running",
      "failed"
    );
  }
});

export const completeTrainingJob = zodMutation({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
    storageId: zid("_storage"),
  },
  handler: async (ctx, args) => {
    // TODO: Add authentication to only allow the batch server to do this
    await updateTrainingJob(
      ctx,
      args.projectId,
      args.jobId,
      "running",
      "complete",
      args.storageId,
    );
  }
});

export const getTrainingJobResultsUploadUrl = zodMutation({
  args: {
    // Job ID is technically unnecessary, but we keep it in case
    // future services require it.
    jobId: zid("jobs"), 
  },
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  }
});