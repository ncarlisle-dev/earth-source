import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const uploadConnectionEntry = mutation({
  args: {
    ipAddress: v.string(),
    port: v.number(),
  },
  handler: async (ctx, args) => {
    console.log("This TypeScript function is running on the server.");

    const authInfo = await ctx.auth.getUserIdentity();
    if (authInfo === null) {
      return;
    }

    const existingConnSpec = await ctx.db.get("connectionSpecs", );

    await ctx.db.insert("connectionSpecs", {
      userId: authInfo.tokenIdentifier,
      ipAddress: args.ipAddress,
      port: args.port,
    });
  },
});