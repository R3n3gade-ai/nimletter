#!/usr/bin/env bash
set -euo pipefail

# Simple local runner for Nimletter using Docker
# Usage: ./scripts/local-up.sh [PORT]
# Env overrides:
#   NIMLETTER_PORT (default 5555)
#   POSTGRES_PORT (default 5432)

NIMLETTER_PORT=${1:-${NIMLETTER_PORT:-5555}}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

echo "[nimletter] Bringing up Postgres and app..."

# Create an isolated network
if ! docker network ls --format '{{.Name}}' | grep -q '^nimletter-net$'; then
  docker network create nimletter-net >/dev/null
  echo "[nimletter] Created docker network: nimletter-net"
fi

# Start Postgres with a local volume
if ! docker ps -a --format '{{.Names}}' | grep -q '^nimletter-postgres$'; then
  docker run -d \
    --name nimletter-postgres \
    --network nimletter-net \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=nimletter_db \
    -v "$(pwd)/data/postgres:/var/lib/postgresql/data" \
    -p ${POSTGRES_PORT}:5432 \
    postgres:17-alpine >/dev/null
  echo "[nimletter] Started postgres on port ${POSTGRES_PORT}"
else
  if ! docker ps --format '{{.Names}}' | grep -q '^nimletter-postgres$'; then
    docker start nimletter-postgres >/dev/null
    echo "[nimletter] Started existing postgres container"
  else
    echo "[nimletter] Postgres already running"
  fi
fi

echo "[nimletter] Waiting for Postgres to be ready..."
tries=0
until docker exec nimletter-postgres pg_isready -U postgres >/dev/null 2>&1; do
  tries=$((tries+1))
  if [ $tries -gt 60 ]; then
    echo "[nimletter] Postgres failed to become ready"
    docker logs --tail 100 nimletter-postgres || true
    exit 1
  fi
  sleep 1
done

# Start Nimletter (override image default CMD; run the binary directly)
if docker ps -a --format '{{.Names}}' | grep -q '^nimletter$'; then
  # Remove to ensure clean start with correct command
  docker rm -f nimletter >/dev/null 2>&1 || true
fi

docker run -d \
  --name nimletter \
  --network nimletter-net \
  -e PG_HOST=nimletter-postgres:5432 \
  -e PG_USER=postgres \
  -e PG_PASSWORD=postgres \
  -e PG_DATABASE=nimletter_db \
  -e PG_WORKERS=3 \
  -e LISTEN_PORT=5555 \
  -e LISTEN_IP=0.0.0.0 \
  -e ADMIN_EMAIL=admin@nimletter.com \
  -e ADMIN_PASSWORD=dripit \
  -p ${NIMLETTER_PORT}:5555 \
  ghcr.io/thomastjdev/nimletter:latest /home/nimmer/nimletter >/dev/null

echo "[nimletter] Started app on http://localhost:${NIMLETTER_PORT}"

echo "[nimletter] Probing health..."
for i in {1..20}; do
  if curl -sf "http://localhost:${NIMLETTER_PORT}/" >/dev/null; then
    echo "[nimletter] OK: http://localhost:${NIMLETTER_PORT}"
    echo "[nimletter] Login: admin@nimletter.com / dripit"
    exit 0
  fi
  sleep 1
done

echo "[nimletter] App did not respond yet. Recent logs:"
docker logs --tail 120 nimletter || true
exit 1

