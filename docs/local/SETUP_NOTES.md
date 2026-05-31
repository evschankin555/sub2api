# Setup Notes

## Status
- Base worktree created from the upstream repository.
- This repository is for execution and controlled adaptation, not for broad provider research.
- 2026-05-12: Baseline Sub2API deployment is live at `https://api.developing-site.ru`.
- 2026-05-13: Production started on the local Russian/Antigravity image `sub2api-local:ru-antigravity-20260513`.
- 2026-05-14 MSK: Production was updated to migration-ready image `sub2api-local:ru-antigravity-20260513-r2`.
- 2026-05-14 MSK: Dedicated-server deployment is live on `gptclaudegemini.xyz`; dashboard moved to `https://d.gptclaudegemini.xyz` and `https://api.gptclaudegemini.xyz` is API-only.

## Planned Bring-Up Path
1. Use `deploy\docker-compose.local.yml`.
2. Generate `.env` from `deploy\.env.example`.
3. Start PostgreSQL, Redis, and app services.
4. Capture admin bootstrap output and local access URL.
5. Record local overrides required for future provider onboarding.

## Why Local Compose Mode
This mode keeps the data in project directories, which simplifies backup, migration, and inspection during early setup.

## Public Deployment
- Domain: `api.developing-site.ru`
- DNS: `A` record points to `188.225.11.147`.
- SSH access: `root@188.225.11.147` works with the local SSH configuration.
- Server stack observed on 2026-05-12: Ubuntu 22.04, Docker, Docker Compose, Nginx, Certbot.
- Deployment directory: `/opt/sub2api`.
- Compose file: `/opt/sub2api/docker-compose.local.yml`.
- Runtime env file: `/opt/sub2api/.env` with root-only permissions; secrets are not stored in this repository.
- Bootstrap credentials file: `/root/sub2api-bootstrap.txt` with root-only permissions.
- Reverse proxy: Nginx server block at `/etc/nginx/sites-available/api.developing-site.ru.conf`, symlinked into `sites-enabled`.
- App listener: `127.0.0.1:8080`; external port `8080` remains closed.
- Public health check: `https://api.developing-site.ru/health`.
- Let's Encrypt certificate issued by Certbot; first certificate expiry observed as 2026-08-10.
- Nginx backup before deployment: `/root/nginx-backup-before-sub2api-20260512-234533.tar.gz`.
- Validation completed: Docker services healthy, local and public health checks pass, admin login smoke test passes.
- Operational caution: the server is shared and disk usage was about 88% on `/` during deployment, so future maintenance should avoid broad cleanup or unrelated service changes.

## 2026-05-13 Russian Locale And Antigravity Baseline
- Frontend locale `ru` was added and set as the default deployment locale; the language switcher now includes `English`, `中文`, and `Русский`.
- The deployed app image is `sub2api-local:ru-antigravity-20260513`, built from this repository with embedded frontend assets.
- Compose backup before the image swap: `/opt/sub2api/docker-compose.local.yml.bak-20260513-183917`.
- The compose change only replaced the `sub2api` image; PostgreSQL, Redis, and data directories were not recreated.
- Production verification after deploy: `sub2api`, `sub2api-postgres`, and `sub2api-redis` are healthy; `http://127.0.0.1:8080/health` and `https://api.developing-site.ru/health` return `{"status":"ok"}`; HTTP redirects to HTTPS; `127.0.0.1:8080` remains the only app listener.
- Nginx config test succeeds. Existing unrelated Nginx warnings remain present on the shared server and were not changed.
- The Docker build required a temporary `/tmp/sub2api-build.swap` file because the shared server swap was full; it was removed automatically after the successful build.
- Disk usage after deploy was about 96% on `/`, so future image builds should continue to avoid broad Docker cleanup and should stop if free space drops further.
- Later validation found a duplicate `copyAccounts` locale object in `en`, `zh`, and `ru`; it was fixed locally so `admin.groups.copyAccounts.accountCountLabel` is present in the final locale shape.
- A follow-up rebuild to redeploy that small locale fix was stopped before deployment when `/` dropped to about 100% used during Go compilation. Only temporary build files created for this attempt were removed; no Docker prune or unrelated cleanup was performed.

## 2026-05-13 Server Disk Cleanup
- Starting point after the stopped rebuild: `/` was about 96% used with roughly 3.5 GB free.
- Removed safe Docker leftovers only: one stopped test/build container, dangling images from Sub2API image build attempts, unused networks, and empty builder cache. Running containers, named volumes, and other project data were not removed.
- Docker cleanup reclaimed about 4.4 GB total (`528 MB` stopped container writable layer plus about `3.9 GB` dangling images).
- Removed `/tmp` top-level entries older than 14 days, including old temporary archives, PHP temp upload files, Chromium/Playwright temp folders, and obsolete SQL/tar temp files. Current `/tmp` entries were left in place.
- Cleaned APT package cache and shrank oversized `/var/log/*/git_auto_update.log` files by keeping their last 5000 lines instead of deleting the logs outright.
- Final observed disk state: `/` about 80% used with roughly 17 GB free.
- Deliberately not removed without a separate decision: Docker rollback/build-base images, Docker volumes, `/var/backups`, project directories under `/opt` and `/var/www`, root toolchains/caches such as `/root/.local`, `/root/bin/depot_tools`, and `/opt/playwright-browsers`.

## 2026-05-13 x-one2 Decommission Cleanup
- User confirmed that `x-one2` will not be used in the future and approved deleting all related artifacts.
- Removed matched `x-one2` / `xone2` backup and release artifacts under `/var/backups`, `/root`, `/var/www`, `/var/lib/letsencrypt/backups`, and the root filesystem.
- Dropped obsolete MySQL database `xone2_test`; no active MySQL sessions for that database were observed before removal.
- Removed unused Nginx basic-auth file `/etc/nginx/.htpasswd_xone2`; no active Nginx references to `x-one2` / `xone2` were present.
- Docker scan found no `x-one2` / `xone2` containers, images, volumes, or networks to remove.
- Final observed disk state after this cleanup: `/` about 77% used with roughly 19 GB free; Sub2API health checks still returned `{"status":"ok"}` and `127.0.0.1:8080` remained the only app listener.

## 2026-05-14 Migration-Ready r2 Image And Package
- Built and deployed `sub2api-local:ru-antigravity-20260513-r2` from the local Russian/Antigravity worktree.
- Compose backup before r2 image swap: `/opt/sub2api/docker-compose.local.yml.bak-20260514-013855-pre-r2`.
- The r2 deploy replaced only the `sub2api` image; PostgreSQL, Redis, and data directories were not recreated.
- Frontend verification on the build source passed: `pnpm -C frontend typecheck` and `pnpm -C frontend test:run` with 91 files / 544 tests passing. A direct bind-mounted `pnpm build` overloaded the shared old server, so production asset build was verified through the Dockerfile image build instead.
- The Docker image build used a temporary `/tmp/sub2api-r2-build.swap` file and CPU limiting to avoid repeating the disk/memory pressure from the earlier build attempt; the temporary swap file was removed automatically.
- Created root-only migration package at `/root/sub2api-migration-20260513` with image tar, compose, `.env`, PostgreSQL logical dump, app data archive, Redis data archive, bootstrap credentials, checksums, staging Nginx config, and `restore-staging.sh`.
- Migration package permissions were validated: package directory `700`, secret files `600`, checksum verification passed.
- Production verification after r2 deploy: `sub2api`, `sub2api-postgres`, and `sub2api-redis` are healthy; local and public health checks return `{"status":"ok"}`; `8080` still listens only on `127.0.0.1`.
- Migration runbook for the new server is tracked in `docs/local/MIGRATION_RUNBOOK.md`; it intentionally contains no secrets.

