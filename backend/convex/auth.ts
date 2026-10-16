import { UnauthorizedError } from "./errors";
import { zodInternalQuery } from "./builders";
import { internal } from "./_generated/api";
import { QueryCtx, ActionCtx, MutationCtx } from "./_generated/server";
import { DbUser, zDbUser } from "./schema";

export const getUserByToken = zodInternalQuery({
  args: { token: zDbUser.shape.token, },
  handler: async (ctx, args) => {
    return await ctx.db
        .query("users")
        .withIndex("by_token", q => q.eq("token", args.token))
        .first();
  }
});

/**
 * Helper function that authenticates the user, throwing an
 * {@link UnauthorizedError} if no credentials are provided.
 * @param ctx The Convex-provided endpoint context.
 * @returns The user's ID according to the database.
 */
export async function authenticateUser(ctx: QueryCtx | MutationCtx | ActionCtx)
{
    const identity = await ctx.auth.getUserIdentity();

    if (identity === null) 
        throw new UnauthorizedError("User is not authenticated.");

    const user = await ctx.runQuery(
        internal.auth.getUserByToken,
        { token: identity.tokenIdentifier }
    ) as DbUser | null;

    if (user === null) 
        throw new UnauthorizedError("User is not registered.");

    return user._id;
}