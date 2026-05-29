#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/ai-route-proxy/.env.prompt-mb"
SERVICE="ai-route-proxy-prompt-mb.service"
ARCHIVE_DIR="/root/ai-route-proxy-prompt-archive-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

source /opt/ai-route-proxy/telemetry-db.env

mkdir -p "$ARCHIVE_DIR"
chmod 700 "$ARCHIVE_DIR"

TABLES=$(
  docker exec ai-route-proxy-mariadb mariadb \
    -uroot -p"${MARIADB_ROOT_PASSWORD}" \
    -N \
    -e "SELECT table_name FROM information_schema.tables WHERE table_schema='ai_route_proxy' AND (table_name LIKE 'proxy_prompt%' OR table_name LIKE 'proxy_prompt_analysis%') ORDER BY table_name;"
)

echo "Archiving tables to ${ARCHIVE_DIR}:"
for table in ${TABLES}; do
  docker exec ai-route-proxy-mariadb mariadb-dump \
    -uroot -p"${MARIADB_ROOT_PASSWORD}" \
    ai_route_proxy "${table}" | gzip > "${ARCHIVE_DIR}/${table}.sql.gz"
  echo "  archived ${table}"
done

sha256sum "${ARCHIVE_DIR}"/*.sql.gz > "${ARCHIVE_DIR}/SHA256SUMS.txt"

echo "Truncating live prompt tables:"
for table in ${TABLES}; do
  docker exec ai-route-proxy-mariadb mariadb \
    -uroot -p"${MARIADB_ROOT_PASSWORD}" \
    ai_route_proxy \
    -e "TRUNCATE TABLE \`${table}\`;"
  echo "  truncated ${table}"
done

cp -a "${ENV_FILE}" "${ENV_FILE}.bak-disable-prompt-$(date +%Y%m%d-%H%M%S)"

set_kv() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "${ENV_FILE}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${ENV_FILE}"
  else
    echo "${key}=${value}" >> "${ENV_FILE}"
  fi
}

set_kv PROMPT_TRACE_DEFAULT_ENABLED false
set_kv PROMPT_ANALYZER_ENABLED false

echo "Updated env flags:"
grep -E '^PROMPT_TRACE_DEFAULT_ENABLED=|^PROMPT_ANALYZER_ENABLED=' "${ENV_FILE}"

systemctl restart "${SERVICE}"
sleep 2
curl -fsS "http://127.0.0.1:3133/healthz"
echo
echo "Done. Archive: ${ARCHIVE_DIR}"
