#!/usr/bin/env bash
set -euo pipefail

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

SULU_VERSION="${SULU_VERSION:-$(tf_output_raw sulu_image_tag)}"
SULU_VERSION="${SULU_VERSION:-3.0.0}"
SULU_SOURCE_URL="${SULU_SOURCE_URL:-https://github.com/sulu/sulu/archive/refs/tags/${SULU_VERSION}.tar.gz}"
SULU_CONTEXT="${SULU_CONTEXT:-./docker/sulu}"
SULU_SOURCE_DIR="${SULU_CONTEXT}/source"

download_source() {
  local dest="$1"
  echo "[sulu] Downloading ${SULU_SOURCE_URL}..."
  curl -fL "${SULU_SOURCE_URL}" -o "${dest}"
}

extract_source() {
  local archive="$1" workdir="$2"
  rm -rf "${SULU_SOURCE_DIR}"
  mkdir -p "${workdir}"
  tar -xzf "${archive}" -C "${workdir}"
  local extracted
  extracted="$(find "${workdir}" -maxdepth 1 -mindepth 1 -type d | head -n1)"
  if [ -z "${extracted}" ]; then
    echo "[sulu] Failed to locate extracted directory" >&2
    exit 1
  fi
  mkdir -p "${SULU_SOURCE_DIR}"
  cp -a "${extracted}/." "${SULU_SOURCE_DIR}/"
  rm -rf "${SULU_SOURCE_DIR}/.git" "${SULU_SOURCE_DIR}/.github"
  echo "[sulu] Extracted ${SULU_SOURCE_URL} to ${SULU_SOURCE_DIR}"
}

write_dockerfile() {
  mkdir -p "${SULU_CONTEXT}"
  cat >"${SULU_CONTEXT}/Dockerfile" <<EOF
ARG SULU_VERSION=${SULU_VERSION}
ARG PHP_IMAGE=php:8.2-fpm
ARG PHP_CLI_IMAGE=php:8.2-cli
ARG COMMON_PACKAGES="ca-certificates git curl unzip zip libpq-dev libzip-dev libicu-dev libonig-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev gnupg libvips-dev libffi-dev pkg-config build-essential autoconf"
ARG NODE_SETUP_SCRIPT=https://deb.nodesource.com/setup_20.x

FROM \${PHP_CLI_IMAGE} AS composer
ARG COMMON_PACKAGES
ARG NODE_SETUP_SCRIPT
RUN set -eux; \
    mkdir -p /etc/apt; \
    codename="\$(. /etc/os-release && echo \"\${VERSION_CODENAME:-bookworm}\")"; \
    if [ ! -f /etc/apt/sources.list ]; then \
      echo "deb https://deb.debian.org/debian \${codename} main" > /etc/apt/sources.list; \
      echo "deb https://deb.debian.org/debian \${codename}-updates main" >> /etc/apt/sources.list; \
      echo "deb https://security.debian.org/debian-security \${codename}-security main" >> /etc/apt/sources.list; \
    else \
      sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list; \
      sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \${COMMON_PACKAGES}; \
    curl -fsSL \${NODE_SETUP_SCRIPT} | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    npm install -g yarn@1.22.19; \
    curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    printf "\\n" | pecl install vips; \
    docker-php-ext-enable vips; \
    docker-php-ext-configure ffi --with-ffi; \
    docker-php-ext-configure intl; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install intl gd pdo pdo_pgsql zip ffi; \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY source/ /app/
COPY init-db.sh /app/docker/init-db.sh
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --no-interaction --prefer-dist --classmap-authoritative --no-progress

FROM \${PHP_IMAGE} AS runtime
ARG SULU_VERSION
ARG COMMON_PACKAGES
ARG NODE_SETUP_SCRIPT
RUN set -eux; \
    mkdir -p /etc/apt; \
    codename="\$(. /etc/os-release && echo \"\${VERSION_CODENAME:-bookworm}\")"; \
    if [ ! -f /etc/apt/sources.list ]; then \
      echo "deb https://deb.debian.org/debian \${codename} main" > /etc/apt/sources.list; \
      echo "deb https://deb.debian.org/debian \${codename}-updates main" >> /etc/apt/sources.list; \
      echo "deb https://security.debian.org/debian-security \${codename}-security main" >> /etc/apt/sources.list; \
    else \
      sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list; \
      sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \${COMMON_PACKAGES}; \
    curl -fsSL \${NODE_SETUP_SCRIPT} | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    npm install -g yarn@1.22.19; \
    printf "\\n" | pecl install vips; \
    docker-php-ext-enable vips; \
    docker-php-ext-configure ffi --with-ffi; \
    docker-php-ext-configure intl; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install intl gd pdo pdo_pgsql zip ffi; \
    rm -rf /var/lib/apt/lists/*
WORKDIR /var/www/html
COPY --from=composer /app /var/www/html
COPY --chown=www-data:www-data config/ config/
COPY --chown=www-data:www-data hooks/ hooks/
RUN set -eux; \
    chown -R www-data:www-data /var/www/html
RUN chmod +x /var/www/html/hooks/onready/*.sh
RUN chmod +x /var/www/html/docker/init-db.sh
LABEL org.opencontainers.image.title="Sulu PHP" \
      org.opencontainers.image.version="${SULU_VERSION}" \
      org.opencontainers.image.vendor="aiops-custom-agent" \
      org.opencontainers.image.source="https://github.com/sulu/sulu"
USER www-data
EOF
  echo "[sulu] Wrote Dockerfile (${SULU_VERSION})"
}

main() {
  local archive workdir
  archive="$(mktemp)"
  workdir="$(mktemp -d)"
  trap 'rm -rf "${archive:-}" "${workdir:-}"' EXIT

  download_source "${archive}"
  extract_source "${archive}" "${workdir}"
  write_dockerfile
}

main "$@"
