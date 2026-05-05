# Setup Notes

## Status
- Base worktree created from the upstream repository.
- This repository is for execution and controlled adaptation, not for broad provider research.

## Planned Bring-Up Path
1. Use `deploy\docker-compose.local.yml`.
2. Generate `.env` from `deploy\.env.example`.
3. Start PostgreSQL, Redis, and app services.
4. Capture admin bootstrap output and local access URL.
5. Record local overrides required for future provider onboarding.

## Why Local Compose Mode
This mode keeps the data in project directories, which simplifies backup, migration, and inspection during early setup.

## Deferred Items
- Antigravity account onboarding
- Seed data for channels and subscription plans
- Local branding details
- Purchase URL wiring