## 2026-05-14 New Dedicated Server And Domain Direction
- New server purchased as `srv_141893` with IP `185.228.72.116`, Ubuntu 22.04 LTS, 2 vCPU, 2 GB RAM, 40 GB SSD, Fremont CA.
- SSH root access by local key was configured; local SSH aliases are `srv_141893`, `sub2api-new`, and `gptclaudegemini`.
- Password authentication was observed as enabled and was not disabled in this step to avoid lockout during provisioning.
- Target DNS layout for `gptclaudegemini.xyz`: root domain points to a static placeholder, `d.gptclaudegemini.xyz` hosts the full Sub2API dashboard/admin UI, and `api.gptclaudegemini.xyz` exposes API/gateway endpoints only.
- Public DNS had not propagated yet when first checked from `1.1.1.1` and `8.8.8.8`; server network reachability and SSH port were confirmed.

## 2026-05-14 Dedicated Server Cutover
- DNS for `gptclaudegemini.xyz`, `d.gptclaudegemini.xyz`, and `api.gptclaudegemini.xyz` resolves to `185.228.72.116`.
- New server stack installed: Docker Engine, Docker Compose plugin, Nginx, Certbot, `zstd`, and supporting packages. Docker and Nginx are enabled.
- Root placeholder is deployed at `/var/www/gptclaudegemini.xyz/index.html` from `docs/local/homepage-placeholders/neutral-2-terminal-empty.html`.
- Sub2API is restored on the new server under `/opt/sub2api` using image `sub2api-local:ru-antigravity-20260513-r2`; app listener remains private on `127.0.0.1:8080`.
- Nginx routing: `gptclaudegemini.xyz` serves static placeholder only; `d.gptclaudegemini.xyz` proxies the full dashboard/admin UI; `api.gptclaudegemini.xyz` proxies only `/health`, `/v1`, `/v1/*`, `/v1beta`, `/v1beta/*`, `/antigravity/v1`, `/antigravity/v1/*`, `/antigravity/v1beta`, and `/antigravity/v1beta/*`, with other routes returning JSON 404.
- Let's Encrypt certificate `gptclaudegemini.xyz` covers `gptclaudegemini.xyz`, `d.gptclaudegemini.xyz`, and `api.gptclaudegemini.xyz`; expiry observed as 2026-08-11.
- Final cutover dump from the old server was created as `/root/sub2api-final-cutover-20260514-035108.sql.gz` with data archive `/root/sub2api-final-data-20260514-035108.tar.gz` and restored on the new server.
- Validation passed: root HTTP redirects to HTTPS, placeholder content is served, `d.` and `api.` health checks return `{"status":"ok"}`, admin login smoke test passed, `api.` UI routes return JSON 404, and external `8080` is not reachable.
- Old server `188.225.11.147` remains as standby with PostgreSQL and Redis running, but the `sub2api` container is stopped to prevent split writes. Do not delete old `/opt/sub2api` or migration artifacts until the standby window is accepted.

## 2026-05-14 Statistics Mini Frontend
- DNS for `statistics.gptclaudegemini.xyz` resolves to `185.228.72.116`.
- The statistics mini frontend source was found in `D:\cursor\ccg-stats-mini-frontend`; production assets were built with `npm run build`.
- Static assets are deployed on the dedicated server under `/var/www/statistics.gptclaudegemini.xyz`.
- Nginx server block: `/etc/nginx/sites-available/statistics.gptclaudegemini.xyz.conf`, symlinked into `sites-enabled`.
- Runtime `app-config.json` on this host points to `https://statistics.gptclaudegemini.xyz` so browser requests use same-origin API calls.
- Nginx proxies `/api/public/lookup` and `/api/public/*` to the existing statistics backend `https://gpt.developing-site.ru`, avoiding CORS changes on the backend/Render bridge.
- Follow-up fix removed the frontend fallback mirrors for `https://gpt.developing-site.ru` and `https://gpt-parser-bridge.onrender.com`; the deployed JS now uses `window.location.origin` plus the same-origin runtime config, so browser traffic stays on `statistics.gptclaudegemini.xyz`.
- Let's Encrypt certificate `statistics.gptclaudegemini.xyz` was issued by Certbot; expiry observed as 2026-08-12.
- Validation passed: HTTP redirects to HTTPS, the static app loads, `/app-config.json` returns the statistics host, `POST /api/public/lookup` proxies to the upstream backend, and a browser network check showed no direct frontend calls to the old backend or Render bridge.

## 2026-05-17 Statistics And Codex Guide Cross-Link
- Added a visible `Instruction` / `Инструкция` link in the statistics mini frontend pointing to `https://codex-only.onrender.com/?lang=<current-language>`.
- Added a visible `Open statistics` / `Открыть статистику` backlink in the Codex-only guide pointing to `https://statistics.gptclaudegemini.xyz/?lang=<current-language>`.
- Statistics source was updated in `D:\cursor\ccg-stats-mini-frontend`, committed as `572f02b` (`feat: link guide from stats`), pushed to `origin/main`, built with `npm run build`, and deployed to `/var/www/statistics.gptclaudegemini.xyz` on `gptclaudegemini`.
- Server backup before replacing statistics static files: `/root/statistics.gptclaudegemini.xyz-before-links-20260517-200613.tar.gz`.
- Codex-only guide source was updated in `D:\cursor\sale\codex-only`, committed as `4d85606` (`feat: link stats and guide`), and pushed to `origin/main` for Render auto-deploy.
- Validation passed with a browser check: statistics links to `https://codex-only.onrender.com/?lang=ru`, and the guide links back to `https://statistics.gptclaudegemini.xyz/?lang=ru`.

## 2026-05-18 Statistics Token-Only Display
- The statistics mini frontend now keeps email lookup support internally but no longer advertises email entry in visible copy or placeholders.
- Search copy now presents token entry only; saved items and detail titles use `maskedKey` / neutral key labels and never render `detail.email`.
- Source was updated in `D:\cursor\ccg-stats-mini-frontend`, committed as `3aaadf5` (`fix: hide emails in stats`), pushed to `origin/main`, built with `npm run build`, and deployed to `/var/www/statistics.gptclaudegemini.xyz` on `gptclaudegemini`.
- Server backup before replacing statistics static files: `/root/statistics.gptclaudegemini.xyz-before-token-display-20260518-120534.tar.gz`.
- Validation passed with a local mocked lookup where the backend returned `client@example.com`: the UI displayed `cr_...ABCD1234` and did not render the email. Live browser check also confirmed the placeholder is `Введите токен` and the visible text has no `email` mention.

