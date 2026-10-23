import {query} from "./_generated/server";
//If success is true Python has reached Convex display message for test
export const ping = query({
  args: {},
  handler: async () => {
    return {
      success: true,
      message: "Python connected to Convex Successfully!"
    };
  }
});
