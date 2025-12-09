ARG BASE_IMAGE=n8nio/n8n:latest
FROM ${BASE_IMAGE}

USER root
RUN set -eux;     if command -v apk >/dev/null 2>&1; then       apk add --no-cache postgresql15-client;     elif command -v apt-get >/dev/null 2>&1; then       apt-get update;       DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql-client;       rm -rf /var/lib/apt/lists/*;     elif command -v yum >/dev/null 2>&1; then       yum install -y postgresql;       yum clean all;     else       echo "No supported package manager found to install psql" >&2;       exit 1;     fi

# Drop privileges back to the n8n user
USER 1000:1000
