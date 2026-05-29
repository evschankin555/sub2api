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
- Production baseline moved to the dedicated `gptclaudegemini.xyz` server with Russian as the default frontend locale
- Safe Antigravity test skeleton without real accounts, secrets, or enabled traffic
- Dedicated deployment split: static root placeholder, full dashboard on `d.gptclaudegemini.xyz`, and API-only access on `api.gptclaudegemini.xyz`
- Statistics mini frontend exposed on `statistics.gptclaudegemini.xyz` as a static site with same-origin backend proxying to the existing GPT Parser statistics backend

## Out Of Scope For Now
- Rebuilding the external storefront
- Large UI redesigns
- Broad provider experiments that belong in the research repository

## Immediate Work Queue
- Verify the Russian default locale across admin/operator flows after each frontend change.
- Keep the production image tag and compose backup path recorded in setup notes.
- Use `docs/local/MIGRATION_RUNBOOK.md` and `/root/sub2api-migration-20260513` as the record for the completed dedicated-server move to `185.228.72.116`.
- Keep the full dashboard/admin UI on `d.gptclaudegemini.xyz`, keep `api.gptclaudegemini.xyz` API-only, and serve the static placeholder on `gptclaudegemini.xyz`.
- Keep `statistics.gptclaudegemini.xyz` static-only except for `/api/public/*`, which is proxied to the existing GPT Parser statistics backend; frontend builds must not include old `gpt.developing-site.ru` or Render bridge API mirrors.
- Add the first real Antigravity account only after purchase, then configure mapping/pricing and enable the sandbox channel.
- Continue preserving the upstream-compatible backend API schema unless a provider adoption decision requires otherwise.

## Internal References
- Deployment docs: `D:\cursor\sub2api-base\deploy\README.md`
- Local compose file: `D:\cursor\sub2api-base\deploy\docker-compose.local.yml`
- Environment template: `D:\cursor\sub2api-base\deploy\.env.example`
- Local notes: `D:\cursor\sub2api-base\docs\local\SETUP_NOTES.md`
- Migration runbook: `D:\cursor\sub2api-base\docs\local\MIGRATION_RUNBOOK.md`
