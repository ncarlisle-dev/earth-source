import { ConvexError } from "convex/values";

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