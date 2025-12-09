locals {
  ssm_writes_enabled                             = var.create_ssm_parameters
  db_username_parameter_name                     = coalesce(var.db_username_parameter_name, "/${local.name_prefix}/db/username")
  db_password_parameter_name                     = coalesce(var.db_password_parameter_name, "/${local.name_prefix}/db/password")
  db_host_parameter_name                         = "/${local.name_prefix}/db/host"
  db_port_parameter_name                         = "/${local.name_prefix}/db/port"
  db_name_parameter_name                         = "/${local.name_prefix}/db/name"
  n8n_encryption_key_parameter_name              = "/${local.name_prefix}/n8n/encryption_key"
  zulip_datasource_parameter_name                = "/${local.name_prefix}/zulip/datasource"
  n8n_db_username_parameter_name                 = "/${local.name_prefix}/n8n/db/username"
  n8n_db_password_parameter_name                 = "/${local.name_prefix}/n8n/db/password"
  n8n_db_name_parameter_name                     = "/${local.name_prefix}/n8n/db/name"
  n8n_oidc_client_id_parameter_name              = "/${local.name_prefix}/n8n/oidc/client_id"
  n8n_oidc_client_secret_parameter_name          = "/${local.name_prefix}/n8n/oidc/client_secret"
  zulip_db_username_parameter_name               = "/${local.name_prefix}/zulip/db/username"
  zulip_db_password_parameter_name               = "/${local.name_prefix}/zulip/db/password"
  zulip_db_name_parameter_name                   = "/${local.name_prefix}/zulip/db/name"
  zulip_secret_key_parameter_name                = "/${local.name_prefix}/zulip/secret_key"
  zulip_mq_username_parameter_name               = "/${local.name_prefix}/zulip/rabbitmq/username"
  zulip_mq_password_parameter_name               = "/${local.name_prefix}/zulip/rabbitmq/password"
  zulip_mq_host_parameter_name                   = "/${local.name_prefix}/zulip/rabbitmq/host"
  zulip_mq_endpoint_parameter_name               = "/${local.name_prefix}/zulip/rabbitmq/amqp_endpoint"
  zulip_mq_port_parameter_name                   = "/${local.name_prefix}/zulip/rabbitmq/port"
  zulip_redis_host_parameter_name                = "/${local.name_prefix}/zulip/redis/host"
  zulip_redis_port_parameter_name                = "/${local.name_prefix}/zulip/redis/port"
  zulip_memcached_endpoint_parameter_name        = "/${local.name_prefix}/zulip/memcached/endpoint"
  zulip_oidc_client_id_parameter_name            = "/${local.name_prefix}/zulip/oidc/client_id"
  zulip_oidc_client_secret_parameter_name        = "/${local.name_prefix}/zulip/oidc/client_secret"
  zulip_oidc_idps_parameter_name                 = "/${local.name_prefix}/zulip/oidc/idps"
  keycloak_db_username_parameter_name            = "/${local.name_prefix}/keycloak/db/username"
  keycloak_db_password_parameter_name            = "/${local.name_prefix}/keycloak/db/password"
  keycloak_db_name_parameter_name                = "/${local.name_prefix}/keycloak/db/name"
  keycloak_db_host_parameter_name                = "/${local.name_prefix}/keycloak/db/host"
  keycloak_db_port_parameter_name                = "/${local.name_prefix}/keycloak/db/port"
  keycloak_db_url_parameter_name                 = "/${local.name_prefix}/keycloak/db/url"
  keycloak_admin_username_parameter_name         = "/${local.name_prefix}/keycloak/admin/username"
  keycloak_admin_password_parameter_name         = "/${local.name_prefix}/keycloak/admin/password"
  odoo_db_username_parameter_name                = "/${local.name_prefix}/odoo/db/username"
  odoo_db_password_parameter_name                = "/${local.name_prefix}/odoo/db/password"
  odoo_db_name_parameter_name                    = "/${local.name_prefix}/odoo/db/name"
  odoo_admin_password_parameter_name             = "/${local.name_prefix}/odoo/admin/password"
  gitlab_db_username_parameter_name              = "/${local.name_prefix}/gitlab/db/username"
  gitlab_db_password_parameter_name              = "/${local.name_prefix}/gitlab/db/password"
  gitlab_db_name_parameter_name                  = "/${local.name_prefix}/gitlab/db/name"
  gitlab_db_host_parameter_name                  = "/${local.name_prefix}/gitlab/db/host"
  gitlab_db_port_parameter_name                  = "/${local.name_prefix}/gitlab/db/port"
  exastro_pf_db_username_parameter_name          = "/${local.name_prefix}/exastro-pf/db/username"
  exastro_pf_db_password_parameter_name          = "/${local.name_prefix}/exastro-pf/db/password"
  exastro_pf_db_name_parameter_name              = "/${local.name_prefix}/exastro-pf/db/name"
  exastro_ita_db_username_parameter_name         = "/${local.name_prefix}/exastro-ita/db/username"
  exastro_ita_db_password_parameter_name         = "/${local.name_prefix}/exastro-ita/db/password"
  exastro_ita_db_name_parameter_name             = "/${local.name_prefix}/exastro-ita/db/name"
  exastro_web_oidc_client_id_parameter_name      = "/${local.name_prefix}/exastro-web/oidc/client_id"
  exastro_web_oidc_client_secret_parameter_name  = "/${local.name_prefix}/exastro-web/oidc/client_secret"
  exastro_api_oidc_client_id_parameter_name      = "/${local.name_prefix}/exastro-api/oidc/client_id"
  exastro_api_oidc_client_secret_parameter_name  = "/${local.name_prefix}/exastro-api/oidc/client_secret"
  oase_db_username_parameter_name                = "/${local.name_prefix}/oase/db/username"
  oase_db_password_parameter_name                = "/${local.name_prefix}/oase/db/password"
  oase_db_name_parameter_name                    = "/${local.name_prefix}/oase/db/name"
  pgadmin_default_password_parameter_name        = "/${local.name_prefix}/pgadmin/default_password"
  phpmyadmin_blowfish_secret_parameter_name      = "/${local.name_prefix}/phpmyadmin/blowfish_secret"
  growi_db_username_parameter_name               = "/${local.name_prefix}/growi/db/username"
  growi_db_password_parameter_name               = "/${local.name_prefix}/growi/db/password"
  growi_db_name_parameter_name                   = "/${local.name_prefix}/growi/db/name"
  growi_db_host_parameter_name                   = "/${local.name_prefix}/growi/db/host"
  growi_db_port_parameter_name                   = "/${local.name_prefix}/growi/db/port"
  growi_mongo_uri_parameter_name                 = "/${local.name_prefix}/growi/db/mongo_uri"
  growi_oidc_client_id_parameter_name            = "/${local.name_prefix}/growi/oidc/client_id"
  growi_oidc_client_secret_parameter_name        = "/${local.name_prefix}/growi/oidc/client_secret"
  cmdbuild_r2u_db_username_parameter_name        = "/${local.name_prefix}/cmdbuild-r2u/db/username"
  cmdbuild_r2u_db_password_parameter_name        = "/${local.name_prefix}/cmdbuild-r2u/db/password"
  cmdbuild_r2u_db_name_parameter_name            = "/${local.name_prefix}/cmdbuild-r2u/db/name"
  cmdbuild_r2u_db_host_parameter_name            = "/${local.name_prefix}/cmdbuild-r2u/db/host"
  cmdbuild_r2u_db_port_parameter_name            = "/${local.name_prefix}/cmdbuild-r2u/db/port"
  cmdbuild_r2u_oidc_client_id_parameter_name     = "/${local.name_prefix}/cmdbuild-r2u/oidc/client_id"
  cmdbuild_r2u_oidc_client_secret_parameter_name = "/${local.name_prefix}/cmdbuild-r2u/oidc/client_secret"
  mysql_db_username_parameter_name               = "/${local.name_prefix}/mysql/db/username"
  mysql_db_password_parameter_name               = "/${local.name_prefix}/mysql/db/password"
  mysql_db_name_parameter_name                   = "/${local.name_prefix}/mysql/db/name"
  mysql_db_host_parameter_name                   = "/${local.name_prefix}/mysql/db/host"
  mysql_db_port_parameter_name                   = "/${local.name_prefix}/mysql/db/port"
  orangehrm_admin_username_parameter_name        = "/${local.name_prefix}/orangehrm/admin/username"
  orangehrm_admin_password_parameter_name        = "/${local.name_prefix}/orangehrm/admin/password"
  orangehrm_oidc_client_id_parameter_name        = "/${local.name_prefix}/orangehrm/oidc/client_id"
  orangehrm_oidc_client_secret_parameter_name    = "/${local.name_prefix}/orangehrm/oidc/client_secret"
  odoo_oidc_client_id_parameter_name             = "/${local.name_prefix}/odoo/oidc/client_id"
  odoo_oidc_client_secret_parameter_name         = "/${local.name_prefix}/odoo/oidc/client_secret"
  gitlab_oidc_client_id_parameter_name           = "/${local.name_prefix}/gitlab/oidc/client_id"
  gitlab_oidc_client_secret_parameter_name       = "/${local.name_prefix}/gitlab/oidc/client_secret"
  pgadmin_oidc_client_id_parameter_name          = "/${local.name_prefix}/pgadmin/oidc/client_id"
  pgadmin_oidc_client_secret_parameter_name      = "/${local.name_prefix}/pgadmin/oidc/client_secret"
  n8n_db_password_effective                      = local.db_password_effective
  zulip_db_password_effective                    = local.db_password_effective
  keycloak_db_password_effective                 = local.db_password_effective
  odoo_db_password_effective                     = local.db_password_effective
  gitlab_db_password_effective                   = local.db_password_effective
  oase_db_username_value                         = coalesce(var.oase_db_username, local.master_username)
  oase_db_password_value                         = coalesce(var.oase_db_password, local.db_password_effective)
  oase_db_name_value                             = var.oase_db_name
  exastro_pf_db_username_value                   = coalesce(var.exastro_pf_db_username, local.master_username)
  exastro_pf_db_password_value                   = coalesce(var.exastro_pf_db_password, local.db_password_effective)
  exastro_pf_db_name_value                       = var.exastro_pf_db_name
  exastro_ita_db_username_value                  = coalesce(var.exastro_ita_db_username, local.master_username)
  exastro_ita_db_password_value                  = coalesce(var.exastro_ita_db_password, local.db_password_effective)
  exastro_ita_db_name_value                      = var.exastro_ita_db_name
  growi_db_username_value                        = var.growi_db_username
  growi_db_password_value                        = var.growi_db_password != null ? var.growi_db_password : (local.ssm_writes_enabled ? try(random_password.growi_db[0].result, null) : null)
  growi_db_name_value                            = var.growi_db_name
  cmdbuild_r2u_db_username_value                 = coalesce(var.cmdbuild_r2u_db_username, local.master_username)
  cmdbuild_r2u_db_password_value                 = coalesce(var.cmdbuild_r2u_db_password, local.db_password_effective)
  cmdbuild_r2u_db_name_value                     = var.cmdbuild_r2u_db_name
  mysql_db_username_value                        = coalesce(var.mysql_db_username, var.orangehrm_db_username)
  mysql_db_password_value                        = var.mysql_db_password != null ? var.mysql_db_password : (var.orangehrm_db_password != null ? var.orangehrm_db_password : (local.ssm_writes_enabled ? try(random_password.mysql_db[0].result, null) : null))
  mysql_db_name_value                            = coalesce(var.mysql_db_name, var.orangehrm_db_name)
  orangehrm_db_username_value                    = local.mysql_db_username_value
  orangehrm_db_password_value                    = local.mysql_db_password_value
  orangehrm_db_name_value                        = local.mysql_db_name_value
  orangehrm_admin_username_value                 = var.orangehrm_admin_username
  orangehrm_admin_password_value                 = var.orangehrm_admin_password != null ? var.orangehrm_admin_password : (var.create_orangehrm && local.ssm_writes_enabled ? try(random_password.orangehrm_admin[0].result, null) : null)
  n8n_smtp_username_parameter_name               = "/${local.name_prefix}/n8n/smtp/username"
  n8n_smtp_password_parameter_name               = "/${local.name_prefix}/n8n/smtp/password"
  zulip_smtp_username_parameter_name             = "/${local.name_prefix}/zulip/smtp/username"
  zulip_smtp_password_parameter_name             = "/${local.name_prefix}/zulip/smtp/password"
  keycloak_smtp_username_parameter_name          = "/${local.name_prefix}/keycloak/smtp/username"
  keycloak_smtp_password_parameter_name          = "/${local.name_prefix}/keycloak/smtp/password"
  odoo_smtp_username_parameter_name              = "/${local.name_prefix}/odoo/smtp/username"
  odoo_smtp_password_parameter_name              = "/${local.name_prefix}/odoo/smtp/password"
  gitlab_smtp_username_parameter_name            = "/${local.name_prefix}/gitlab/smtp/username"
  gitlab_smtp_password_parameter_name            = "/${local.name_prefix}/gitlab/smtp/password"
  exastro_web_smtp_username_parameter_name       = "/${local.name_prefix}/exastro-web/smtp/username"
  exastro_web_smtp_password_parameter_name       = "/${local.name_prefix}/exastro-web/smtp/password"
  exastro_api_smtp_username_parameter_name       = "/${local.name_prefix}/exastro-api/smtp/username"
  exastro_api_smtp_password_parameter_name       = "/${local.name_prefix}/exastro-api/smtp/password"
  pgadmin_smtp_username_parameter_name           = "/${local.name_prefix}/pgadmin/smtp/username"
  pgadmin_smtp_password_parameter_name           = "/${local.name_prefix}/pgadmin/smtp/password"
  growi_smtp_username_parameter_name             = "/${local.name_prefix}/growi/smtp/username"
  growi_smtp_password_parameter_name             = "/${local.name_prefix}/growi/smtp/password"
  cmdbuild_smtp_username_parameter_name          = "/${local.name_prefix}/cmdbuild-r2u/smtp/username"
  cmdbuild_smtp_password_parameter_name          = "/${local.name_prefix}/cmdbuild-r2u/smtp/password"
  orangehrm_smtp_username_parameter_name         = "/${local.name_prefix}/orangehrm/smtp/username"
  orangehrm_smtp_password_parameter_name         = "/${local.name_prefix}/orangehrm/smtp/password"
}

