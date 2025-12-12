locals {
  zulip_error_log_shipper_snippet = <<-EOT
    set -euo pipefail

    log_file="/var/log/zulip/errors.log"
    log_dir="$(dirname "$${log_file}")"
    mkdir -p "$${log_dir}"
    chown zulip:zulip "$${log_dir}"
    touch "$${log_file}"
    chown zulip:zulip "$${log_file}"

    tail -n0 -F "$${log_file}" &
    tail_pid=$$!

    cleanup() {
      kill "$${tail_pid}" >/dev/null 2>&1 || true
    }

    trap cleanup EXIT
  EOT

  zulip_missing_dictionaries_snippet = <<-EOT
    crudini --set /etc/zulip/zulip.conf postgresql missing_dictionaries true
  EOT

  zulip_oidc_idps_patch_snippet = <<-EOT
    oidc_idps_var="$${SETTING_SOCIAL_AUTH_OIDC_ENABLED_IDPS:-}"
    if [ -z "$${oidc_idps_var:-}" ] && [ -n "$${OIDC_IDPS:-}" ]; then
      oidc_idps_var="$${OIDC_IDPS}"
    fi
    if [ -n "$${oidc_idps_var:-}" ] && command -v python3 >/dev/null 2>&1; then
      patched="$(
        python3 - <<'PY' || exit 0
import os
import sys
import json

try:
    import yaml
except Exception:
    sys.exit(0)

oidc_idps = os.environ.get("SETTING_SOCIAL_AUTH_OIDC_ENABLED_IDPS") or os.environ.get("OIDC_IDPS")
client_id = os.environ.get("OIDC_CLIENT_ID") or None
secret = os.environ.get("OIDC_CLIENT_SECRET") or None
if not oidc_idps or not secret:
    sys.exit(0)

data = yaml.safe_load(oidc_idps) or {}
changed = False
if isinstance(data, dict):
    for name, cfg in data.items():
        if not isinstance(cfg, dict):
            continue
        if not cfg.get("client_id") and client_id:
            cfg["client_id"] = client_id
            changed = True
        secret_val = cfg.get("secret")
        if secret_val in (None, "", "null") and secret:
            cfg["secret"] = secret
            changed = True

if changed:
    print(json.dumps(data))
else:
    print(json.dumps(data))
PY
      )"
      if [ -n "$${patched}" ]; then
        export SETTING_SOCIAL_AUTH_OIDC_ENABLED_IDPS="$${patched}"
      fi
    fi
  EOT

  zulip_trusted_proxy_cidrs_input  = coalesce(var.zulip_trusted_proxy_cidrs, [])
  zulip_trusted_proxy_cidrs        = length(local.zulip_trusted_proxy_cidrs_input) > 0 ? local.zulip_trusted_proxy_cidrs_input : [for s in local.public_subnets : s.cidr]
  zulip_loadbalancer_ips           = join(",", local.zulip_trusted_proxy_cidrs)
  zulip_trust_proxies_snippet      = <<-EOT
    crudini --set /etc/zulip/zulip.conf loadbalancer ips "${local.zulip_loadbalancer_ips}"
  EOT
  zulip_social_auth_secret_snippet = <<-EOT
    if [ -n "$${OIDC_CLIENT_SECRET:-}" ]; then
      secrets_file="/etc/zulip/zulip-secrets.conf"
      touch "$${secrets_file}"
      chown zulip:zulip "$${secrets_file}"
      chmod 640 "$${secrets_file}"
      if command -v crudini >/dev/null 2>&1; then
        crudini --set "$${secrets_file}" secrets social_auth_oidc_secret "$${OIDC_CLIENT_SECRET}"
      else
        tmp_file="$${secrets_file}.tmp"
        if [ -f "$${secrets_file}" ]; then
          grep -v '^social_auth_oidc_secret' "$${secrets_file}" >"$${tmp_file}" || true
        else
          : >"$${tmp_file}"
        fi
        if ! grep -q '^\[secrets\]' "$${tmp_file}" >/dev/null 2>&1; then
          printf '[secrets]\n' >>"$${tmp_file}"
        fi
        echo "social_auth_oidc_secret = $${OIDC_CLIENT_SECRET}" >>"$${tmp_file}"
        mv "$${tmp_file}" "$${secrets_file}"
      fi
    fi
  EOT

  zulip_entrypoint_command = join("\n", compact([
    trimspace(local.zulip_error_log_shipper_snippet),
    trimspace(local.zulip_trust_proxies_snippet),
    trimspace(local.zulip_social_auth_secret_snippet),
    trimspace(local.zulip_oidc_idps_patch_snippet),
    var.zulip_missing_dictionaries ? trimspace(local.zulip_missing_dictionaries_snippet) : "",
    "exec /sbin/entrypoint.sh app:run"
  ]))
}

