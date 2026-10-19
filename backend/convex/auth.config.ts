import { AuthConfig } from "convex/server";

export default {
  providers: [
    {
      domain: "https://5uk3n8.logto.app/oidc", // iss in JWT
      applicationID: "https://5uk3n8.logto.app/api", // aud in JWT
    },
  ],
} satisfies AuthConfig;