data "aws_ssm_parameters_by_path" "existing_keycloak_admin" {
  count           = var.create_keycloak ? 1 : 0
  path            = "/${local.name_prefix}/keycloak/admin"
  with_decryption = true
}

locals {
  ses_smtp_username_value               = var.enable_ses_smtp_auto ? try(aws_iam_access_key.ses_smtp[0].id, null) : null
  ses_smtp_password_value               = var.enable_ses_smtp_auto ? try(aws_iam_access_key.ses_smtp[0].ses_smtp_password_v4, null) : null
  n8n_smtp_username_value               = coalesce(var.n8n_smtp_username, local.ses_smtp_username_value)
  n8n_smtp_password_value               = coalesce(var.n8n_smtp_password, local.ses_smtp_password_value)
  zulip_smtp_username_value             = coalesce(var.zulip_smtp_username, local.ses_smtp_username_value)
  zulip_smtp_password_value             = coalesce(var.zulip_smtp_password, local.ses_smtp_password_value)
  zulip_secret_key_value                = var.zulip_secret_key != null ? var.zulip_secret_key : (local.ssm_writes_enabled ? try(random_password.zulip_secret_key[0].result, null) : null)
  zulip_mq_username_value               = var.zulip_mq_username
  zulip_mq_password_value               = local.zulip_mq_password_effective
  zulip_oidc_client_id_value            = try(coalesce(var.zulip_oidc_client_id, try(local.keycloak_managed_clients["zulip"].client_id, null)), null)
  zulip_oidc_client_secret_value        = try(coalesce(var.zulip_oidc_client_secret, try(local.keycloak_managed_clients["zulip"].client_secret, null)), null)
  n8n_oidc_client_id_value              = try(coalesce(var.n8n_oidc_client_id, try(local.keycloak_managed_clients["n8n"].client_id, null)), null)
  n8n_oidc_client_secret_value          = try(coalesce(var.n8n_oidc_client_secret, try(local.keycloak_managed_clients["n8n"].client_secret, null)), null)
  exastro_web_oidc_client_id_value      = try(coalesce(var.exastro_web_oidc_client_id, try(local.keycloak_managed_clients["exastro-web"].client_id, null)), null)
  exastro_web_oidc_client_secret_value  = try(coalesce(var.exastro_web_oidc_client_secret, try(local.keycloak_managed_clients["exastro-web"].client_secret, null)), null)
  exastro_api_oidc_client_id_value      = try(coalesce(var.exastro_api_oidc_client_id, try(local.keycloak_managed_clients["exastro-api"].client_id, null)), null)
  exastro_api_oidc_client_secret_value  = try(coalesce(var.exastro_api_oidc_client_secret, try(local.keycloak_managed_clients["exastro-api"].client_secret, null)), null)
  growi_oidc_client_id_value            = try(coalesce(var.growi_oidc_client_id, try(local.keycloak_managed_clients["growi"].client_id, null)), null)
  growi_oidc_client_secret_value        = try(coalesce(var.growi_oidc_client_secret, try(local.keycloak_managed_clients["growi"].client_secret, null)), null)
  cmdbuild_r2u_oidc_client_id_value     = try(coalesce(var.cmdbuild_r2u_oidc_client_id, try(local.keycloak_managed_clients["cmdbuild-r2u"].client_id, null)), null)
  cmdbuild_r2u_oidc_client_secret_value = try(coalesce(var.cmdbuild_r2u_oidc_client_secret, try(local.keycloak_managed_clients["cmdbuild-r2u"].client_secret, null)), null)
  orangehrm_oidc_client_id_value        = try(coalesce(var.orangehrm_oidc_client_id, try(local.keycloak_managed_clients["orangehrm"].client_id, null)), null)
  orangehrm_oidc_client_secret_value    = try(coalesce(var.orangehrm_oidc_client_secret, try(local.keycloak_managed_clients["orangehrm"].client_secret, null)), null)
  odoo_oidc_client_id_value             = var.enable_odoo_keycloak ? try(coalesce(var.odoo_oidc_client_id, try(local.keycloak_managed_clients["odoo"].client_id, null)), null) : null
  odoo_oidc_client_secret_value         = var.enable_odoo_keycloak ? try(coalesce(var.odoo_oidc_client_secret, try(local.keycloak_managed_clients["odoo"].client_secret, null)), null) : null
  gitlab_oidc_client_id_value           = var.enable_gitlab_keycloak ? try(coalesce(var.gitlab_oidc_client_id, try(local.keycloak_managed_clients["gitlab"].client_id, null)), null) : null
  gitlab_oidc_client_secret_value       = var.enable_gitlab_keycloak ? try(coalesce(var.gitlab_oidc_client_secret, try(local.keycloak_managed_clients["gitlab"].client_secret, null)), null) : null
  pgadmin_oidc_client_id_value          = var.enable_pgadmin_keycloak ? try(coalesce(var.pgadmin_oidc_client_id, try(local.keycloak_managed_clients["pgadmin"].client_id, null)), null) : null
  pgadmin_oidc_client_secret_value      = var.enable_pgadmin_keycloak ? try(coalesce(var.pgadmin_oidc_client_secret, try(local.keycloak_managed_clients["pgadmin"].client_secret, null)), null) : null
  keycloak_admin_params_from_ssm = zipmap(
    try(data.aws_ssm_parameters_by_path.existing_keycloak_admin[0].names, []),
    try(data.aws_ssm_parameters_by_path.existing_keycloak_admin[0].values, []),
  )
  zulip_oidc_idps_value = var.enable_zulip_keycloak ? (
    var.zulip_oidc_idps_yaml != null ? var.zulip_oidc_idps_yaml : (
      local.zulip_oidc_client_id_value != null && local.zulip_oidc_client_secret_value != null ? yamlencode({
        keycloak = {
          oidc_url     = "https://keycloak.${local.hosted_zone_name_input}/realms/master"
          display_name = "Keycloak"
          client_id    = local.zulip_oidc_client_id_value
          secret       = local.zulip_oidc_client_secret_value
          api_url      = "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/userinfo"
          extra_params = { scope = "openid email profile" }
        }
      }) : null
    )
  ) : null
  zulip_oidc_idps_write_enabled = local.ssm_writes_enabled && var.create_ecs && var.create_zulip && var.enable_zulip_keycloak && (
    var.zulip_oidc_idps_yaml != null ||
    (var.zulip_oidc_client_id != null && var.zulip_oidc_client_secret != null) ||
    local.manage_keycloak_clients_effective
  )
  n8n_oidc_client_id_write_enabled              = local.ssm_writes_enabled && var.create_ecs && var.create_n8n && var.enable_n8n_keycloak && (var.n8n_oidc_client_id != null || local.manage_keycloak_clients_effective)
  n8n_oidc_client_secret_write_enabled          = local.ssm_writes_enabled && var.create_ecs && var.create_n8n && var.enable_n8n_keycloak && (var.n8n_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  zulip_oidc_client_id_write_enabled            = local.ssm_writes_enabled && var.create_ecs && var.create_zulip && var.enable_zulip_keycloak && (var.zulip_oidc_client_id != null || local.manage_keycloak_clients_effective)
  zulip_oidc_client_secret_write_enabled        = local.ssm_writes_enabled && var.create_ecs && var.create_zulip && var.enable_zulip_keycloak && (var.zulip_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  exastro_web_oidc_client_id_write_enabled      = local.ssm_writes_enabled && var.create_ecs && var.create_exastro_web_server && var.enable_exastro_web_keycloak && (var.exastro_web_oidc_client_id != null || local.manage_keycloak_clients_effective)
  exastro_web_oidc_client_secret_write_enabled  = local.ssm_writes_enabled && var.create_ecs && var.create_exastro_web_server && var.enable_exastro_web_keycloak && (var.exastro_web_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  exastro_api_oidc_client_id_write_enabled      = local.ssm_writes_enabled && var.create_ecs && var.create_exastro_api_admin && var.enable_exastro_api_keycloak && (var.exastro_api_oidc_client_id != null || local.manage_keycloak_clients_effective)
  exastro_api_oidc_client_secret_write_enabled  = local.ssm_writes_enabled && var.create_ecs && var.create_exastro_api_admin && var.enable_exastro_api_keycloak && (var.exastro_api_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  growi_oidc_client_id_write_enabled            = local.ssm_writes_enabled && var.create_ecs && var.create_growi && var.enable_growi_keycloak && (var.growi_oidc_client_id != null || local.manage_keycloak_clients_effective)
  growi_oidc_client_secret_write_enabled        = local.ssm_writes_enabled && var.create_ecs && var.create_growi && var.enable_growi_keycloak && (var.growi_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  cmdbuild_r2u_oidc_client_id_write_enabled     = local.ssm_writes_enabled && var.create_ecs && var.create_cmdbuild_r2u && var.enable_cmdbuild_r2u_keycloak && (var.cmdbuild_r2u_oidc_client_id != null || local.manage_keycloak_clients_effective)
  cmdbuild_r2u_oidc_client_secret_write_enabled = local.ssm_writes_enabled && var.create_ecs && var.create_cmdbuild_r2u && var.enable_cmdbuild_r2u_keycloak && (var.cmdbuild_r2u_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  orangehrm_oidc_client_id_write_enabled        = local.ssm_writes_enabled && var.create_ecs && var.create_orangehrm && var.enable_orangehrm_keycloak && (var.orangehrm_oidc_client_id != null || local.manage_keycloak_clients_effective)
  orangehrm_oidc_client_secret_write_enabled    = local.ssm_writes_enabled && var.create_ecs && var.create_orangehrm && var.enable_orangehrm_keycloak && (var.orangehrm_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  odoo_oidc_client_id_write_enabled             = local.ssm_writes_enabled && var.create_ecs && var.create_odoo && var.enable_odoo_keycloak && (var.odoo_oidc_client_id != null || local.manage_keycloak_clients_effective)
  odoo_oidc_client_secret_write_enabled         = local.ssm_writes_enabled && var.create_ecs && var.create_odoo && var.enable_odoo_keycloak && (var.odoo_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  gitlab_oidc_client_id_write_enabled           = local.ssm_writes_enabled && var.create_ecs && var.create_gitlab && var.enable_gitlab_keycloak && (var.gitlab_oidc_client_id != null || local.manage_keycloak_clients_effective)
  gitlab_oidc_client_secret_write_enabled       = local.ssm_writes_enabled && var.create_ecs && var.create_gitlab && var.enable_gitlab_keycloak && (var.gitlab_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  pgadmin_oidc_client_id_write_enabled          = local.ssm_writes_enabled && var.create_ecs && var.create_pgadmin && var.enable_pgadmin_keycloak && (var.pgadmin_oidc_client_id != null || local.manage_keycloak_clients_effective)
  pgadmin_oidc_client_secret_write_enabled      = local.ssm_writes_enabled && var.create_ecs && var.create_pgadmin && var.enable_pgadmin_keycloak && (var.pgadmin_oidc_client_secret != null || local.manage_keycloak_clients_effective)
  keycloak_smtp_username_value                  = coalesce(var.keycloak_smtp_username, local.ses_smtp_username_value)
  keycloak_smtp_password_value                  = coalesce(var.keycloak_smtp_password, local.ses_smtp_password_value)
  keycloak_db_username_value                    = coalesce(var.keycloak_db_username, local.master_username)
  keycloak_db_password_value                    = coalesce(var.keycloak_db_password, local.db_password_effective)
  keycloak_admin_username_value                 = coalesce(try(local.keycloak_admin_params_from_ssm[local.keycloak_admin_username_parameter_name], null), var.keycloak_admin_username)
  keycloak_admin_password_value                 = coalesce(var.keycloak_admin_password, try(local.keycloak_admin_params_from_ssm[local.keycloak_admin_password_parameter_name], null), var.create_keycloak && local.ssm_writes_enabled ? try(random_password.keycloak_admin[0].result, null) : null)
  odoo_smtp_username_value                      = coalesce(var.odoo_smtp_username, local.ses_smtp_username_value)
  odoo_smtp_password_value                      = coalesce(var.odoo_smtp_password, local.ses_smtp_password_value)
  odoo_db_username_value                        = coalesce(var.odoo_db_username, local.master_username)
  odoo_db_password_value                        = coalesce(var.odoo_db_password, local.db_password_effective)
  odoo_admin_password_value                     = var.odoo_admin_password != null ? var.odoo_admin_password : (var.create_odoo && local.ssm_writes_enabled ? try(random_password.odoo_admin[0].result, null) : null)
  gitlab_db_username_value                      = coalesce(var.gitlab_db_username, local.master_username)
  gitlab_db_password_value                      = coalesce(var.gitlab_db_password, local.db_password_effective)
  gitlab_db_name_value                          = var.gitlab_db_name
  gitlab_smtp_username_value                    = coalesce(var.gitlab_smtp_username, local.ses_smtp_username_value)
  gitlab_smtp_password_value                    = coalesce(var.gitlab_smtp_password, local.ses_smtp_password_value)
  exastro_web_smtp_username_value               = local.ses_smtp_username_value
  exastro_web_smtp_password_value               = local.ses_smtp_password_value
  exastro_api_smtp_username_value               = local.ses_smtp_username_value
  exastro_api_smtp_password_value               = local.ses_smtp_password_value
  pgadmin_smtp_username_value                   = coalesce(var.pgadmin_smtp_username, local.ses_smtp_username_value)
  pgadmin_smtp_password_value                   = coalesce(var.pgadmin_smtp_password, local.ses_smtp_password_value)
  growi_smtp_username_value                     = coalesce(var.growi_smtp_username, local.ses_smtp_username_value)
  growi_smtp_password_value                     = coalesce(var.growi_smtp_password, local.ses_smtp_password_value)
  cmdbuild_smtp_username_value                  = coalesce(var.cmdbuild_smtp_username, local.ses_smtp_username_value)
  cmdbuild_smtp_password_value                  = coalesce(var.cmdbuild_smtp_password, local.ses_smtp_password_value)
  orangehrm_smtp_username_value                 = coalesce(var.orangehrm_smtp_username, local.ses_smtp_username_value)
  orangehrm_smtp_password_value                 = coalesce(var.orangehrm_smtp_password, local.ses_smtp_password_value)
}

locals {
  smtp_creds_available            = var.enable_ses_smtp_auto
  n8n_smtp_params_enabled         = local.smtp_creds_available || var.n8n_smtp_username != null || var.n8n_smtp_password != null
  zulip_smtp_params_enabled       = local.smtp_creds_available || var.zulip_smtp_username != null || var.zulip_smtp_password != null
  keycloak_smtp_params_enabled    = local.smtp_creds_available || var.keycloak_smtp_username != null || var.keycloak_smtp_password != null
  odoo_smtp_params_enabled        = local.smtp_creds_available || var.odoo_smtp_username != null || var.odoo_smtp_password != null
  gitlab_smtp_params_enabled      = local.smtp_creds_available || var.gitlab_smtp_username != null || var.gitlab_smtp_password != null
  exastro_web_smtp_params_enabled = local.smtp_creds_available
  exastro_api_smtp_params_enabled = local.smtp_creds_available
  pgadmin_smtp_params_enabled     = local.smtp_creds_available || var.pgadmin_smtp_username != null || var.pgadmin_smtp_password != null
  growi_smtp_params_enabled       = local.smtp_creds_available || var.growi_smtp_username != null || var.growi_smtp_password != null
  cmdbuild_smtp_params_enabled    = local.smtp_creds_available || var.cmdbuild_smtp_username != null || var.cmdbuild_smtp_password != null
  orangehrm_smtp_params_enabled   = local.smtp_creds_available || var.orangehrm_smtp_username != null || var.orangehrm_smtp_password != null
  randoms_enabled                 = local.ssm_writes_enabled
}

resource "aws_ssm_parameter" "db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters && var.create_rds ? 1 : 0) : 0

  name  = local.db_username_parameter_name
  type  = "SecureString"
  value = local.master_username

  tags = merge(local.tags, { Name = "${local.name_prefix}-db-username" })
}

resource "aws_ssm_parameter" "db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters && var.create_rds && local.db_password_effective != null ? 1 : 0) : 0

  name  = local.db_password_parameter_name
  type  = "SecureString"
  value = local.db_password_effective

  tags = merge(local.tags, { Name = "${local.name_prefix}-db-password" })
}

resource "aws_ssm_parameter" "n8n_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.n8n_db_username_parameter_name
  type  = "String"
  value = local.master_username

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-db-username" })
}

resource "aws_ssm_parameter" "n8n_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.n8n_db_password_parameter_name
  type  = "SecureString"
  value = local.db_password_effective

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-db-password" })
}

resource "aws_ssm_parameter" "n8n_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.n8n_db_name_parameter_name
  type  = "String"
  value = var.n8n_db_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-db-name" })
}

resource "aws_ssm_parameter" "n8n_oidc_client_id" {
  count = local.n8n_oidc_client_id_write_enabled ? 1 : 0

  name      = local.n8n_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.n8n_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-oidc-client-id" })
}

resource "aws_ssm_parameter" "n8n_oidc_client_secret" {
  count = local.n8n_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.n8n_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.n8n_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-oidc-client-secret" })
}

resource "aws_ssm_parameter" "n8n_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && local.n8n_smtp_params_enabled ? 1 : 0) : 0

  name      = local.n8n_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.n8n_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-smtp-username" })
}

resource "aws_ssm_parameter" "n8n_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && local.n8n_smtp_params_enabled ? 1 : 0) : 0

  name      = local.n8n_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.n8n_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-smtp-password" })
}

resource "aws_ssm_parameter" "keycloak_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && local.keycloak_smtp_params_enabled ? 1 : 0) : 0

  name      = local.keycloak_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.keycloak_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-smtp-username" })
}

resource "aws_ssm_parameter" "keycloak_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && local.keycloak_smtp_params_enabled ? 1 : 0) : 0

  name      = local.keycloak_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.keycloak_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-smtp-password" })
}

