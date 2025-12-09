ARG BASE_IMAGE=weseek/growi:7.3.8
FROM ${BASE_IMAGE}

USER root
COPY plugins/ /opt/growi/apps/app/tmp/plugins/
COPY rds-combined-ca-bundle.pem /etc/ssl/certs/rds-combined-ca-bundle.pem
RUN set -eux;     chown -R 1000:1000 /opt/growi/apps/app/tmp/plugins

ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/rds-combined-ca-bundle.pem
