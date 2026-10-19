import { zodQuery } from "./builders";

export const ping = zodQuery({
  args: {},
  handler: async () => "ok",
});