resource "aws_ssm_parameter" "odoo_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_odoo && local.odoo_smtp_params_enabled ? 1 : 0) : 0

  name      = local.odoo_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.odoo_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-smtp-username" })
}

resource "aws_ssm_parameter" "odoo_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_odoo && local.odoo_smtp_params_enabled ? 1 : 0) : 0

  name      = local.odoo_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.odoo_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-smtp-password" })
}

resource "aws_ssm_parameter" "zulip_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip && local.zulip_smtp_params_enabled ? 1 : 0) : 0

  name      = local.zulip_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.zulip_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-smtp-username" })
}

resource "aws_ssm_parameter" "zulip_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip && local.zulip_smtp_params_enabled ? 1 : 0) : 0

  name      = local.zulip_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.zulip_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-smtp-password" })
}

resource "aws_ssm_parameter" "zulip_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.zulip_db_username_parameter_name
  type  = "String"
  value = local.master_username

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-db-username" })
}

resource "aws_ssm_parameter" "zulip_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.zulip_db_password_parameter_name
  type  = "SecureString"
  value = local.db_password_effective

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-db-password" })
}

resource "aws_ssm_parameter" "zulip_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.zulip_db_name_parameter_name
  type  = "String"
  value = var.zulip_db_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-db-name" })
}