## 2026-05-19 Statistics Telegram Mini App Boot
- The statistics mini frontend now loads `telegram-web-app.js` asynchronously and retries `Telegram.WebApp.ready()` / `expand()` from both the inline boot script and the React app, so a slow Telegram script does not block the static app from rendering.
- Source was updated in `D:\cursor\ccg-stats-mini-frontend`, committed as `bd2dccb` (`fix: stabilize telegram mini app boot`), pushed to `origin/main`, built with Vite, and deployed to `/var/www/statistics.gptclaudegemini.xyz` on `gptclaudegemini`.
- Server backup before replacing statistics static files: `/root/statistics.gptclaudegemini.xyz-before-tg-boot-20260519-120844.tar.gz`.
- Validation passed: live `index.html` serves `/assets/index-CQZro-rE.js`, `window.__CCG_BOOT_TELEGRAM__` is present, `window.__CCG_TG_READY__` becomes true when `telegram-web-app.js` loads, and the page still renders the token input if that external Telegram script is blocked.
- Added a minimal isolated Mini App diagnostic page at `https://statistics.gptclaudegemini.xyz/tg-test.html?v=20260519`, committed as `94ce008` (`feat: add telegram mini app test page`), pushed to `origin/main`, and deployed to the same static host.
- Server backup before adding the diagnostic page: `/root/statistics.gptclaudegemini.xyz-before-tg-test-20260519-132234.tar.gz`.

## 2026-05-13 Antigravity Operator Seed
- Existing `default` group remains unchanged as `anthropic` / `standard`.
- Created or verified group `Antigravity Default` with platform `antigravity`, exclusive access enabled, `rate_multiplier=1`, `rpm_limit=0`, `mcp_xml_inject=true`, scopes `["claude","gemini_text","gemini_image"]`, OAuth/privacy filters disabled, and image generation disabled.
- Created or verified disabled channel placeholder `Antigravity Sandbox`, linked only to `Antigravity Default`, with empty model mapping and no model pricing rows.
- No Antigravity account, provider secret, pricing rule, or channel enablement was added in this step.

## 2026-05-29 Prompt Capture Decommission
- Operator decision: stop accumulating user prompt text and disable async prompt analysis on `ai.gptclaudegemini.xyz`.
- Live proxy env `/opt/ai-route-proxy/.env.prompt-mb` now sets `PROMPT_TRACE_DEFAULT_ENABLED=false` and `PROMPT_ANALYZER_ENABLED=false`; service `ai-route-proxy-prompt-mb.service` on `127.0.0.1:3133` remains the active route.
- Historical prompt tables were archived to `/root/ai-route-proxy-prompt-archive-20260529-031855` with `SHA256SUMS.txt`, then truncated in MariaDB: `proxy_prompt_trace_events`, `proxy_prompt_trace_sessions`, `proxy_prompt_trace_pauses`, `proxy_prompt_analysis_results`.
- Route/model/CRM telemetry is unchanged; only prompt body storage and analysis jobs are off by default.
- Re-enable only with an explicit operator decision; do not turn prompt capture back on silently during unrelated proxy work.

## 2026-05-31 Sub2API 20x/5x Mirror Proxy
- Added an independent streaming mirror proxy for `20x.gptclaudegemini.xyz` and `5x.gptclaudegemini.xyz`; the existing `ai.gptclaudegemini.xyz` proxy on `127.0.0.1:3133` was not restarted or repointed.
- New systemd service: `ai-route-proxy-sub2api.service`, binary `/opt/ai-route-proxy/bin/ai-route-proxy-20260531-sub2api`, env `/opt/ai-route-proxy/.env.sub2api`, listener `127.0.0.1:3134`.
- New gateway settings: `UPSTREAM_BASE=https://sub2api.gptclubapi.xyz`, `ROUTE_MODE=mirror`, `AUTH_MODE=passthrough`, `PROMPT_TRACE_DEFAULT_ENABLED=false`, `PROMPT_ANALYZER_ENABLED=false`.
- Mirror mode preserves path and query exactly, e.g. `/v1/models` maps to `https://sub2api.gptclubapi.xyz/v1/models`; no WebSocket Upgrade tunnel was added in v1.
- Created separate MariaDB schema `ai_route_proxy_sub2api` for 20x/5x telemetry, using the existing local MariaDB container and existing proxy DB user. This keeps 20x/5x stats separate from the AI proxy telemetry DB.
- Let's Encrypt certificate was issued for `20x.gptclaudegemini.xyz` and `5x.gptclaudegemini.xyz`; cert path `/etc/letsencrypt/live/20x.gptclaudegemini.xyz/`.
- Nginx config `/etc/nginx/sites-available/20x-5x.gptclaudegemini.xyz.conf` proxies both hosts to `127.0.0.1:3134` with streaming-safe settings from `ai-route-proxy-params.conf`, `gzip off`, and `client_max_body_size 20m`.
- Statistics Nginx now exposes `/api/proxy/telemetry/sub2api` and `/api/proxy/telemetry/sub2api/*` to `127.0.0.1:3134/telemetry`; the original `/api/proxy/telemetry` route remains on `127.0.0.1:3133`.
- Statistics Nginx telemetry proxy timeouts were raised from `10s` to `30s` because the existing AI telemetry endpoint can take about 12 seconds under live MariaDB load; this avoids a false `504` on the monitor page without restarting the AI proxy.
- The statistics frontend source in `D:\cursor\ccg-stats-mini-frontend` now has proxy source tabs: `AI` and `20x / 5x`. The selected source is stored in localStorage and all detail/admin telemetry calls use the selected source.
- Production frontend assets were rebuilt with Vite and deployed to `/var/www/statistics.gptclaudegemini.xyz`; server backups were created under `/root/statistics.gptclaudegemini.xyz-before-sub2api-source-*`.
- Validation passed: DNS resolves both new hosts to `185.228.72.116`; `https://20x.gptclaudegemini.xyz/healthz` and `https://5x.gptclaudegemini.xyz/healthz` return version `2026-05-31.1`; `https://ai.gptclaudegemini.xyz/healthz` still returns `2026-05-27.8`; invalid-token `/v1/models` reaches upstream and returns upstream `401`; admin telemetry shows `sub2api 2026-05-31.1` while AI telemetry remains `2026-05-27.8`; browser smoke on `statistics.gptclaudegemini.xyz/?lang=en&proxyMonitor=1&proxyAdmin=1` switches to `20x / 5x` with zero console errors.

## 2026-05-29 Sub2API Russian Locale Deploy
- Committed the full Russian frontend locale baseline locally as `84a7769c` on branch `sub2api-base-local`.
- Built and deployed image `sub2api-local:ru-antigravity-20260529` on `gptclaudegemini` from the committed worktree tarball.
- Compose backup before image swap: `/opt/sub2api/docker-compose.local.yml.bak-20260529-*-pre-ru-commit`.
- Only the `sub2api` container was recreated; PostgreSQL, Redis, and data directories were not recreated.
- Validation passed: `sub2api` healthy, `http://127.0.0.1:8080/health` and `https://d.gptclaudegemini.xyz/health` return `{"status":"ok"}`.

## Deferred Items
- Antigravity account onboarding after purchase
- Seed data for channels and subscription plans
- Local branding details
- Purchase URL wiring

