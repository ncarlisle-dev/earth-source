import { zodMutation, zodQuery } from "./builders";
import { ApiPredictionJob, ApiTrainingJob, JobStatus } from "./schema";
import { InvalidRequestError, ResourceNotFoundError } from "./errors";

import { zid } from "convex-helpers/server/zod4";
import { api } from "./_generated/api";
import { Id } from "./_generated/dataModel";
import { MutationCtx } from "./_generated/server";

// TODO: Add authentication to only allow the batch server to run these endpoints

/* ============================ Prediction jobs ============================ */

export const getPredictionJobById = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args): Promise<ApiPredictionJob> => {
    const job = await ctx.db.get("jobs", args.jobId);

    if (job === null || job.kind !== "prediction")
      throw new ResourceNotFoundError(
        `Prediction job with ID '${args.jobId}' not found.`
      );

    return {
      id:                 job._id,
      name:               job.name,
      description:        job.description,
      layerId:            job.layerId,
      modelId:            job.modelId,
      dataAssignments:    job.dataAssignments,
      status:             job.status,
      createdAt:          job._creationTime,
      lastUpdated:        job.lastUpdated,
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

export const getTrainingJobById = zodQuery({
  args: {
    projectId: zid("projects"),
    jobId: zid("jobs"),
  },
  handler: async (ctx, args): Promise<ApiTrainingJob> => {
    const job = await ctx.db.get("jobs", args.jobId);

    if (job === null || job.kind !== "training")
      throw new ResourceNotFoundError(
        `Training job with ID '${args.jobId}' not found.`
      );

    return {
      id:                 job._id,
      name:               job.name,
      description:        job.description,
      trainingDataSpecId: job.trainingDataSpecId,
      status:             job.status,
      createdAt:          job._creationTime,
      lastUpdated:        job.lastUpdated,
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