resource "aws_ssm_parameter" "growi_db_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_db_username_parameter_name
  type      = "String"
  value     = local.growi_db_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-db-username" })
}

resource "aws_ssm_parameter" "growi_db_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_db_password_parameter_name
  type      = "SecureString"
  value     = local.growi_db_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-db-password" })
}

resource "aws_ssm_parameter" "growi_db_name" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_db_name_parameter_name
  type      = "String"
  value     = local.growi_db_name_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-db-name" })
}

resource "aws_ssm_parameter" "growi_db_host" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_db_host_parameter_name
  type      = "String"
  value     = var.create_growi_docdb ? try(aws_docdb_cluster.growi[0].endpoint, "") : ""
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-db-host" })
}

resource "aws_ssm_parameter" "growi_db_port" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_db_port_parameter_name
  type      = "String"
  value     = var.create_growi_docdb ? tostring(try(aws_docdb_cluster.growi[0].port, 27017)) : "27017"
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-db-port" })
}

resource "aws_ssm_parameter" "growi_mongo_uri" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi ? 1 : 0) : 0

  name      = local.growi_mongo_uri_parameter_name
  type      = "SecureString"
  value     = var.create_growi_docdb ? "mongodb://${local.growi_db_username_value}:${urlencode(local.growi_db_password_value)}@${aws_docdb_cluster.growi[0].endpoint}:${aws_docdb_cluster.growi[0].port}/${local.growi_db_name_value}?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false" : ""
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-mongo-uri" })
}