resource "aws_ecs_task_definition" "growi" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  family                   = "${local.name_prefix}-growi"
  cpu                      = coalesce(var.growi_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.growi_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.growi_efs_id != null ? [1] : []
    content {
      name = "growi-data"
      efs_volume_configuration {
        file_system_id     = local.growi_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.growi_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "growi-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.growi_filesystem_path}/uploads"
            chown -R 1000:1000 "${var.growi_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "growi-data"
          containerPath = var.growi_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["growi"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name  = "growi"
        image = local.ecr_uri_growi
        user  = "0:0"
        portMappings = [{
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(local.default_environment_growi, var.growi_environment, local.growi_keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.growi_secrets,
          [for k, v in local.ssm_param_arns_growi : { name = k, valueFrom = v }],
          var.enable_growi_keycloak ? [for k, v in local.ssm_param_arns_growi_oidc : { name = k, valueFrom = v }] : []
        )
        mountPoints = local.growi_efs_id != null ? [{
          sourceVolume  = "growi-data"
          containerPath = var.growi_filesystem_path
          readOnly      = false
        }] : []
        dependsOn = local.growi_efs_id != null ? [
          {
            containerName = "growi-fs-init"
            condition     = "COMPLETE"
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["growi"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-td" })
}

resource "aws_ecs_task_definition" "cmdbuild_r2u" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  family                   = "${local.name_prefix}-cmdbuild-r2u"
  cpu                      = coalesce(var.cmdbuild_r2u_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.cmdbuild_r2u_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.cmdbuild_r2u_efs_id != null ? [1] : []
    content {
      name = "cmdbuild-r2u-data"
      efs_volume_configuration {
        file_system_id     = local.cmdbuild_r2u_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.cmdbuild_r2u_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "cmdbuild-r2u-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.cmdbuild_r2u_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "cmdbuild-r2u-data"
          containerPath = var.cmdbuild_r2u_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["cmdbuild-r2u"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "cmdbuild-r2u-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            apk add --no-cache postgresql15-client >/dev/null

            db_host="$${POSTGRES_HOST:-}"
            db_port="$${POSTGRES_PORT:-5432}"
            db_user="$${POSTGRES_USER:-}"
            db_pass="$${POSTGRES_PASSWORD:-}"
            db_name="$${POSTGRES_DB:-cmdbuild}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            export PGPASSWORD="$${db_pass}"

            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 2
            done

            role_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname = '$${db_user}'" || true)"
            if [ "$${role_exists}" != "1" ]; then
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE ROLE \"$${db_user}\" WITH LOGIN PASSWORD '$${db_pass}';" || true
            fi

            db_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$${db_name}'" || true)"
            if [ "$${db_exists}" != "1" ]; then
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE DATABASE \"$${db_name}\" OWNER \"$${db_user}\";"
            fi
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_cmdbuild_r2u : { name = k, valueFrom = v }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["cmdbuild-r2u"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "cmdbuild-r2u"
        image = local.ecr_uri_cmdbuild_r2u
        portMappings = [{
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }]
        mountPoints = local.cmdbuild_r2u_efs_id != null ? [{
          sourceVolume  = "cmdbuild-r2u-data"
          containerPath = var.cmdbuild_r2u_filesystem_path
          readOnly      = false
        }] : []
        environment = [for k, v in merge(local.default_environment_cmdbuild_r2u, var.cmdbuild_r2u_environment, local.cmdbuild_r2u_keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.cmdbuild_r2u_secrets,
          [for k, v in local.ssm_param_arns_cmdbuild_r2u : { name = k, valueFrom = v }],
          var.enable_cmdbuild_r2u_keycloak ? [for k, v in local.ssm_param_arns_cmdbuild_r2u_oidc : { name = k, valueFrom = v }] : []
        )
        dependsOn = concat(
          local.cmdbuild_r2u_efs_id != null ? [
            {
              containerName = "cmdbuild-r2u-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "cmdbuild-r2u-db-init"
              condition     = "COMPLETE"
            }
          ]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["cmdbuild-r2u"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-td" })
}

resource "aws_ecs_task_definition" "orangehrm" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  family                   = "${local.name_prefix}-orangehrm"
  cpu                      = coalesce(var.orangehrm_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.orangehrm_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.orangehrm_efs_id != null ? [1] : []
    content {
      name = "orangehrm-data"
      efs_volume_configuration {
        file_system_id     = local.orangehrm_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.orangehrm_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "orangehrm-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.orangehrm_filesystem_path}"
            chown -R 1001:1001 "${var.orangehrm_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "orangehrm-data"
          containerPath = var.orangehrm_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["orangehrm"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "orangehrm-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            apk add --no-cache mariadb-client >/dev/null

            db_host="$${MARIADB_HOST:-}"
            db_port="$${MARIADB_PORT_NUMBER:-3306}"
            db_user="$${ORANGEHRM_DATABASE_USER:-}"
            db_pass="$${ORANGEHRM_DATABASE_PASSWORD:-}"
            db_name="$${ORANGEHRM_DATABASE_NAME:-orangehrm}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            until mysqladmin --user="$${db_user}" --password="$${db_pass}" --host="$${db_host}" --port="$${db_port}" ping --silent; do
              sleep 3
            done

            mysql --user="$${db_user}" --password="$${db_pass}" --host="$${db_host}" --port="$${db_port}" -e "CREATE DATABASE IF NOT EXISTS \`$${db_name}\` CHARACTER SET utf8mb4;"
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_orangehrm : { name = k, valueFrom = v }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["orangehrm"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "orangehrm"
        image = local.ecr_uri_orangehrm
        user  = "1001:1001"
        portMappings = [{
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }]
        mountPoints = local.orangehrm_efs_id != null ? [{
          sourceVolume  = "orangehrm-data"
          containerPath = var.orangehrm_filesystem_path
          readOnly      = false
        }] : []
        environment = [for k, v in merge(local.default_environment_orangehrm, var.orangehrm_environment, local.orangehrm_keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.orangehrm_secrets,
          [for k, v in local.ssm_param_arns_orangehrm : { name = k, valueFrom = v }],
          var.enable_orangehrm_keycloak ? [for k, v in local.ssm_param_arns_orangehrm_oidc : { name = k, valueFrom = v }] : []
        )
        dependsOn = concat(
          local.orangehrm_efs_id != null ? [
            {
              containerName = "orangehrm-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "orangehrm-db-init"
              condition     = "COMPLETE"
            }
          ]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["orangehrm"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-td" })
}

resource "aws_ecs_task_definition" "zulip" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  family                   = "${local.name_prefix}-zulip"
  cpu                      = coalesce(var.zulip_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.zulip_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.zulip_efs_id != null ? [1] : []
    content {
      name = "zulip-data"
      efs_volume_configuration {
        file_system_id     = local.zulip_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.zulip_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "zulip-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.zulip_filesystem_path}"
            chown -R 1000:1000 "${var.zulip_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "zulip-data"
          containerPath = var.zulip_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "zulip-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            apk add --no-cache postgresql15-client >/dev/null

            db_host="$${DB_HOST:-}"
            db_port="$${DB_PORT:-5432}"
            db_user="$${DB_USER:-}"
            db_pass="$${DB_PASSWORD:-}"
            db_name="$${DB_NAME:-zulip}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            select_sql="SELECT 1 FROM pg_database WHERE datname = '$${db_name}'"
            create_sql="CREATE DATABASE \"$${db_name}\" OWNER \"$${db_user}\";"
            schema_check_sql="SELECT 1 FROM pg_namespace WHERE nspname = 'zulip';"
            create_schema_sql="CREATE SCHEMA IF NOT EXISTS zulip AUTHORIZATION \"$${db_user}\";"
            set_search_path_sql="ALTER ROLE \"$${db_user}\" SET search_path TO zulip,public;"

            export PGPASSWORD="$${db_pass}"
            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 3
            done

            db_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "$${select_sql}" || true)"
            if [ "$${db_exists}" != "1" ]; then
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "$${create_sql}"
            fi

            schema_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d "$${db_name}" -Atc "$${schema_check_sql}" || true)"
            if [ "$${schema_exists}" != "1" ]; then
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d "$${db_name}" -c "$${create_schema_sql}"
            fi
            psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d "$${db_name}" -c "$${set_search_path_sql}"
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_zulip : { name = k, valueFrom = v }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "zulip-memcached"
        image = "public.ecr.aws/docker/library/memcached:1.6-alpine"
        portMappings = [{
          containerPort = 11211
          hostPort      = 11211
          protocol      = "tcp"
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name    = "zulip-redis"
        image   = "public.ecr.aws/docker/library/redis:7.2-alpine"
        command = ["redis-server", "--save", "", "--appendonly", "no"]
        portMappings = [{
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "zulip-rabbitmq"
        image = "public.ecr.aws/docker/library/rabbitmq:3.13-alpine"
        portMappings = [{
          containerPort = 5672
          hostPort      = 5672
          protocol      = "tcp"
        }]
        environment = [{
          name  = "RABBITMQ_DEFAULT_VHOST"
          value = "/"
        }]
        secrets = concat(
          contains(keys(local.ssm_param_arns_zulip), "RABBITMQ_USERNAME") ? [{
            name      = "RABBITMQ_DEFAULT_USER"
            valueFrom = local.ssm_param_arns_zulip["RABBITMQ_USERNAME"]
          }] : [],
          contains(keys(local.ssm_param_arns_zulip), "RABBITMQ_PASSWORD") ? [{
            name      = "RABBITMQ_DEFAULT_PASS"
            valueFrom = local.ssm_param_arns_zulip["RABBITMQ_PASSWORD"]
          }] : []
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "zulip"
        image = local.ecr_uri_zulip
        portMappings = [{
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(local.default_environment_zulip, local.zulip_keycloak_environment, var.zulip_environment) : { name = k, value = v }]
        secrets = concat(
          var.zulip_secrets,
          [for k, v in local.ssm_param_arns_zulip : { name = k, valueFrom = v }]
        )
        mountPoints = local.zulip_efs_id != null ? [{
          sourceVolume  = "zulip-data"
          containerPath = var.zulip_filesystem_path
          readOnly      = false
        }] : []
        dependsOn = concat(
          local.zulip_efs_id != null ? [
            {
              containerName = "zulip-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "zulip-db-init"
              condition     = "COMPLETE"
            },
            {
              containerName = "zulip-memcached"
              condition     = "START"
            },
            {
              containerName = "zulip-redis"
              condition     = "START"
            },
            {
              containerName = "zulip-rabbitmq"
              condition     = "START"
            }
          ]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
          })
        })
        entryPoint = ["/bin/bash", "-c"]
        command    = [local.zulip_entrypoint_command]
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-td" })
}