## 2026-05-24 AI Route Streaming Proxy
- Added a separate production streaming proxy on `ai.gptclaudegemini.xyz`; this is intentionally separate from the Sub2API hosts `api.gptclaudegemini.xyz` and `d.gptclaudegemini.xyz`.
- DNS for `ai.gptclaudegemini.xyz` resolves to `185.228.72.116`; `route.gptclaudegemini.xyz` was not used because it did not resolve during implementation.
- Gateway service is deployed on the dedicated server under `/opt/ai-route-proxy` and runs as `ai-route-proxy.service`, listening only on `127.0.0.1:3120`.
- Public routing is `client -> Nginx TLS -> 127.0.0.1:3120 -> https://api.gptclubapi.xyz/openai`; `/openai/*` is canonical and `/v1/*` is supported as an OpenAI-compatible alias.
- Nginx server block `/etc/nginx/sites-available/ai.gptclaudegemini.xyz.conf` uses streaming-safe proxy settings: no proxy buffering, no request buffering, 3600s read/send timeouts, `gzip off`, and `client_max_body_size 20m`.
- Nginx core limits were raised for streaming load: `worker_rlimit_nofile 65535`, `worker_connections 16384`, `multi_accept on`, `keepalive_requests 10000`, and `underscores_in_headers on`.
- Let's Encrypt certificate `ai.gptclaudegemini.xyz` was issued by Certbot and expires on 2026-08-22.
- Proxy keys are stored hashed in `/opt/ai-route-proxy/keys.json`; the initial bootstrap key is root-only at `/opt/ai-route-proxy/BOOTSTRAP_PROXY_KEY.txt` and should be rotated after first distribution.
- Upstream secret is not committed or printed; set it on the server in `/opt/ai-route-proxy/.env` as `UPSTREAM_API_KEY=<gptclub key>` and restart `ai-route-proxy.service` before live API use.
- Current limits are per-key concurrency 10, global concurrency 1200, per-key RPS 30, global RPS 1000, max body 20 MB, connect timeout 10s, and upstream response-header timeout 120s.
- Validation passed for DNS, HTTPS `/healthz`, missing-key `401`, invalid-key `403`, service/Nginx health, and regression checks for the existing `api.`, `d.`, `statistics.`, and `or.` hosts. Live upstream streaming remains blocked until `UPSTREAM_API_KEY` is installed.

## 2026-05-24 AI Route Pass-Through Auth
- `ai-route-proxy.service` was updated to version `2026-05-24.2` and switched to `AUTH_MODE=passthrough` so any non-empty `Authorization: Bearer ...` token is forwarded to `https://api.gptclubapi.xyz/openai` without checking `/opt/ai-route-proxy/keys.json`.
- Missing or malformed bearer headers still return local `401`; invalid tokens now return upstream `401` responses instead of local `403`, proving the token gate is removed.
- Local `CRS_OAI_KEY` was verified against `https://ai.gptclaudegemini.xyz/v1/models` with HTTP 200; direct streaming test still returned upstream HTTP 400, matching the old direct `https://api.gptclubapi.xyz/openai/v1/responses` behavior and not indicating a proxy-side block.

## 2026-05-24 AI Route Proxy Telemetry
- `ai-route-proxy` was upgraded on `gptclaudegemini` to version `2026-05-24.5` and now exposes safe JSON telemetry at `http://127.0.0.1:3120/telemetry`; `/metrics` remains local Prometheus-style text and now also includes `ai_route_proxy_client_disconnects_total`.
- Telemetry tracks rolling 10-second buckets for requests, proxied responses, active streams, rate limits, auth failures, upstream errors, client disconnects, response bytes, latency, active upstream probes, upstream availability, and top key hash prefixes only. Full prompts and bearer tokens are still not logged or exposed.
- `statistics.gptclaudegemini.xyz` Nginx now proxies `GET /api/proxy/telemetry` to the local proxy service. Public `/metrics` was not exposed.
- The stats mini frontend was redeployed to `/var/www/statistics.gptclaudegemini.xyz` with a hidden proxy monitoring card shown only when `?proxyMonitor=1` is present; it appears after the saved-key list and refreshes telemetry every 10 seconds while visible.
- Validation: `go test ./...` passed for `/opt/ai-route-proxy/src`; `nginx -t` passed; `https://statistics.gptclaudegemini.xyz/api/proxy/telemetry` returns JSON; `https://statistics.gptclaudegemini.xyz/?lang=ru` renders the monitoring card without browser console errors.

## 2026-05-24 AI Route Persistent Route Telemetry
- `ai-route-proxy.service` was upgraded on `gptclaudegemini` to version `2026-05-24.6`; the service still listens only on `127.0.0.1:3120`.
- Added a separate MariaDB container for proxy telemetry only: `ai-route-proxy-mariadb`, compose file `/opt/ai-route-proxy/docker-compose.telemetry.yml`, env file `/opt/ai-route-proxy/telemetry-db.env` with root-only permissions, data directory `/opt/ai-route-proxy/mariadb_data`, and host binding `127.0.0.1:3307`.
- Proxy runtime env `/opt/ai-route-proxy/.env` now includes the names `TELEMETRY_DSN`, `IP_HASH_SALT`, `GEOIP_DB_PATH`, `TELEMETRY_RETENTION_DAYS`, and `TRUSTED_PROXY_CIDRS`; secret values stay only on the server.
- GeoIP uses a local MMDB file at `/opt/ai-route-proxy/geoip/dbip-city-lite.mmdb`; no client IP is sent to external GeoIP APIs.
- Persistent telemetry stores one-minute rollups and route state/events in MariaDB tables `proxy_telemetry_rollup_1m`, `proxy_key_route_state`, and `proxy_route_events`. Full IPs, prompts, request bodies, bearer tokens, and upstream secrets are not stored or exposed.
- Public telemetry API remains compatible at `GET /api/proxy/telemetry` and now also exposes `ranges`, `keys`, `countries`, and `asns`; key drill-down is available through `GET /api/proxy/telemetry/key/<keyHash>?range=10m|1h|24h`.
- `statistics.gptclaudegemini.xyz` Nginx keeps the exact `/api/proxy/telemetry` proxy and adds the prefix `/api/proxy/telemetry/` to route key drill-down calls to `127.0.0.1:3120/telemetry/`.
- The hidden statistics frontend monitor was expanded into an operational route dashboard shown only with `?proxyMonitor=1`, still after the saved-key list. It displays active streams, RPS, latency, upstream header timing, countries, ASN distribution, per-key country/city/masked IP, errors, disconnects, route score, and key detail ranges.
- Browser validation passed after deploying the statistics frontend: without `?proxyMonitor=1`, the page makes no `/api/proxy/telemetry` calls; with `?proxyMonitor=1`, the route dashboard and key drill-down load on desktop and mobile without console errors.
- Server validation passed: `ai-route-proxy.service` is active, `/healthz` returns version `2026-05-24.6`, MariaDB container health is `healthy`, `nginx -t` succeeds, and `https://statistics.gptclaudegemini.xyz/api/proxy/telemetry` returns route telemetry with keys and countries.