resource "aws_ssm_parameter" "growi_oidc_client_id" {
  count = local.growi_oidc_client_id_write_enabled ? 1 : 0

  name      = local.growi_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.growi_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-oidc-client-id" })
}

resource "aws_ssm_parameter" "growi_oidc_client_secret" {
  count = local.growi_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.growi_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.growi_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-oidc-client-secret" })
}

resource "aws_ssm_parameter" "keycloak_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.keycloak_db_username_parameter_name
  type  = "String"
  value = local.keycloak_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-username" })
}

resource "aws_ssm_parameter" "keycloak_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.keycloak_db_password_parameter_name
  type  = "SecureString"
  value = local.keycloak_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-password" })
}

resource "aws_ssm_parameter" "keycloak_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.keycloak_db_name_parameter_name
  type  = "String"
  value = var.keycloak_db_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-name" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name      = local.cmdbuild_r2u_db_username_parameter_name
  type      = "String"
  value     = local.cmdbuild_r2u_db_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-db-username" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name      = local.cmdbuild_r2u_db_password_parameter_name
  type      = "SecureString"
  value     = local.cmdbuild_r2u_db_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-db-password" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name      = local.cmdbuild_r2u_db_name_parameter_name
  type      = "String"
  value     = local.cmdbuild_r2u_db_name_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-db-name" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_oidc_client_id" {
  count = local.cmdbuild_r2u_oidc_client_id_write_enabled ? 1 : 0

  name      = local.cmdbuild_r2u_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.cmdbuild_r2u_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-oidc-client-id" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_oidc_client_secret" {
  count = local.cmdbuild_r2u_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.cmdbuild_r2u_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.cmdbuild_r2u_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-oidc-client-secret" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_db_host" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_cmdbuild_r2u && var.create_rds ? 1 : 0) : 0

  name      = local.cmdbuild_r2u_db_host_parameter_name
  type      = "String"
  value     = aws_db_instance.this[0].address
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-db-host" })
}

