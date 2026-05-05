# Sub2API Base Project

## Role
This repository is the local execution base for reproducing the engine behind `aiprimetech.io` on localhost.

## Origin
- Upstream source: `Wei-Shaw/sub2api`
- Local branch: `sub2api-base-local`
- Local path: `D:\cursor\sub2api-base`

## Goal
1. Run the stock engine locally.
2. Understand deployment, bootstrap, migrations, accounts, groups, channels, and plans.
3. Prepare a clean baseline for later provider configuration, starting with Antigravity.
4. Keep local decisions documented so the project can be pushed to a remote later without losing intent.

## Current Scope
- Docker and localhost deployment
- `.env` and generated bootstrap state
- Admin initialization flow
- Mapping accounts, groups, channels, plans, and purchase links
- Minimal local customization after a working baseline exists

## Out Of Scope For Now
- Rebuilding the external storefront
- Large UI redesigns
- Broad provider experiments that belong in the research repository

## Immediate Work Queue
- Bring up the upstream stack with Docker Compose local mode.
- Record the exact localhost startup path.
- Prepare a first local `.env` profile.
- Define the first operator checklist for future provider onboarding.

## Internal References
- Deployment docs: `D:\cursor\sub2api-base\deploy\README.md`
- Local compose file: `D:\cursor\sub2api-base\deploy\docker-compose.local.yml`
- Environment template: `D:\cursor\sub2api-base\deploy\.env.example`
- Local notes: `D:\cursor\sub2api-base\docs\local\SETUP_NOTES.md`
