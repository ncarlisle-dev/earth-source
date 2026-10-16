import { UserIdentity } from "convex/server";
import { ConvexError } from "convex/values";
import { Id } from "./_generated/dataModel";
import { action, ActionCtx, httpAction, internalAction, internalMutation, internalQuery, mutation, MutationCtx, query, QueryCtx } from "./_generated/server";
import { zCustomAction, zCustomMutation, zCustomQuery } from "convex-helpers/server/zod4";
import { NoOp } from "convex-helpers/server/customFunctions";

/* =========================== API errors =========================== */

/**
 * A wrapper around a {@link ConvexError} that includes a message
 * and status code.
*/
export class ApiError extends ConvexError<{message: string, code: number}>
{
    constructor(message: string, code: number) {
        super({ message, code });
    }
};

/** Instance of {@link ApiError} that returns a 400 status code. */
export class InvalidRequestError extends ApiError {
    constructor(message: string) {
        super(message, 400)
    }
}

/** Instance of {@link ApiError} that returns a 401 status code. */
export class UnauthorizedError extends ApiError {
    constructor(message: string) {
        super(message, 401)
    }
}

/** Instance of {@link ApiError} that returns a 404 status code. */
export class ResourceNotFoundError extends ApiError {
    constructor(message: string) {
        super(message, 404)
    }
}

/** Instance of {@link ApiError} that returns a 409 status code. */
export class ResourceConflictError extends ApiError {
    constructor(message: string) {
        super(message, 409)
    }
}

/** Instance of {@link ApiError} that returns a 500 status code. */
export class UnknownServerError extends ApiError {
    constructor(message: string) {
        super(message, 500)
    }
}

/* =========================== Zod bridging =========================== */

/** 
 * A {@link zCustomQuery} that wraps Convex's {@link query} in Zod 
 * validation.
 */
export const zodQuery = zCustomQuery(query, NoOp);

/** 
 * A {@link zCustomQuery} that wraps Convex's {@link internalQuery}
 * in Zod validation.
 */
export const zodInternalQuery = zCustomQuery(internalQuery, NoOp);

/**
 * A {@link zCustomMutation} that wraps Convex's {@link mutation} in Zod
 * validation.
 */
export const zodMutation = zCustomMutation(mutation, NoOp);

/** 
 * A {@link zCustomMutation} that wraps Convex's {@link internalMutation} in Zod
 * validation.
 */
export const zodInternalMutation = zCustomMutation(internalMutation, NoOp);

/**
 * A {@link zCustomAction} that wraps Convex's {@link action} in Zod
 * validation.
 */
export const zodAction = zCustomAction(action, NoOp);

/**
 * A {@link zCustomAction} that wraps Convex's {@link internalAction} in Zod
 * validation.
 */
export const zodInternalAction = zCustomAction(internalAction, NoOp);

/* =========================== Helper functions =========================== */

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
    return identity.tokenIdentifier as Id<"users">;
}