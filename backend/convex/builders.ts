import {
  action,
  internalAction,
  internalMutation,
  internalQuery,
  mutation,
  query,
} from "./_generated/server";

import {
    zCustomAction,
    zCustomMutation,
    zCustomQuery
} from "convex-helpers/server/zod4";

import { NoOp } from "convex-helpers/server/customFunctions";

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