#!/usr/bin/env bash
set -euo pipefail

echo "[nimletter] Stopping containers..."
docker rm -f nimletter nimletter-postgres >/dev/null 2>&1 || true

echo "[nimletter] Removing network if unused..."
if docker network ls --format '{{.Name}}' | grep -q '^nimletter-net$'; then
  # Only remove if no containers are attached
  if [ -z "$(docker network inspect nimletter-net -f '{{range .Containers}}{{.Name}} {{end}}')" ]; then
    docker network rm nimletter-net >/dev/null 2>&1 || true
    echo "[nimletter] Removed network nimletter-net"
  fi
fi

echo "[nimletter] Done. To remove data, delete ./data/postgres"

