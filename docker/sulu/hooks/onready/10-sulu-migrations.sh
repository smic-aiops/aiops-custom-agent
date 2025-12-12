#!/usr/bin/env bash
set -euo pipefail

# Composer may still be bootstrapping the project on first run, so wait briefly for bin/console.
cd /var/www/html
max_wait=120
elapsed=0
while [ ! -f bin/console ] && [ "${elapsed}" -lt "${max_wait}" ]; do
  sleep 1
  elapsed=$((elapsed + 1))
done

if [ ! -f bin/console ]; then
  echo "[sulu] bin/console is missing after ${max_wait}s; skipping migrations."
  exit 0
fi

if [ -z "${DATABASE_URL:-}" ]; then
  echo "[sulu] DATABASE_URL is missing; skipping migrations."
  exit 0
fi

# Ensure the database exists before running migrations.
php bin/console doctrine:database:create --if-not-exists --no-interaction || true
php bin/console doctrine:migrations:migrate --no-interaction
php bin/console sulu:document:init --no-interaction || true
