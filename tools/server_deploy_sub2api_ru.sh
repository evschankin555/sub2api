#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="/tmp/sub2api-build-20260529"
ARCHIVE="/root/sub2api-build-20260529.tgz"
IMAGE="sub2api-local:ru-antigravity-20260529"
COMPOSE="/opt/sub2api/docker-compose.local.yml"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
tar -xzf "${ARCHIVE}" -C "${BUILD_DIR}"

cd "${BUILD_DIR}"
docker build -t "${IMAGE}" -f Dockerfile .

cp "${COMPOSE}" "${COMPOSE}.bak-$(date +%Y%m%d-%H%M%S)-pre-ru-commit"
sed -i "s|image: sub2api-local:ru-antigravity-20260513-r2|image: ${IMAGE}|" "${COMPOSE}"

cd /opt/sub2api
docker compose -f docker-compose.local.yml up -d sub2api
sleep 5
docker compose -f docker-compose.local.yml ps sub2api
curl -fsS http://127.0.0.1:8080/health
echo
curl -fsS https://d.gptclaudegemini.xyz/health
echo
