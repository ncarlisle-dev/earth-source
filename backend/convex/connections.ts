import { UnauthorizedError, ResourceNotFoundError, UnknownServerError } from "./errors";
import { zodQuery, zodMutation, } from "./builders";
import { authenticateUser } from "./auth";
import { ApiConnectionSpec, zDbConnectionSpec } from "./schema";
import { zid } from "convex-helpers/server/zod4";

/**
 * Given an IP address and port, creates a connection spec in the database.
 * Returns the generated spec.
 */
export const createConnectionSpec = zodMutation({
  args: {
    ipAddress: zDbConnectionSpec.shape.ipAddress,
    port: zDbConnectionSpec.shape.port,
  },
  handler: async (ctx, args): Promise<ApiConnectionSpec> => {
    const userId = await authenticateUser(ctx);

    const id = await ctx.db.insert("connectionSpecs", {
      userId,
      ipAddress: args.ipAddress,
      port: args.port,
    });

    const dbSpec = await ctx.db.get("connectionSpecs", id);
    if (dbSpec === null)
      throw new UnknownServerError("Couldn't fetch created connection spec.");
    
    return {
      id:        dbSpec._id,
      ipAddress: dbSpec.ipAddress,
      port:      dbSpec.port,
      createdAt: dbSpec._creationTime,
    };
  },
});

/** Given a connection spec ID, removes the spec from the database. */
export const deleteConnectionSpec = zodMutation({
  args: {
    id: zid("connectionSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);

    const existingSpec = await ctx.db.get("connectionSpecs", args.id);
    if (!existingSpec)
      throw new ResourceNotFoundError(
        `Connection spec with ID '${args.id}' not found.`
      );

    if (existingSpec.userId !== userId)
      throw new UnauthorizedError(
        `User is not authorized to delete connection spec with ID '${args.id}'.`
      );

    await ctx.db.delete("connectionSpecs", args.id);
  }
});

/** Query that returns the user's connection specs. */
export const getUserConnectionSpecs = zodQuery({
  handler: async (ctx) => {
    const userId = await authenticateUser(ctx);

    const specs = await ctx.db
      .query("connectionSpecs")
      .withIndex(
        "by_userId", 
        (q) => q.eq("userId", userId)
      )
      .collect();
    
    return specs;
  }
});