## 2026-05-24 AI Route Key Labels And Client Version
- `ai-route-proxy.service` was upgraded on `gptclaudegemini` to version `2026-05-24.7`.
- Route telemetry now stores and exposes only a masked bearer label such as `...ABC123` plus `keySuffix`; the full bearer token is still never stored, logged, or returned.
- Route telemetry now records the latest observed client identity from safe request headers, primarily `User-Agent` and optional `X-Codex-Client-Version` / `X-Codex-Version` / `X-Client-Version` / `OpenAI-Client-Version`.
- MariaDB table `proxy_key_route_state` was migrated with `key_label`, `key_suffix`, `client_name`, `client_version`, and `client_user_agent` columns.
- The hidden statistics proxy monitor now shows `Key / client` in the route table and the client line in key detail, so Codex CLI/TUI versions can be correlated with route errors and latency.
- Validation passed: `go test ./...` on `/opt/ai-route-proxy/src`, service restart, `/healthz` version `2026-05-24.7`, live telemetry includes masked key labels and client version, and the deployed statistics UI renders the new fields without console errors.

## 2026-05-24 AI Route Admin Metadata
- `ai-route-proxy.service` was upgraded on `gptclaudegemini` to version `2026-05-24.8`.
- Added admin-only telemetry auth through `TELEMETRY_ADMIN_TOKEN` in `/opt/ai-route-proxy/.env`; the current token is stored root-only in `/opt/ai-route-proxy/ADMIN_TOKEN.txt`.
- Public telemetry remains safe: without the admin token, `/api/proxy/telemetry` and key drill-down do not expose manually assigned emails or names.
- Admin telemetry accepts `X-Proxy-Admin-Token` and returns `admin: true` plus per-key `name` and `email` fields when available.
- Added admin metadata endpoint `PUT /api/proxy/telemetry/key/<keyHash>/metadata` with JSON `{ "name": "...", "email": "..." }`; it updates only existing observed keys.
- MariaDB table `proxy_key_route_state` was migrated with `admin_name` and `admin_email`; these fields are operator labels, not data pulled from bearer tokens.
- The hidden statistics proxy monitor now has an admin login form. After admin auth it shows extra name/email data and an editor in the key detail panel.
- Validation passed: wrong admin token returns `401`, public mode omits email/name, admin mode unlocks the UI, metadata save was tested with a temporary dummy key and cleaned up, and the deployed UI renders public/admin modes without console errors.

## 2026-05-24 AI Route Hidden Admin Login
- The proxy monitor remains behind `?proxyMonitor=1`, but the admin login form is now additionally hidden behind `?proxyAdmin=1`.
- Normal operator view: `https://statistics.gptclaudegemini.xyz/?lang=ru&proxyMonitor=1` shows telemetry without the admin login panel.
- Admin login view: `https://statistics.gptclaudegemini.xyz/?lang=ru&proxyMonitor=1&proxyAdmin=1` shows the token input. After successful login, the token is kept only in browser `sessionStorage`.
- Admin token remains root-only on the server at `/opt/ai-route-proxy/ADMIN_TOKEN.txt`; retrieve it via SSH when needed instead of copying it into repository files.
- Validation passed: normal monitor URL has no admin token input, admin URL shows the input, and an already-unlocked admin session still shows metadata editors while keeping the login panel hidden unless `proxyAdmin=1` is present.

## 2026-05-24 AI Route Score And Admin Labels UX
- Rotated the proxy telemetry admin token to a clean 48-character hex value and rewrote `TELEMETRY_ADMIN_TOKEN` in `/opt/ai-route-proxy/.env`; the root-only copy remains `/opt/ai-route-proxy/ADMIN_TOKEN.txt`.
- Added an in-dashboard explanation for route `Score 0-100`: higher is better; penalties come from latency, upstream header delay, errors, client disconnects, and recent IP changes.
- In admin mode the route table now has a visible `Имя / Email` column. Unlabeled keys show `имя не задано` / `email не задан` until the operator saves metadata.
- The key detail metadata editor is now wrapped in an explicit `Admin: подпись ключа` card with a note that email/name are operator labels and cannot be recovered from hash values.
- Validation passed: public monitor shows score explanation but no admin login or name/email column; admin session shows the name/email column and metadata editor without console errors.

## 2026-05-25 SigmaGate Profile Prototype
- Created a standalone dark HTML prototype at `docs/local/stats-widget-prototypes/sigmagate-user-profile-modern-variants.html` based on `https://sigmagate.link/user.php?id=09Bs6VgmSm3z_P2v`.
- The prototype keeps the visible source content: user greeting, inactive subscription state, expiration timestamp, negative remaining days, Karing setup steps, account/settings/support actions, and the subscription payment gate.
- Deployed the static file to `/var/www/statistics.gptclaudegemini.xyz/sigmagate-user-profile-modern-variants.html` on `gptclaudegemini`.
- Public URL: `https://statistics.gptclaudegemini.xyz/sigmagate-user-profile-modern-variants.html`.
- Validation passed: HTTPS returns 200, deployed SHA256 matches the local file, and desktop/mobile Playwright smoke checks show no console errors.

## 2026-05-26 AI Route Security Observation
- `ai-route-proxy` upgraded to version `2026-05-26.1` with observe-only security telemetry for OpenAI-compatible JSON routes. The public endpoint remains `https://ai.gptclaudegemini.xyz/openai`; no traffic split, auto-block, or auto-throttle is enabled.
- Security capture is limited to model names matching `SECURITY_MODEL_PATTERNS` (default `5.5`) and only creates `proxy_security_events` when the model response contains a safety/cyber warning or refusal. Normal prompts and non-flagged responses are not stored.
- Flagged events store redacted prompt/messages and response excerpts with caps of 256 KB request text and 512 KB response text. Authorization headers, raw proxy keys, upstream secrets, full IP addresses, and normal request bodies are not stored or returned.
- MariaDB migrations add `proxy_model_rollup_1m`, `proxy_security_events`, and `proxy_key_tags`; retention follows `TELEMETRY_RETENTION_DAYS=14` and cleanup removes old model/security rows and old auto tags.
- Admin telemetry now exposes `/api/proxy/telemetry/security`, `/api/proxy/telemetry/security/events`, `/api/proxy/telemetry/security/key/<keyHash>`, and `PATCH /api/proxy/telemetry/security/events/<id>` through the statistics host. Sensitive security content requires the existing admin token and the hidden UI URL `?proxyMonitor=1&proxyAdmin=1`.
- Admin key metadata endpoint now accepts `name`, `email`, `tags`, and `adminNotes`; public telemetry still omits operator labels and security content without a valid admin token.
- Blue-green rollout used `/opt/ai-route-proxy/bin/ai-route-proxy-20260526-security` and `ai-route-proxy-green.service` on `127.0.0.1:3121`; Nginx now routes both `ai.gptclaudegemini.xyz` and statistics telemetry prefixes to `3121`. The old `ai-route-proxy.service` on `3120` was stopped only after active streams reached `0` and is disabled for rollback/reference.
- Rollback path: switch the two Nginx site files back from `127.0.0.1:3121` to `127.0.0.1:3120`, enable/start `ai-route-proxy.service`, then run `nginx -t && systemctl reload nginx`.

## 2026-05-26 AI Route Anthropic Partner Console Candidate
- New candidate supplier docs were reviewed at `https://anthropic-api.com/docs`. It exposes OpenAI-compatible `https://anthropic-api.com/v1/*` and Anthropic-compatible `https://anthropic-api.com/v1/messages` surfaces with streaming support via `stream: true`.
- For the existing `ai.gptclaudegemini.xyz` proxy, the compatible upstream base is the bare host `https://anthropic-api.com`, not `https://anthropic-api.com/v1`, because `ai-route-proxy` already forwards public `/v1/*` and `/openai/v1/*` paths onto the upstream base.
- To resell through local proxy keys instead of forwarding buyer keys to the old supplier, the live proxy must switch from `AUTH_MODE=passthrough` to `AUTH_MODE=proxy_key` and store the supplier key only as `UPSTREAM_API_KEY` in `/opt/ai-route-proxy/.env.green` on the server.
- Do not commit, log, or paste the full supplier key into repository docs. Validate with `/v1/models` and one streaming `/v1/chat/completions` request after the key is installed.

