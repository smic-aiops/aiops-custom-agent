ARG SULU_IMAGE=shinsenter/sulu:php8.4
FROM ${SULU_IMAGE}

USER root
COPY config/packages/sulu_security_sso.yaml /var/www/html/config/packages/sulu_security_sso.yaml
COPY hooks/onready/10-sulu-migrations.sh /var/www/html/hooks/onready/10-sulu-migrations.sh
RUN chmod +x /var/www/html/hooks/onready/10-sulu-migrations.sh \
  && mkdir -p /var/www/html/hooks/onready \
  && chown -R www-data:www-data /var/www/html/hooks /var/www/html/config/packages/sulu_security_sso.yaml

# Upstream entrypoint requires root; keep container user as root.
USER root
