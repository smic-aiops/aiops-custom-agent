#!/usr/bin/env sh
set -eu

LOCK_DIR="/efs/locks"
LOCK_FILE="${LOCK_DIR}/db-init.lock"
SENTINEL="${LOCK_DIR}/db-init.done"

mkdir -p "${LOCK_DIR}" /efs/media /efs/loupe
chown -R www-data:www-data /efs

# Sentinel ensures the init step only runs once per filesystem state.
if [ -f "${SENTINEL}" ]; then
  echo "[init-db] sentinel exists; skipping."
  exit 0
fi

echo "[init-db] waiting for database..."
until php bin/console doctrine:query:sql "SELECT 1" >/dev/null 2>&1; do
  sleep 3
done

exec 9>"${LOCK_FILE}"
flock 9

if [ -f "${SENTINEL}" ]; then
  echo "[init-db] sentinel detected after lock; skipping."
  exit 0
fi

echo "[init-db] running sulu:build prod ..."
php bin/adminconsole sulu:build prod --no-interaction

date -Iseconds > "${SENTINEL}"
echo "[init-db] completed."