## 2026-05-26 Local Direct Supplier Probe
- Added local template `.env.partner-console.example` in the repo root for direct supplier testing without committing secrets.
- The intended local secret file is `.env.partner-console.local` in the repo root; it is already ignored by git through the existing `.env.*.local` rule.
- Added `tools/test_anthropic_partner_console.ps1`, which loads `.env.partner-console.local` and checks `GET /v1/models`, `POST /v1/chat/completions`, `POST /v1/messages`, and an optional negative model probe.
- Use this direct probe before switching `ai.gptclaudegemini.xyz` upstream, so provider capability checks are separated from proxy behavior and local routing.

## 2026-05-26 AI Route Model Usage Telemetry
- `ai-route-proxy` upgraded to version `2026-05-26.2` and now records model rollups for all parsed OpenAI-compatible JSON requests with a `model` field, not only `SECURITY_MODEL_PATTERNS` matches. Security event creation remains limited to watched models and warning/refusal detection.
- Public telemetry now exposes `models` for the last hour and best-effort `currentModels` / `activeModels` for in-flight parsed streams. Per-key route rows expose `models`, `topModel`, `currentModels`, and `currentModel` without storing prompts, raw tokens, headers, full IPs, or request bodies.
- The hidden statistics monitor at `?proxyMonitor=1` now shows top/current model tiles, a Models distribution card, model badges in each key row, and model info in key detail. This is visible in normal monitor mode and does not require admin auth.
- Blue-green rollout moved live Nginx upstreams from `127.0.0.1:3121` to `127.0.0.1:3122` using `ai-route-proxy-models.service` and `/opt/ai-route-proxy/bin/ai-route-proxy-20260526-models`. The old `ai-route-proxy-green.service` on `3121` was stopped/disabled only after active streams reached `0`; `ai-route-proxy.service` on `3120` remains inactive.
- Rollback path: re-enable/start `ai-route-proxy-green.service`, switch both Nginx site files from `127.0.0.1:3122` back to `127.0.0.1:3121`, then run `nginx -t && systemctl reload nginx`.
- Validation passed: `go test ./...` on the staged proxy source, `npm run build` for `ccg-stats-mini-frontend`, `nginx -t`, public `/healthz` returns `2026-05-26.2`, and `https://statistics.gptclaudegemini.xyz/api/proxy/telemetry` returns model rollups and key rows.

## 2026-05-26 AI Route Model Detail UX
- `ai-route-proxy` upgraded to version `2026-05-26.3`. Key detail model rollups now follow the requested detail range `10m|1h|24h`; summary table model rollups remain a one-hour overview.
- Live Nginx routing moved from `127.0.0.1:3122` to `127.0.0.1:3123` using `ai-route-proxy-model-detail.service` and `/opt/ai-route-proxy/bin/ai-route-proxy-20260526-model-detail`. The previous `ai-route-proxy-models.service` on `3122` was stopped/disabled after active streams reached `0`.
- Statistics monitor now separates `active now` model data from `history 1h` model data in key rows and opens key details in a modal-style panel with separate active/history model sections.
- Prompt/body content is still not captured for normal requests. Only flagged security events store redacted prompt/response excerpts as described in the Security Observation entry.
- Validation passed: `go test ./...` for `/opt/ai-route-proxy/src`, `npm run build` for the statistics frontend, `nginx -t`, public `/healthz` returns `2026-05-26.3`, and public telemetry returns model rollups plus current model data.

## 2026-05-26 AI Route Targeted Prompt Trace
- `ai-route-proxy` upgraded to version `2026-05-26.4` with admin-only targeted prompt tracing for one selected proxy key at a time. The public endpoint remains `https://ai.gptclaudegemini.xyz/openai`; no traffic split and no automatic blocking are enabled.
- Prompt trace is off by default and is controlled only from the hidden admin monitor `?proxyMonitor=1&proxyAdmin=1` inside a key detail modal. It captures only future user-authored prompt text for that key, not past requests.
- The trace stores redacted prompt text only: no HTTP headers, no `Authorization`, no raw proxy/upstream keys, no full IPs, and no system/developer/tool messages. Request text is capped at 128 KB, session duration is capped at 24 hours, and max captured events is capped at 500.
- MariaDB migrations add `proxy_prompt_trace_sessions` and `proxy_prompt_trace_events`; retention follows `TELEMETRY_RETENTION_DAYS=14`. The security warning capture from `2026-05-26.1` remains unchanged.
- Blue-green rollout used `/opt/ai-route-proxy/bin/ai-route-proxy-20260526-prompt-trace` and `ai-route-proxy-prompt-trace.service` on `127.0.0.1:3124`. Nginx routes for both `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3124`.
- The previous `ai-route-proxy-model-detail.service` on `3123` was stopped and disabled only after `ai_route_proxy_active_streams` reached `0`.
- Rollback path: enable/start `ai-route-proxy-model-detail.service`, switch both Nginx site files from `127.0.0.1:3124` back to `127.0.0.1:3123`, then run `nginx -t && systemctl reload nginx`.
- Validation passed: `go test ./...` on the staged proxy source, prompt trace start/stop API smoke, prompt capture smoke with secret redaction and system-message exclusion, `npm run build`, `nginx -t`, public `/healthz` version `2026-05-26.4`, and public telemetry version `2026-05-26.4`.

