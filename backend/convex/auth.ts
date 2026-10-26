import { UnauthorizedError, ResourceConflictError } from "./errors";
import { zodInternalQuery, zodMutation } from "./builders";
import { internal } from "./_generated/api";
import { QueryCtx, ActionCtx, MutationCtx } from "./_generated/server";
import { DbUser, zDbUser } from "./schema";
import { Id } from "./_generated/dataModel";

export const getUserByToken = zodInternalQuery({
  args: { token: zDbUser.shape.token, },
  handler: async (ctx, args) => {
    return await ctx.db
        .query("users")
        .withIndex("by_token", q => q.eq("token", args.token))
        .unique();
  }
});

export const storeUser = zodMutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (identity === null) throw new UnauthorizedError("User is not authenticated.");

    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_token", q => q.eq("token", identity.tokenIdentifier))
      .unique();

    if (existingUser !== null)
      throw new ResourceConflictError("User with token already exists");

    return await ctx.db.insert("users", {
      name: identity.name ?? "",
      token: identity.tokenIdentifier,
    });
  }
});

/**
 * Helper function that authenticates the user, throwing an
 * {@link UnauthorizedError} if no credentials are provided.
 * {@link UnauthorizedError} if no credentials are provided or the user isn't
 * registered.
 * @param ctx The Convex-provided endpoint context.
 * @returns The user's ID according to the database.
 */
export async function authenticateUser(ctx: QueryCtx | MutationCtx | ActionCtx): Promise<Id<"users">>
{
  // TODO: implement actual authentication

  // const identity = await ctx.auth.getUserIdentity();

  // if (identity === null) 
  //   throw new UnauthorizedError("User is not authenticated.");
  // const user = await ctx.runQuery(
  //   internal.auth.getUserByToken,
  //   { token: identity.tokenIdentifier }
  // ) as DbUser | null;

  // if (user === null) 
  //   throw new UnauthorizedError("User is not registered.");

  // return user._id;

  return "jx79gcase9kn4qqz2tses3w62x8gzkxz" as Id<"users">; // replace with your own user ID
} 