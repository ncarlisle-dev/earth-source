import { UserIdentity } from "convex/server";
import { ConvexError } from "convex/values";
import { Id } from "./_generated/dataModel";
import { action, ActionCtx, httpAction, internalAction, internalMutation, internalQuery, mutation, MutationCtx, query, QueryCtx } from "./_generated/server";
import { zCustomAction, zCustomMutation, zCustomQuery } from "convex-helpers/server/zod4";
import { NoOp } from "convex-helpers/server/customFunctions";

/* =========================== API errors =========================== */

export class ApiError extends ConvexError<{message: string, code: number}>
{
    constructor(message: string, code: number) {
        super({ message, code });
    }
};

export class InvalidRequestError extends ApiError {
    constructor(message: string) {
        super(message, 400)
    }
}

export class UnauthorizedError extends ApiError {
    constructor(message: string) {
        super(message, 401)
    }
}

export class ResourceNotFoundError extends ApiError {
    constructor(message: string) {
        super(message, 404)
    }
}

export class ResourceConflictError extends ApiError {
    constructor(message: string) {
        super(message, 409)
    }
}

export class UnknownServerError extends ApiError {
    constructor(message: string) {
        super(message, 500)
    }
}

/* =========================== Zod bridging =========================== */

export const zodQuery = zCustomQuery(query, NoOp);
export const zodInternalQuery = zCustomQuery(internalQuery, NoOp);
export const zodMutation = zCustomMutation(mutation, NoOp);
export const zodInternalMutation = zCustomMutation(internalMutation, NoOp);
export const zodAction = zCustomAction(action, NoOp);
export const zodInternalAction = zCustomAction(internalAction, NoOp);

/* =========================== Helper functions =========================== */

export async function authenticateUser(ctx: QueryCtx | MutationCtx | ActionCtx) {
    const identity = await ctx.auth.getUserIdentity();
    if (identity === null) throw new UnauthorizedError("User is not authenticated.");
    return identity.tokenIdentifier as Id<"users">;
}