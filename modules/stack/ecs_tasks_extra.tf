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
      merge(
        local.ecs_base_container,
        {
          name  = "zulip"
          image = local.ecr_uri_zulip
          portMappings = [{
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
          }]
          environment = [for k, v in merge(local.default_environment_zulip, var.zulip_environment) : { name = k, value = v }]
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
              }
            ]
          )
          logConfiguration = merge(local.ecs_base_container.logConfiguration, {
            options = merge(local.ecs_base_container.logConfiguration.options, {
              "awslogs-group" = aws_cloudwatch_log_group.ecs["zulip"].name
            })
          })
        },
        var.zulip_missing_dictionaries ? {
          entryPoint = ["/bin/bash", "-c"]
          command = [
            <<-EOT
              set -euo pipefail
              crudini --set /etc/zulip/zulip.conf postgresql missing_dictionaries true
              exec /sbin/entrypoint.sh app:run
            EOT
          ]
        } : {}
      )
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-td" })
}
