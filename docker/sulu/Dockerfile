ARG SULU_VERSION=3.0.0
ARG PHP_IMAGE=php:8.2-fpm
ARG PHP_CLI_IMAGE=php:8.2-cli
ARG COMMON_PACKAGES="ca-certificates git curl unzip zip libpq-dev libzip-dev libicu-dev libonig-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev gnupg libvips-dev libffi-dev pkg-config build-essential autoconf"
ARG NODE_SETUP_SCRIPT=https://deb.nodesource.com/setup_20.x

FROM ${PHP_CLI_IMAGE} AS composer
ARG COMMON_PACKAGES
ARG NODE_SETUP_SCRIPT
RUN set -eux;     mkdir -p /etc/apt;     codename="$(. /etc/os-release && echo \"${VERSION_CODENAME:-bookworm}\")";     if [ ! -f /etc/apt/sources.list ]; then       echo "deb https://deb.debian.org/debian ${codename} main" > /etc/apt/sources.list;       echo "deb https://deb.debian.org/debian ${codename}-updates main" >> /etc/apt/sources.list;       echo "deb https://security.debian.org/debian-security ${codename}-security main" >> /etc/apt/sources.list;     else       sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list;       sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list;     fi;     apt-get update;     apt-get install -y --no-install-recommends ${COMMON_PACKAGES};     curl -fsSL ${NODE_SETUP_SCRIPT} | bash -;     apt-get install -y --no-install-recommends nodejs;     npm install -g yarn@1.22.19;     curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer;     printf "\n" | pecl install vips;     docker-php-ext-enable vips;     docker-php-ext-configure ffi --with-ffi;     docker-php-ext-configure intl;     docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp;     docker-php-ext-install intl gd pdo pdo_pgsql zip ffi;     rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY source/ /app/
COPY init-db.sh /app/docker/init-db.sh
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --no-interaction --prefer-dist --classmap-authoritative --no-progress

FROM ${PHP_IMAGE} AS runtime
ARG SULU_VERSION
ARG COMMON_PACKAGES
ARG NODE_SETUP_SCRIPT
RUN set -eux;     mkdir -p /etc/apt;     codename="$(. /etc/os-release && echo \"${VERSION_CODENAME:-bookworm}\")";     if [ ! -f /etc/apt/sources.list ]; then       echo "deb https://deb.debian.org/debian ${codename} main" > /etc/apt/sources.list;       echo "deb https://deb.debian.org/debian ${codename}-updates main" >> /etc/apt/sources.list;       echo "deb https://security.debian.org/debian-security ${codename}-security main" >> /etc/apt/sources.list;     else       sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list;       sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list;     fi;     apt-get update;     apt-get install -y --no-install-recommends ${COMMON_PACKAGES};     curl -fsSL ${NODE_SETUP_SCRIPT} | bash -;     apt-get install -y --no-install-recommends nodejs;     npm install -g yarn@1.22.19;     printf "\n" | pecl install vips;     docker-php-ext-enable vips;     docker-php-ext-configure ffi --with-ffi;     docker-php-ext-configure intl;     docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp;     docker-php-ext-install intl gd pdo pdo_pgsql zip ffi;     rm -rf /var/lib/apt/lists/*
WORKDIR /var/www/html
COPY --from=composer /app /var/www/html
COPY --chown=www-data:www-data config/ config/
COPY --chown=www-data:www-data hooks/ hooks/
RUN set -eux;     chown -R www-data:www-data /var/www/html
RUN chmod +x /var/www/html/hooks/onready/*.sh
RUN chmod +x /var/www/html/docker/init-db.sh
LABEL org.opencontainers.image.title="Sulu PHP"       org.opencontainers.image.version="3.0.0"       org.opencontainers.image.vendor="aiops-custom-agent"       org.opencontainers.image.source="https://github.com/sulu/sulu"
USER www-data
