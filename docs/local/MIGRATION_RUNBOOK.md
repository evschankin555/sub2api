# Sub2API Migration Runbook

## Current Status
- Migration completed on 2026-05-14 MSK.
- Active dashboard: `https://d.gptclaudegemini.xyz`.
- Active API-only host: `https://api.gptclaudegemini.xyz`.
- Root placeholder: `https://gptclaudegemini.xyz`.
- Active server: `srv_141893` / `185.228.72.116`.
- Old server `188.225.11.147` is standby only; its `sub2api` container is stopped while PostgreSQL and Redis remain intact.

## Current Migration Package
- Source server: `188.225.11.147`.
- Package path: `/root/sub2api-migration-20260513`.
- Runtime image: `sub2api-local:ru-antigravity-20260513-r2`.
- New server: `srv_141893` / `185.228.72.116`, Ubuntu 22.04 LTS, 2 vCPU, 2 GB RAM, 40 GB SSD.
- SSH alias on this workstation: `srv_141893` / `sub2api-new` / `gptclaudegemini`.
- Dashboard domain: `d.gptclaudegemini.xyz`.
- API-only domain: `api.gptclaudegemini.xyz`.
- Root domain: `gptclaudegemini.xyz` for a static placeholder.
- App port must stay private: `127.0.0.1:8080`.
- Do not commit or copy package contents into this repository; it contains `.env` and bootstrap credentials.

## Target DNS And Routing
- `A gptclaudegemini.xyz -> 185.228.72.116`: static placeholder only.
- `A d.gptclaudegemini.xyz -> 185.228.72.116`: full Sub2API dashboard/admin UI.
- `A api.gptclaudegemini.xyz -> 185.228.72.116`: gateway endpoints only, no dashboard UI.
- Do not use wildcard DNS for this first deployment.
- Nginx should expose `/health`, `/v1/*`, `/v1beta/*`, `/antigravity/v1/*`, and `/antigravity/v1beta/*` on `api.gptclaudegemini.xyz`; other UI/admin routes should be blocked or return a minimal JSON/404 response.

## New Server Bootstrap
Completed on the new Ubuntu server after DNS for `gptclaudegemini.xyz`, `d.gptclaudegemini.xyz`, and `api.gptclaudegemini.xyz` resolved to `185.228.72.116`:

```bash
apt-get update
apt-get install -y ca-certificates curl gnupg zstd nginx certbot python3-certbot-nginx
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker nginx
```

Transfer the package to the new server:

```bash
scp -r root@188.225.11.147:/root/sub2api-migration-20260513 /root/
chmod 700 /root/sub2api-migration-20260513
cd /root/sub2api-migration-20260513
sha256sum -c SHA256SUMS.txt
```

Restore helper note: the packaged `restore-staging.sh` targets the older `api-new.developing-site.ru` staging name, so the completed production move used the same package contents but restored the app manually and configured the final `gptclaudegemini.xyz` Nginx routes.

Restore the app on the new server for a future re-run only after updating the staging domain inside the helper or restoring manually:

```bash
/root/sub2api-migration-20260513/restore-staging.sh /root/sub2api-migration-20260513
```

## Staging Validation
- `docker compose -f /opt/sub2api/docker-compose.local.yml ps`
- `curl -fsS http://127.0.0.1:8080/health`
- `curl -fsS https://d.gptclaudegemini.xyz/health`
- `curl -fsS https://api.gptclaudegemini.xyz/health`
- Confirm admin login, Russian default locale, Groups, Accounts, Channels, Settings.
- Confirm `Antigravity Default` exists and `Antigravity Sandbox` is disabled.
- Confirm `ss -ltnp | grep ':8080'` shows only `127.0.0.1:8080`.

## Completed Production Routing
- `/var/www/gptclaudegemini.xyz/index.html` serves the neutral Matrix-style placeholder on the root domain.
- `d.gptclaudegemini.xyz` proxies all routes to `http://127.0.0.1:8080`.
- `api.gptclaudegemini.xyz` proxies only gateway routes and `/health`; other routes return JSON 404.
- Certificate `gptclaudegemini.xyz` covers root, `d.`, and `api.` domains and expires on 2026-08-11.
- Final cutover files used: `/root/sub2api-final-cutover-20260514-035108.sql.gz` and `/root/sub2api-final-data-20260514-035108.tar.gz`.

## Production Cutover
- On the old server, freeze writes and create final delta archives:

```bash
cd /opt/sub2api
set -a
. /opt/sub2api/.env
set +a
docker compose -f /opt/sub2api/docker-compose.local.yml stop sub2api
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" sub2api-postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-acl | gzip -9 > /root/sub2api-final-cutover.sql.gz
tar -C /opt/sub2api -czf /root/sub2api-final-data.tar.gz data
chmod 600 /root/sub2api-final-cutover.sql.gz /root/sub2api-final-data.tar.gz
```

- Transfer final delta archives to the new server and restore them:

```bash
set -a
. /opt/sub2api/.env
set +a
docker compose -f /opt/sub2api/docker-compose.local.yml stop sub2api
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" sub2api-postgres dropdb -U "$POSTGRES_USER" --if-exists "$POSTGRES_DB"
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" sub2api-postgres createdb -U "$POSTGRES_USER" "$POSTGRES_DB"
gzip -dc /root/sub2api-final-cutover.sql.gz | docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" sub2api-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
rm -rf /opt/sub2api/data
tar -C /opt/sub2api -xzf /root/sub2api-final-data.tar.gz
docker compose -f /opt/sub2api/docker-compose.local.yml up -d
```

- Treat `d.gptclaudegemini.xyz` as the new dashboard production host and `api.gptclaudegemini.xyz` as the API-only production host.
- Optionally keep `api.developing-site.ru` on the old server during the validation window, or add a temporary redirect later after the new domain is accepted.
- Validate `https://d.gptclaudegemini.xyz/health`, `https://api.gptclaudegemini.xyz/health`, dashboard login on `d.`, API route blocking on `api.`, and private `8080`.
- Keep the old server intact as standby for 24-48 hours; do not delete `/opt/sub2api` or the migration package until the new server is accepted.