resource "aws_ssm_parameter" "cmdbuild_r2u_db_port" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_cmdbuild_r2u && var.create_rds ? 1 : 0) : 0

  name      = local.cmdbuild_r2u_db_port_parameter_name
  type      = "String"
  value     = tostring(aws_db_instance.this[0].port)
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-db-port" })
}

resource "aws_ssm_parameter" "keycloak_db_host" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && var.create_rds ? 1 : 0) : 0

  name  = local.keycloak_db_host_parameter_name
  type  = "String"
  value = aws_db_instance.this[0].address

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-host" })
}

resource "aws_ssm_parameter" "keycloak_db_port" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && var.create_rds ? 1 : 0) : 0

  name  = local.keycloak_db_port_parameter_name
  type  = "String"
  value = tostring(aws_db_instance.this[0].port)

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-port" })
}

resource "aws_ssm_parameter" "keycloak_db_url" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && var.create_rds ? 1 : 0) : 0

  name  = local.keycloak_db_url_parameter_name
  type  = "SecureString"
  value = "jdbc:postgresql://${aws_db_instance.this[0].address}:${aws_db_instance.this[0].port}/${var.keycloak_db_name}"

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-db-url" })
}

resource "aws_ssm_parameter" "keycloak_admin_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak ? 1 : 0) : 0

  name      = local.keycloak_admin_username_parameter_name
  type      = "SecureString"
  value     = local.keycloak_admin_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-admin-username" })
}

resource "aws_ssm_parameter" "keycloak_admin_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak ? 1 : 0) : 0

  name      = local.keycloak_admin_password_parameter_name
  type      = "SecureString"
  value     = local.keycloak_admin_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-admin-password" })
}

resource "aws_ssm_parameter" "odoo_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.odoo_db_username_parameter_name
  type  = "String"
  value = local.odoo_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-db-username" })
}

resource "aws_ssm_parameter" "odoo_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.odoo_db_password_parameter_name
  type  = "SecureString"
  value = local.odoo_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-db-password" })
}

resource "aws_ssm_parameter" "odoo_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.odoo_db_name_parameter_name
  type  = "String"
  value = var.odoo_db_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-db-name" })
}

resource "aws_ssm_parameter" "odoo_oidc_client_id" {
  count = local.odoo_oidc_client_id_write_enabled ? 1 : 0

  name      = local.odoo_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.odoo_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-oidc-client-id" })
}

resource "aws_ssm_parameter" "odoo_oidc_client_secret" {
  count = local.odoo_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.odoo_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.odoo_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-oidc-client-secret" })
}

resource "aws_ssm_parameter" "mysql_db_username" {
  count = local.ssm_writes_enabled ? (var.create_mysql_rds ? 1 : 0) : 0

  name      = local.mysql_db_username_parameter_name
  type      = "String"
  value     = local.mysql_db_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-mysql-db-username" })
}

resource "aws_ssm_parameter" "mysql_db_password" {
  count = local.ssm_writes_enabled ? (var.create_mysql_rds ? 1 : 0) : 0

  name      = local.mysql_db_password_parameter_name
  type      = "SecureString"
  value     = local.mysql_db_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-mysql-db-password" })
}

resource "aws_ssm_parameter" "mysql_db_name" {
  count = local.ssm_writes_enabled ? (var.create_mysql_rds ? 1 : 0) : 0

  name      = local.mysql_db_name_parameter_name
  type      = "String"
  value     = local.mysql_db_name_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-mysql-db-name" })
}

resource "aws_ssm_parameter" "mysql_db_host" {
  count = local.ssm_writes_enabled ? (var.create_mysql_rds ? 1 : 0) : 0

  name      = local.mysql_db_host_parameter_name
  type      = "String"
  value     = var.create_mysql_rds ? try(aws_db_instance.mysql[0].address, "") : ""
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-mysql-db-host" })
}

resource "aws_ssm_parameter" "mysql_db_port" {
  count = local.ssm_writes_enabled ? (var.create_mysql_rds ? 1 : 0) : 0

  name      = local.mysql_db_port_parameter_name
  type      = "String"
  value     = var.create_mysql_rds ? tostring(try(aws_db_instance.mysql[0].port, 3306)) : "3306"
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-mysql-db-port" })
}

resource "aws_ssm_parameter" "orangehrm_admin_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_orangehrm ? 1 : 0) : 0

  name      = local.orangehrm_admin_username_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_admin_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-admin-username" })
}

resource "aws_ssm_parameter" "orangehrm_admin_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_orangehrm ? 1 : 0) : 0

  name      = local.orangehrm_admin_password_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_admin_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-admin-password" })
}

resource "aws_ssm_parameter" "orangehrm_oidc_client_id" {
  count = local.orangehrm_oidc_client_id_write_enabled ? 1 : 0

  name      = local.orangehrm_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-oidc-client-id" })
}

resource "aws_ssm_parameter" "orangehrm_oidc_client_secret" {
  count = local.orangehrm_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.orangehrm_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-oidc-client-secret" })
}

resource "aws_ssm_parameter" "gitlab_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.gitlab_db_username_parameter_name
  type  = "String"
  value = local.gitlab_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-db-username" })
}

resource "aws_ssm_parameter" "gitlab_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.gitlab_db_password_parameter_name
  type  = "SecureString"
  value = local.gitlab_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-db-password" })
}

resource "aws_ssm_parameter" "gitlab_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.gitlab_db_name_parameter_name
  type  = "String"
  value = local.gitlab_db_name_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-db-name" })
}

resource "aws_ssm_parameter" "gitlab_db_host" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.gitlab_db_host_parameter_name
  type  = "String"
  value = aws_db_instance.this[0].address

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-db-host" })
}

resource "aws_ssm_parameter" "gitlab_db_port" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.gitlab_db_port_parameter_name
  type  = "String"
  value = tostring(aws_db_instance.this[0].port)

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-db-port" })
}

