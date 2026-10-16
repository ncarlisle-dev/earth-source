import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server";
import { internal } from "./_generated/api";

import { zid } from "convex-helpers/server/zod4";
import * as z from "zod";
import { zPxrfDataSpec, zTrainingDataSpec } from "./schema";
import { ApiError } from "./errors";
import { authenticateUser } from "./auth";

/** The HTTP router object used to initialize all HTTP endpoints. */
const http = httpRouter();

/** Zod object defining the shape of arguments for uploading pXRF data. */
const zUploadPxrfDataArgs = z.object({
  projectId: zid("projects"),
  description: zPxrfDataSpec.shape.description,
  file: z
    .file()
    .refine(
      (file) => file.size > 0,
      { message: "File must be non-empty." }
    )
    .refine(
      (file) => {
        // TODO: add CSV format validation here
        return true;
      },
      { message: "File must be a valid pXRF data file." }
    ),
});

/**
 * POST endpoint that adds pXRF data to a project. Returns the resulting data
 * spec's ID and the update timestamp.
 */
http.route({
  path: "/uploadPxrfData",
  method: "POST",
  handler: httpAction(async (ctx, request) => {
    // get args
    const formData = Object.fromEntries(await request.formData());
    const { success, error, data: args } = zUploadPxrfDataArgs.safeParse(formData);
    if (!success)
      return new Response(
        `Invalid argument(s) given:\n${error}`,
        { status: 400, }
      );
    
    // authenticate user and verify the project may be referenced
    try {
      const userId = await authenticateUser(ctx);
      await ctx.runQuery(
        internal.projects.getDbProjectQuery,
        { userId, projectId: args.projectId, }
      );
    } catch (e) {
      return e instanceof ApiError
        ? new Response(e.data.message, { status: e.data.code, })
        : new Response(`Unknown error occurred:\n${e}`, { status: 500, });
    }
    
    // put into storage
    const storageId = await ctx.storage.store(args.file);
    const timestamp = Date.now();

    // write to database and return
    try {
      const specId = await ctx.runMutation(
        internal.projects.finalizePxrfFileUpload,
        {
          projectId: args.projectId,
          storageId,
          fileName: args.file.name,
          description: args.description,
          size: args.file.size,
          numPoints: 0, // TODO: get the number of points
          timestamp,
        }
      );

      return Response.json({ specId, timestamp }, { status: 201 });
    } catch (e) {
      await ctx.storage.delete(storageId);

      return e instanceof ApiError
        ? new Response(e.data.message, { status: e.data.code })
        : new Response(`Unknown error occurred:\n${e}`, { status: 500 });
    }
  }),
});

/** Zod object defining the shape of arguments for uploading training data. */
const zUploadTrainingDataArgs = z.object({
  projectId: zid("projects"),
  description: zTrainingDataSpec.shape.description,
  file: z
    .file()
    .refine(
      (file) => file.size > 0,
      { message: "File must be non-empty." }
    )
    .refine(
      (file) => {
        // TODO: add CSV format validation here
        return true;
      },
      { message: "File must be a valid training data file." }
    ),
});

/**
 * POST endpoint that adds training data to a project. Returns the resulting
 * data spec's ID and the update timestamp.
 */
http.route({
  path: "/uploadTrainingData",
  method: "POST",
  handler: httpAction(async (ctx, request) => {
    // get args
    const formData = Object.fromEntries(await request.formData());
    const { success, error, data: args } = zUploadTrainingDataArgs.safeParse(formData);
    if (!success)
      return new Response(
        `Invalid argument(s) given:\n${error}`,
        { status: 400, }
      );
    
    // authenticate user and verify the project may be referenced
    try {
      const userId = await authenticateUser(ctx);
      await ctx.runQuery(
        internal.projects.getDbProjectQuery,
        { userId, projectId: args.projectId, }
      );
    } catch (e) {
      return e instanceof ApiError
        ? new Response(e.data.message, { status: e.data.code, })
        : new Response(`Unknown error occurred:\n${e}`, { status: 500, });
    }
    
    // put into storage
    const storageId = await ctx.storage.store(args.file);
    const timestamp = Date.now();

    // write to database and return
    try {
      const specId = await ctx.runMutation(
        internal.projects.finalizeTrainingFileUpload,
        {
          projectId: args.projectId,
          storageId,
          fileName: args.file.name,
          description: args.description,
          size: args.file.size,
          numPoints: 0, // TODO: get the number of points
          timestamp,
        }
      );

      return Response.json({ specId, timestamp }, { status: 201 });
    } catch (e) {
      await ctx.storage.delete(storageId);

      return e instanceof ApiError
        ? new Response(e.data.message, { status: e.data.code })
        : new Response(`Unknown error occurred:\n${e}`, { status: 500 });
    }
  }),
});

// Export the HTTP router for Convex to deploy.
export default http;