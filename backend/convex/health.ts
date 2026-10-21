import { zodQuery } from "./builders";

export const ping = zodQuery({
  args: {},
  handler: async () => "Convex client is connected!",
});