## 2026-05-27 AI Route Key Tabs And Prompt Badges
- `ai-route-proxy` upgraded to version `2026-05-27.1` and now includes admin-only per-key prompt trace counters in telemetry: active trace session, prompt events for 24h/14d, and last prompt trace event time. Public telemetry still omits these fields without a valid admin token.
- The hidden statistics monitor key table now has two tabs: active keys with current streams and recent idle keys. The admin-only prompt filter shows only keys with an active prompt trace session or stored prompt trace events.
- Prompt trace badges are shown in the key row only when the admin token is active and prompt data exists for that key. If no prompt trace events exist yet, the badge/filter count remains zero.
- Blue-green rollout used `/opt/ai-route-proxy/bin/ai-route-proxy-20260527-key-tabs` and `ai-route-proxy-key-tabs.service` on `127.0.0.1:3125`. Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3125`.
- The previous `ai-route-proxy-prompt-trace.service` on `3124` was stopped and disabled after its active stream count reached `0`. Old Nginx backup files were moved from `sites-enabled` to `/etc/nginx/sites-backups` so backup server blocks are not loaded.
- Rollback path: enable/start `ai-route-proxy-prompt-trace.service`, switch both Nginx site files from `127.0.0.1:3125` back to `127.0.0.1:3124`, then run `nginx -t && systemctl reload nginx`.
- Validation passed: `go test ./...` on the staged proxy source, `npm run build` for `ccg-stats-mini-frontend`, `nginx -t`, public `/healthz` version `2026-05-27.1`, public telemetry version `2026-05-27.1`, admin telemetry returns the new prompt trace fields, and Playwright smoke confirmed active/recent tabs plus the prompt filter without console errors.

## 2026-05-27 AI Route Blocked Model Denylist
- `ai-route-proxy` upgraded to version `2026-05-27.2` and now rejects known unavailable model names before contacting upstream. The current `BLOCKED_MODELS` value is `gpt-5.2-codex,gpt-5.4-nano,gpt-5.5-pro`.
- The denylist is exact-match only. Working aliases such as `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.3-codex`, and `gpt-5.5` are not blocked.
- Blocked requests return local HTTP `400` with OpenAI-style `code=model_not_available`. They are not forwarded to `api.gptclubapi.xyz`, do not increment upstream/router error counters, and do not create model rollup error rows.
- Blue-green rollout used `/opt/ai-route-proxy/bin/ai-route-proxy-20260527-model-block` and `ai-route-proxy-model-block.service` on `127.0.0.1:3126`. Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3126`.
- The previous `ai-route-proxy-key-tabs.service` on `3125` was stopped and disabled after its active stream count reached `0`. Temporary Nginx backup files were moved from `sites-enabled` to `/etc/nginx/sites-backups` before the final reload.
- Rollback path: enable/start `ai-route-proxy-key-tabs.service`, switch both Nginx site files from `127.0.0.1:3126` back to `127.0.0.1:3125`, then run `nginx -t && systemctl reload nginx`.
- Validation passed: `go test ./...` on the staged proxy source, local blocked-model smoke returned `400 model_not_available`, public blocked-model smoke returned `400 model_not_available`, public allowed-model smoke for `gpt-5.4` returned `200`, `nginx -t` passed, public `/healthz` returns `2026-05-27.2`, public telemetry returns `2026-05-27.2`, and recent model rollups show only working models after the denylist check.

## 2026-05-27 AI Route CRM Auto-Link
- `ai-route-proxy` upgraded to version `2026-05-27.3` and now performs server-side GPT Parser CRM lookup for real bearer tokens that look like `cr_...`; the raw token is used only transiently in a POST body to `https://gpt.developing-site.ru/api/public/lookup`.
- The gateway stores only normalized safe CRM card fields in MariaDB (`proxy_key_crm_cards`): email/name, masked token, bucket transition, marketplace/order id, remote label, usage balance, status, sync/expiry dates, archive reason, and top-up flag.
- Public telemetry still omits CRM cards. Admin telemetry enriches key rows with `crm` only when `X-Proxy-Admin-Token` is valid, so the hidden monitor URL remains `?proxyMonitor=1&proxyAdmin=1`.
- Existing historical key hashes cannot be retro-linked without the original token or a saved buyer email. They auto-link after the next successful request with that token; non-`cr_` tokens are intentionally skipped.
- Live service is `ai-route-proxy-crm-link.service` on `127.0.0.1:3127`; Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3127`. The previous `ai-route-proxy-model-block.service` on `3126` remains active as rollback.
- Rollback path: switch both Nginx site files from `127.0.0.1:3127` back to `127.0.0.1:3126`, run `nginx -t && systemctl reload nginx`, then keep or stop the CRM-link service after active streams drain.
- Validation passed: `npm run build` for `ccg-stats-mini-frontend`, public `/healthz` returns `2026-05-27.3`, public telemetry omits CRM cards, admin telemetry returns CRM cards for linked keys, and the statistics frontend is deployed with telemetry CRM card support.

## 2026-05-27 Prompt Trace UX Shortcut
- The hidden admin monitor now shows a prompt-capture hint on each key row and a visible `start prompt capture` button at the top of the key modal, before the deeper security section.
- Prompt content capture remains targeted and opt-in per key. It starts only after pressing the button, stores future user-authored prompt text for that key only, and keeps the existing redaction/no-headers/no-raw-token rules.
- The existing lower `Prompt trace` panel still shows captured prompt events, active session status, duration, max prompt count, reason, restart, and stop controls.
- Validation passed: `npm run build`, production frontend deploy, and Playwright smoke confirmed the row hint, modal callout, start buttons, and no console errors.

## 2026-05-27 Prompt Trace Default Capture
- `ai-route-proxy` upgraded to version `2026-05-27.4` and now runs with `PROMPT_TRACE_DEFAULT_ENABLED=true` in `/opt/ai-route-proxy/.env.default-trace`.
- Future user-authored prompt text is captured by default for all proxy keys. The same privacy controls remain in place: secret redaction, no headers, no Authorization, no raw proxy/upstream keys, no full IPs, content cap, and telemetry retention.
- Admins can pause capture per key from the hidden monitor key modal. Paused keys are excluded until the admin resumes/restarts capture.
- Default capture uses `session_id=0` in `proxy_prompt_trace_events`; targeted sessions still use rows in `proxy_prompt_trace_sessions` and remain available for explicit restart/max-event workflows.
- Live service is `ai-route-proxy-default-trace.service` on `127.0.0.1:3128`; Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3128`. The previous `ai-route-proxy-crm-link.service` on `3127` remains active as rollback.
- Rollback path: switch both Nginx site files from `127.0.0.1:3128` back to `127.0.0.1:3127`, run `nginx -t && systemctl reload nginx`, then keep or stop the default-trace service after active streams drain.
- Validation passed: `go test ./...`, local prompt-capture smoke confirmed `session_id=0`, pause smoke confirmed paused keys are not captured, public `/healthz` returns `2026-05-27.4`, public telemetry returns `2026-05-27.4`, `npm run build`, production frontend deploy, and Playwright smoke confirmed default-capture badges plus pause controls.

## 2026-05-27 Responses Endpoint Prompt Capture Fix
- `ai-route-proxy` upgraded to version `2026-05-27.5` to include Codex-style `/openai/responses` and bare `/responses` in the JSON audit/capture route matcher.
- Root cause: production traffic was visible in request/model telemetry as `POST /openai/responses`, but prompt capture only matched `/v1/responses` and `/openai/v1/responses`, so the prompt extractor was not invoked for normal Codex usage.
- Live service is `ai-route-proxy-responses-capture.service` on `127.0.0.1:3129`; Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3129`. The previous `ai-route-proxy-default-trace.service` on `3128` remains active as rollback.
- Rollback path: switch both Nginx site files from `127.0.0.1:3129` back to `127.0.0.1:3128`, run `nginx -t && systemctl reload nginx`, then keep or stop the responses-capture service after active streams drain.
- Validation passed: `go test ./...`, local `/openai/responses` smoke created a default prompt trace event with endpoint `/v1/responses`, public `/healthz` returns `2026-05-27.5`, admin prompt telemetry already shows a real non-smoke captured prompt event, and smoke rows were removed from MariaDB after validation.

## 2026-05-27 Async Prompt Analysis And DB Guard
- `ai-route-proxy` upgraded to version `2026-05-27.6` with `proxy_prompt_analysis_results`, async prompt-analysis job queuing, raw prompt retention, security-content retention, and MariaDB size guard settings.
- Live service is `ai-route-proxy-analysis.service` on `127.0.0.1:3131`; port `3130` was already used by `/opt/api-claude-router`, so the blue-green candidate moved to `3131`.
- Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3131`. The previous `ai-route-proxy-responses-capture.service` on `3129` was stopped after its active stream count reached `0`.
- Prompt capture remains default-on and admin-pausable per key. New captured prompts create pending analysis jobs without blocking the streaming path. Raw prompt text is cleared after `PROMPT_RAW_RETENTION_HOURS=24` unless linked to a security event; security events/content use `SECURITY_RETENTION_DAYS=30`; rollup/statistics tables are not purged by this retention pass.
- DB guard is configured by `TELEMETRY_DB_SOFT_CAP_MB=2048` and `TELEMETRY_DB_HARD_CAP_MB=4096`. Soft cap logs/admin-warns; hard cap clears oldest non-flagged raw prompts and non-security analysis summaries, not rollups or security events.
- The hidden admin monitor now shows analysis queue, analyzed/high-risk counters, DB size/raw prompt MB, per-key AI risk badges, and prompt-modal analysis summaries next to captured prompt text.
- `PROMPT_ANALYZER_ENABLED=true`, `PROMPT_ANALYZER_MODEL=gpt-5.4`, and `PROMPT_ANALYZER_REASONING=low` are set in `/opt/ai-route-proxy/.env.analysis`, but `PROMPT_ANALYZER_API_KEY` is not present yet. Until an operator adds that server-side key and restarts `ai-route-proxy-analysis.service`, jobs remain pending and `analyzerEnabled` is false in telemetry.
- Rollback path: start `ai-route-proxy-responses-capture.service`, switch both Nginx site files from `127.0.0.1:3131` back to `127.0.0.1:3129`, then run `nginx -t && systemctl reload nginx`.
- Validation passed: `go test ./...`, `go build`, `npm run build`, production frontend deploy, `nginx -t`, public `/healthz` returns `2026-05-27.6`, public admin telemetry returns storage/analysis fields, and public smoke request creates prompt jobs without waiting for analysis.

