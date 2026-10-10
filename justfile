[group('backend config')]
[working-directory: './backend']
backend-setup:
    npm ci
    npx convex login

[group('backend config')]
[working-directory: './backend']
backend-switch id:
    npx convex deployment select {{id}}

[group('backend config')]
[working-directory: './backend']
backend-write:
    npx convex codegen

# Lists all existing deployments. Too complicated to implement without outsourcing the work to a custom script.
# backend-list:
#     curl "https://api.convex.dev/v1/projects/YOUR_PROJECT_ID/list_deployments" -d "includeLocal=true" -H "Authorization: Bearer YOUR_TOKEN"

setup: backend-setup
    flutter pub get

[group('execution')]
[working-directory: './backend']
dev:
    npx convex dev --start "cd .. && flutter run"

[group('execution')]
frontend-dev:
    flutter run

[group('execution')]
[working-directory: './backend']
backend-dev-once:
    npx convex dev --once

[group('execution')]
[working-directory: './backend']
backend-dev-watch:
    npx convex dev

