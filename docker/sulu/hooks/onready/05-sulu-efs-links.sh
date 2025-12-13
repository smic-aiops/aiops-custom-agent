#!/usr/bin/env bash
set -euo pipefail

MOUNT_DIR="/efs"
MEDIA_TARGET="/var/www/html/public/uploads/media"
LOUPE_TARGET="/var/www/html/var/indexes"

mkdir -p "${MOUNT_DIR}"/{media,loupe,locks}
mkdir -p "${MEDIA_TARGET}"
mkdir -p "${LOUPE_TARGET}"
chown -R www-data:www-data "${MOUNT_DIR}" "${MEDIA_TARGET}" "${LOUPE_TARGET}"