resource "aws_ssm_parameter" "gitlab_oidc_client_id" {
  count = local.gitlab_oidc_client_id_write_enabled ? 1 : 0

  name      = local.gitlab_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.gitlab_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-oidc-client-id" })
}

resource "aws_ssm_parameter" "gitlab_oidc_client_secret" {
  count = local.gitlab_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.gitlab_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.gitlab_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-oidc-client-secret" })
}

resource "aws_ssm_parameter" "oase_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.oase_db_username_parameter_name
  type  = "String"
  value = local.oase_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-oase-db-username" })
}

resource "aws_ssm_parameter" "oase_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters && local.oase_db_password_value != null ? 1 : 0) : 0

  name  = local.oase_db_password_parameter_name
  type  = "SecureString"
  value = local.oase_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-oase-db-password" })
}

resource "aws_ssm_parameter" "oase_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.oase_db_name_parameter_name
  type  = "String"
  value = local.oase_db_name_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-oase-db-name" })
}

resource "aws_ssm_parameter" "exastro_pf_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.exastro_pf_db_username_parameter_name
  type  = "String"
  value = local.exastro_pf_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-pf-db-username" })
}

resource "aws_ssm_parameter" "exastro_pf_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters && local.exastro_pf_db_password_value != null ? 1 : 0) : 0

  name  = local.exastro_pf_db_password_parameter_name
  type  = "SecureString"
  value = local.exastro_pf_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-pf-db-password" })
}

resource "aws_ssm_parameter" "exastro_pf_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.exastro_pf_db_name_parameter_name
  type  = "String"
  value = local.exastro_pf_db_name_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-pf-db-name" })
}

resource "aws_ssm_parameter" "exastro_ita_db_username" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.exastro_ita_db_username_parameter_name
  type  = "String"
  value = local.exastro_ita_db_username_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-ita-db-username" })
}

resource "aws_ssm_parameter" "exastro_ita_db_password" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters && local.exastro_ita_db_password_value != null ? 1 : 0) : 0

  name  = local.exastro_ita_db_password_parameter_name
  type  = "SecureString"
  value = local.exastro_ita_db_password_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-ita-db-password" })
}

resource "aws_ssm_parameter" "exastro_ita_db_name" {
  count = local.ssm_writes_enabled ? (var.create_db_credentials_parameters ? 1 : 0) : 0

  name  = local.exastro_ita_db_name_parameter_name
  type  = "String"
  value = local.exastro_ita_db_name_value

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-ita-db-name" })
}

resource "aws_ssm_parameter" "gitlab_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_gitlab && local.gitlab_smtp_params_enabled ? 1 : 0) : 0

  name      = local.gitlab_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.gitlab_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-smtp-username" })
}

resource "aws_ssm_parameter" "gitlab_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_gitlab && local.gitlab_smtp_params_enabled ? 1 : 0) : 0

  name      = local.gitlab_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.gitlab_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-smtp-password" })
}

resource "aws_ssm_parameter" "exastro_web_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_exastro_web_server && local.exastro_web_smtp_params_enabled ? 1 : 0) : 0

  name      = local.exastro_web_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.exastro_web_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-smtp-username" })
}

resource "aws_ssm_parameter" "exastro_web_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_exastro_web_server && local.exastro_web_smtp_params_enabled ? 1 : 0) : 0

  name      = local.exastro_web_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.exastro_web_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-smtp-password" })
}

resource "aws_ssm_parameter" "exastro_web_oidc_client_id" {
  count = local.exastro_web_oidc_client_id_write_enabled ? 1 : 0

  name      = local.exastro_web_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.exastro_web_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-oidc-client-id" })
}

resource "aws_ssm_parameter" "exastro_web_oidc_client_secret" {
  count = local.exastro_web_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.exastro_web_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.exastro_web_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-oidc-client-secret" })
}

resource "aws_ssm_parameter" "exastro_api_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_exastro_api_admin && local.exastro_api_smtp_params_enabled ? 1 : 0) : 0

  name      = local.exastro_api_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.exastro_api_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-smtp-username" })
}

resource "aws_ssm_parameter" "exastro_api_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_exastro_api_admin && local.exastro_api_smtp_params_enabled ? 1 : 0) : 0

  name      = local.exastro_api_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.exastro_api_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-smtp-password" })
}

resource "aws_ssm_parameter" "exastro_api_oidc_client_id" {
  count = local.exastro_api_oidc_client_id_write_enabled ? 1 : 0

  name      = local.exastro_api_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.exastro_api_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-oidc-client-id" })
}

resource "aws_ssm_parameter" "exastro_api_oidc_client_secret" {
  count = local.exastro_api_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.exastro_api_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.exastro_api_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-oidc-client-secret" })
}


resource "aws_ssm_parameter" "pgadmin_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_pgadmin && local.pgadmin_smtp_params_enabled ? 1 : 0) : 0

  name = local.pgadmin_smtp_username_parameter_name
  type = "SecureString"
  # Quote the value so pgAdmin's config_distro.py sees a valid Python string literal.
  value     = local.pgadmin_smtp_username_value != null ? jsonencode(local.pgadmin_smtp_username_value) : null
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-smtp-username" })
}

resource "aws_ssm_parameter" "pgadmin_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_pgadmin && local.pgadmin_smtp_params_enabled ? 1 : 0) : 0

  name = local.pgadmin_smtp_password_parameter_name
  type = "SecureString"
  # Quote the value so pgAdmin's config_distro.py sees a valid Python string literal.
  value     = local.pgadmin_smtp_password_value != null ? jsonencode(local.pgadmin_smtp_password_value) : null
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-smtp-password" })
}

resource "aws_ssm_parameter" "pgadmin_oidc_client_id" {
  count = local.pgadmin_oidc_client_id_write_enabled ? 1 : 0

  name      = local.pgadmin_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.pgadmin_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-oidc-client-id" })
}

resource "aws_ssm_parameter" "pgadmin_oidc_client_secret" {
  count = local.pgadmin_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.pgadmin_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.pgadmin_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-oidc-client-secret" })
}

resource "aws_ssm_parameter" "growi_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi && local.growi_smtp_params_enabled ? 1 : 0) : 0

  name      = local.growi_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.growi_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-smtp-username" })
}

resource "aws_ssm_parameter" "growi_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_growi && local.growi_smtp_params_enabled ? 1 : 0) : 0

  name      = local.growi_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.growi_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-smtp-password" })
}

resource "aws_ssm_parameter" "cmdbuild_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_cmdbuild_r2u && local.cmdbuild_smtp_params_enabled ? 1 : 0) : 0

  name      = local.cmdbuild_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.cmdbuild_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-smtp-username" })
}

resource "aws_ssm_parameter" "cmdbuild_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_cmdbuild_r2u && local.cmdbuild_smtp_params_enabled ? 1 : 0) : 0

  name      = local.cmdbuild_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.cmdbuild_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-smtp-password" })
}

resource "aws_ssm_parameter" "orangehrm_smtp_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_orangehrm && local.orangehrm_smtp_params_enabled ? 1 : 0) : 0

  name      = local.orangehrm_smtp_username_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_smtp_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-smtp-username" })
}

