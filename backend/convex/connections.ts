import { authenticateUser, zodQuery, zodMutation, UnauthorizedError, ResourceNotFoundError } from "./helper";
import { zDbConnectionSpec } from "./schema";
import { zid } from "convex-helpers/server/zod4";

export const createConnectionSpec = zodMutation({
  args: {
    ipAddress: zDbConnectionSpec.shape.ipAddress,
    port: zDbConnectionSpec.shape.port,
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);

    const id = await ctx.db.insert("connectionSpecs", {
      userId,
      ipAddress: args.ipAddress,
      port: args.port,
    });

    return id;
  },
});

export const deleteConnectionSpec = zodMutation({
  args: {
    id: zid("connectionSpecs"),
  },
  handler: async (ctx, args) => {
    const userId = await authenticateUser(ctx);

    const existingSpec = await ctx.db.get("connectionSpecs", args.id);
    if (!existingSpec)
      throw new ResourceNotFoundError(`Connection spec with ID '${args.id}' not found.`);

    if (existingSpec.userId !== userId)
      throw new UnauthorizedError(`User is not authorized to delete connection spec with ID '${args.id}'.`);

    await ctx.db.delete("connectionSpecs", args.id);
  }
});

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