## 2026-05-27 CRM Daily Spend And Compact Route Monitor
- `ai-route-proxy` upgraded to version `2026-05-27.7`; admin-only CRM telemetry now includes `crm.dailySpend`, sourced from GPT Parser lookup fields `usage.dailyCost` / `remote.limits.currentDailyCost`.
- MariaDB table `proxy_key_crm_cards` was migrated with `daily_spend_amount`. Existing rows default to `0` until the next CRM refresh; the frontend also performs an admin-only fallback lookup by CRM email when the telemetry daily value is missing or zero.
- Live service is `ai-route-proxy-daily-spend.service` on `127.0.0.1:3132`; Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3132`. The previous `ai-route-proxy-analysis.service` on `3131` remains active for rollback.
- The hidden statistics monitor now shows `today $...` inside CRM sale cards, makes the first two top summary tiles wider, gives the first two route-table columns more room, and allows country/ASN/IP cells to wrap in narrower columns.
- Temporary Nginx backup server files from `sites-enabled` were moved to `/etc/nginx/sites-backups`, removing duplicate `server_name` warnings from `nginx -t`.
- Rollback path: switch both Nginx site files from `127.0.0.1:3132` back to `127.0.0.1:3131`, run `nginx -t && systemctl reload nginx`, then keep or stop the daily-spend service after active streams drain.
- Validation passed: `go test ./...`, `go build`, `npm run build`, production frontend deploy, `nginx -t`, public `/healthz` returns `2026-05-27.7`, public telemetry returns `2026-05-27.7`, and Playwright admin smoke found visible `today` CRM spend rows with widened summary/route grid columns and no page errors.

## 2026-05-27 Route Row Compact Prototype
- Added standalone UX prototype `docs/local/stats-widget-prototypes/proxy-route-row-compact-variants.html` with four compact route-row layout variants for the hidden proxy monitor.
- Deployed the prototype to `https://statistics.gptclaudegemini.xyz/proxy-route-row-compact-variants.html`.
- The prototype uses live prompt-storage observations for the active `152db7` key: `1608` prompt rows and about `37.653 MB` of stored user prompt text at the time of inspection.

## 2026-05-27 Prompt MB And Variant 4 Route Rows
- `ai-route-proxy` upgraded to version `2026-05-27.8`; admin telemetry now adds per-key prompt storage fields: `promptTraceContentMb24h`, `promptTraceContentMb14d`, `promptTraceAvgBytes24h`, and `promptTraceMaxBytes24h`.
- MariaDB table `proxy_prompt_trace_events` now has `prompt_bytes` so telemetry sums prompt size without re-reading `MEDIUMTEXT` on every refresh. Existing rows were backfilled during rollout; new rows write byte size at insert time.
- Live service is `ai-route-proxy-prompt-mb.service` on `127.0.0.1:3133`; Nginx routes for `ai.gptclaudegemini.xyz` and `statistics.gptclaudegemini.xyz/api/proxy/telemetry` now point to `3133`. The previous `ai-route-proxy-daily-spend.service` on `3132` remains active for rollback.
- The hidden statistics monitor now uses the selected Variant 4 row: richer key/model tile, preserved CRM/balance tile, expiry chip in the top-right of the CRM tile, compact route/latency tile, and smaller warning/score tile.
- Updated and redeployed the standalone prototype at `https://statistics.gptclaudegemini.xyz/proxy-route-row-compact-variants.html` so Variant 4 reflects the selected layout.
- Rollback path: switch both Nginx site files from `127.0.0.1:3133` back to `127.0.0.1:3132`, run `nginx -t && systemctl reload nginx`, then keep or stop the prompt-mb service after active streams drain.
- Validation passed: `go test ./...`, `go build`, `npm run build`, public `/healthz` returns `2026-05-27.8`, public telemetry returns `2026-05-27.8`, admin telemetry returns prompt MB fields in about 4s via Nginx, and Playwright found Variant 4 rows with expiry/prompt-MB/warning cards and no page errors.

## 2026-05-27 Prompt Storage Header Card
- Added the compact `Prompt storage сейчас` card to the top of the hidden proxy monitor after admin unlock.
- The card shows the busiest prompt key count, raw text MB for that key, and a total MB fallback across keys in the monitor when the heavier DB-size summary is not returned fast enough.
- The row hint stays aligned with the selected Variant 4 layout: count + MB are shown together and tags remain collapsed for modal/tooltip use.
- Source was updated in `D:\cursor\ccg-stats-mini-frontend`, built with `npm run build`, deployed to `/var/www/statistics.gptclaudegemini.xyz`, and verified with Playwright. Screenshot: `D:\cursor\sub2api-base\output\playwright\proxy-monitor-prompt-storage-header.png`.

## 2026-05-31 AI Route Service Cleanup
- Public Nginx routes still point to the live `ai-route-proxy-prompt-mb.service` on `127.0.0.1:3133`, version `2026-05-27.8`.
- Stopped and disabled old rollback/experiment services: `ai-route-proxy-analysis.service`, `ai-route-proxy-crm-link.service`, `ai-route-proxy-daily-spend.service`, `ai-route-proxy-default-trace.service`, `ai-route-proxy-model-block.service`, and `ai-route-proxy-responses-capture.service`.
- After cleanup, the only enabled/running `ai-route-proxy*.service` is `ai-route-proxy-prompt-mb.service`. The separate `api-claude-router` process on `3130` was not touched.
- Live telemetry confirms prompt analysis is off: `PROMPT_ANALYZER_ENABLED=false`, `analyzerEnabled=false`, queue `0`, raw prompt MB `0`.