resource "aws_ssm_parameter" "orangehrm_smtp_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_orangehrm && local.orangehrm_smtp_params_enabled ? 1 : 0) : 0

  name      = local.orangehrm_smtp_password_parameter_name
  type      = "SecureString"
  value     = local.orangehrm_smtp_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-smtp-password" })
}

resource "random_password" "growi_db" {
  count            = local.ssm_writes_enabled ? (var.create_growi_docdb && var.growi_db_password == null ? 1 : 0) : 0
  length           = 16
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%^&*()-_+="
}

resource "random_password" "mysql_db" {
  count            = local.ssm_writes_enabled ? (var.create_mysql_rds && var.mysql_db_password == null && var.orangehrm_db_password == null ? 1 : 0) : 0
  length           = 16
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%^&*()-_+="
}

resource "random_password" "orangehrm_admin" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_orangehrm && var.orangehrm_admin_password == null ? 1 : 0) : 0
  length  = 16
  special = false
}

resource "random_password" "odoo_admin" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_odoo && var.odoo_admin_password == null ? 1 : 0) : 0
  length  = 24
  special = false
}

resource "random_password" "keycloak_admin" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_keycloak && var.keycloak_admin_password == null ? 1 : 0) : 0
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "odoo_admin_password" {
  # The value is always resolved from either var.odoo_admin_password or random_password.odoo_admin.
  # Keep creation gated only by create flags to avoid count depending on computed values.
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_odoo ? 1 : 0) : 0

  name      = local.odoo_admin_password_parameter_name
  type      = "SecureString"
  value     = local.odoo_admin_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-admin-password" })
}

resource "random_password" "pgadmin_default_password" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_pgadmin ? 1 : 0) : 0
  length  = 20
  special = false
}

resource "aws_ssm_parameter" "pgadmin_default_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_pgadmin ? 1 : 0) : 0

  name      = local.pgadmin_default_password_parameter_name
  type      = "SecureString"
  value     = random_password.pgadmin_default_password[0].result
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-default-password" })
}

resource "random_password" "phpmyadmin_blowfish_secret" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_phpmyadmin ? 1 : 0) : 0
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "phpmyadmin_blowfish_secret" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_phpmyadmin ? 1 : 0) : 0

  name      = local.phpmyadmin_blowfish_secret_parameter_name
  type      = "SecureString"
  value     = random_password.phpmyadmin_blowfish_secret[0].result
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-phpmyadmin-blowfish-secret" })
}

resource "random_password" "zulip_secret_key" {
  count   = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip && var.zulip_secret_key == null ? 1 : 0) : 0
  length  = 50
  special = true
}

resource "aws_ssm_parameter" "zulip_secret_key" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_secret_key_parameter_name
  type      = "SecureString"
  value     = local.zulip_secret_key_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-secret-key" })
}

resource "aws_ssm_parameter" "db_host" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.db_host_parameter_name
  type  = "String"
  value = aws_db_instance.this[0].address

  tags = merge(local.tags, { Name = "${local.name_prefix}-db-host" })
}

resource "aws_ssm_parameter" "db_port" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.db_port_parameter_name
  type  = "String"
  value = tostring(aws_db_instance.this[0].port)

  tags = merge(local.tags, { Name = "${local.name_prefix}-db-port" })
}

resource "aws_ssm_parameter" "db_name" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.db_name_parameter_name
  type  = "String"
  value = var.pg_db_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-db-name" })
}

resource "aws_ssm_parameter" "zulip_datasource" {
  count = local.ssm_writes_enabled ? (var.create_rds ? 1 : 0) : 0

  name  = local.zulip_datasource_parameter_name
  type  = "SecureString"
  value = "postgres://${local.master_username}:${urlencode(local.db_password_effective)}@${aws_db_instance.this[0].address}:${aws_db_instance.this[0].port}/${var.zulip_db_name}?sslmode=require&connect_timeout=10"

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-datasource" })
}

resource "aws_ssm_parameter" "zulip_mq_username" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip && local.zulip_mq_username_value != null ? 1 : 0) : 0

  name      = local.zulip_mq_username_parameter_name
  type      = "SecureString"
  value     = local.zulip_mq_username_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-mq-username" })
}

resource "aws_ssm_parameter" "zulip_mq_password" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip && local.zulip_mq_password_value != null ? 1 : 0) : 0

  name      = local.zulip_mq_password_parameter_name
  type      = "SecureString"
  value     = local.zulip_mq_password_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-mq-password" })
}

resource "aws_ssm_parameter" "zulip_mq_host" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_mq_host_parameter_name
  type      = "String"
  value     = coalesce(local.zulip_mq_host, "")
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-mq-host" })
}

resource "aws_ssm_parameter" "zulip_mq_port" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_mq_port_parameter_name
  type      = "String"
  value     = local.zulip_mq_port_effective != null ? tostring(local.zulip_mq_port_effective) : ""
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-mq-port" })
}

resource "aws_ssm_parameter" "zulip_mq_amqp_endpoint" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_mq_endpoint_parameter_name
  type      = "String"
  value     = coalesce(local.zulip_mq_amqp_endpoint, "")
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-mq-amqp-endpoint" })
}

resource "aws_ssm_parameter" "zulip_redis_host" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_redis_host_parameter_name
  type      = "String"
  value     = coalesce(local.zulip_redis_host, "")
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-redis-host" })
}

resource "aws_ssm_parameter" "zulip_redis_port" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_redis_port_parameter_name
  type      = "String"
  value     = tostring(local.zulip_redis_port)
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-redis-port" })
}

resource "aws_ssm_parameter" "zulip_memcached_endpoint" {
  count = local.ssm_writes_enabled ? (var.create_ecs && var.create_zulip ? 1 : 0) : 0

  name      = local.zulip_memcached_endpoint_parameter_name
  type      = "String"
  value     = coalesce(local.zulip_memcached_endpoint, "")
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-memcached-endpoint" })
}

resource "aws_ssm_parameter" "zulip_oidc_client_id" {
  count = local.zulip_oidc_client_id_write_enabled ? 1 : 0

  name      = local.zulip_oidc_client_id_parameter_name
  type      = "SecureString"
  value     = local.zulip_oidc_client_id_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-oidc-client-id" })
}

resource "aws_ssm_parameter" "zulip_oidc_client_secret" {
  count = local.zulip_oidc_client_secret_write_enabled ? 1 : 0

  name      = local.zulip_oidc_client_secret_parameter_name
  type      = "SecureString"
  value     = local.zulip_oidc_client_secret_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-oidc-client-secret" })
}

resource "aws_ssm_parameter" "zulip_oidc_idps" {
  count = local.zulip_oidc_idps_write_enabled ? 1 : 0

  name      = local.zulip_oidc_idps_parameter_name
  type      = "SecureString"
  value     = local.zulip_oidc_idps_value
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-oidc-idps" })
}

resource "random_password" "n8n_encryption_key" {
  count   = local.ssm_writes_enabled ? (var.create_ecs ? 1 : 0) : 0
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "n8n_encryption_key" {
  count = local.ssm_writes_enabled ? (var.create_ecs ? 1 : 0) : 0

  name  = local.n8n_encryption_key_parameter_name
  type  = "SecureString"
  value = random_password.n8n_encryption_key[0].result

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-encryption-key" })
}
