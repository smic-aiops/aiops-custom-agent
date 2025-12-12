locals {
  ssm_console_base = "https://${var.region}.console.aws.amazon.com/systems-manager/parameters"
  admin_param_names = {
    keycloak_admin_username  = var.create_ecs && var.create_keycloak ? local.keycloak_admin_username_parameter_name : null
    keycloak_admin_password  = var.create_ecs && var.create_keycloak ? local.keycloak_admin_password_parameter_name : null
    odoo_admin_password      = var.create_ecs && var.create_odoo ? local.odoo_admin_password_parameter_name : null
    pgadmin_default_password = var.create_ecs && var.create_pgadmin ? local.pgadmin_default_password_parameter_name : null
    orangehrm_admin_password = var.create_ecs && var.create_orangehrm ? local.orangehrm_admin_password_parameter_name : null
  }
  admin_param_console_urls = {
    for key, param in local.admin_param_names :
    key => param != null ? "${local.ssm_console_base}/${urlencode(param)}/description?region=${var.region}" : null
  }
}

output "vpc_id" {
  description = "ID of the selected or created VPC"
  value       = local.vpc_id
}

output "hosted_zone_id" {
  description = "Managed Route53 hosted zone ID"
  value       = local.hosted_zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the managed hosted zone"
  value       = local.hosted_zone_name_servers
}

output "hosted_zone_name" {
  description = "Managed Route53 hosted zone name (root domain)"
  value       = local.hosted_zone_name_input
}

output "db_credentials_ssm_parameters" {
  description = "SSM parameter names for DB credentials (if created)"
  value = {
    username = try(aws_ssm_parameter.db_username[0].name, null)
    password = try(aws_ssm_parameter.db_password[0].name, null)
    host     = try(aws_ssm_parameter.db_host[0].name, null)
    port     = try(aws_ssm_parameter.db_port[0].name, null)
    name     = try(aws_ssm_parameter.db_name[0].name, null)
  }
}

output "ecs_cluster" {
  description = "ECS cluster and roles"
  value = {
    name               = try(aws_ecs_cluster.this[0].name, null)
    arn                = try(aws_ecs_cluster.this[0].arn, null)
    execution_role_arn = try(aws_iam_role.ecs_execution[0].arn, null)
    task_role_arn      = try(aws_iam_role.ecs_task[0].arn, null)
  }
}

output "service_urls" {
  description = "Endpoints for user-facing services"
  value = {
    n8n          = var.create_ecs && var.create_n8n ? "https://${local.n8n_host}" : null
    zulip        = var.create_ecs && var.create_zulip ? "https://${local.zulip_host}" : null
    exastro_web  = var.create_ecs && var.create_exastro_web_server ? "https://${local.exastro_web_host}" : null
    exastro_api  = var.create_ecs && var.create_exastro_api_admin ? "https://${local.exastro_api_host}" : null
    pgadmin      = var.create_ecs && var.create_pgadmin ? "https://${local.pgadmin_host}" : null
    phpmyadmin   = var.create_ecs && var.create_phpmyadmin ? "https://${local.phpmyadmin_host}" : null
    odoo         = var.create_ecs && var.create_odoo ? "https://${local.odoo_host}" : null
    keycloak     = var.create_ecs && var.create_keycloak ? "https://${local.keycloak_host}" : null
    gitlab       = var.create_ecs && var.create_gitlab ? "https://${local.gitlab_host}" : null
    sulu         = var.create_ecs && var.create_sulu ? "https://${local.sulu_host}" : null
    growi        = var.create_ecs && var.create_growi ? "https://${local.growi_host}" : null
    cmdbuild_r2u = var.create_ecs && var.create_cmdbuild_r2u ? "https://${local.cmdbuild_r2u_host}" : null
    orangehrm    = var.create_ecs && var.create_orangehrm ? "https://${local.orangehrm_host}" : null
    control_ui   = "https://${local.control_site_domain}"
    alb_dns      = try(aws_lb.app[0].dns_name, null)
    control_cf   = try(aws_cloudfront_distribution.control_site[0].domain_name, null)
    control_api  = local.control_api_base_url_effective != "" ? "${local.control_api_base_url_effective}" : null
  }
}

output "enabled_services" {
  description = "ECS services enabled for deployment"
  value       = local.enabled_services
}

# output "zulip_dependencies" {
#   description = "Connection details and parameter names for Zulip dependencies"
#   value = {
#     redis_host                   = local.zulip_redis_host
#     redis_port                   = local.zulip_redis_port
#     memcached_endpoint           = local.zulip_memcached_endpoint
#     memcached_host               = local.zulip_memcached_host
#     memcached_port               = local.zulip_memcached_port_effective
#     mq_endpoint                  = local.zulip_mq_amqp_endpoint
#     mq_host                      = local.zulip_mq_host
#     mq_port                      = local.zulip_mq_port_effective
#     mq_username                  = var.zulip_mq_username
#     mq_password_parameter        = local.zulip_mq_password_parameter_name
#     db_username_parameter        = local.zulip_db_username_parameter_name
#     db_password_parameter        = local.zulip_db_password_parameter_name
#     db_name_parameter            = local.zulip_db_name_parameter_name
#     secret_key_parameter         = local.zulip_secret_key_parameter_name
#     oidc_client_id_parameter     = local.zulip_oidc_client_id_parameter_name
#     oidc_client_secret_parameter = local.zulip_oidc_client_secret_parameter_name
#     oidc_idps_parameter          = local.zulip_oidc_idps_parameter_name
#   }
# }

output "sulu_control_api_base_url" {
  description = "Base URL for the sulu control API (set via var.sulu_control_api_base_url)"
  value       = local.sulu_control_api_base_url_effective
}

output "service_control_api_base_url" {
  description = "Base URL for the service control API (n8n/zulip/sulu/keycloak/odoo/pgadmin/phpmyadmin/gitlab)"
  value       = local.service_control_api_base_url_effective
}

output "n8n_filesystem_id" {
  description = "EFS ID used for n8n (if created or supplied)"
  value       = local.n8n_filesystem_id_effective
}

output "zulip_filesystem_id" {
  description = "EFS ID used for Zulip (if created or supplied)"
  value       = local.zulip_filesystem_id_effective
}

output "sulu_filesystem_id" {
  description = "EFS ID used for sulu (if created or supplied)"
  value       = try(local.sulu_filesystem_id_effective, null)
}

output "exastro_filesystem_id" {
  description = "EFS ID used for Exastro IT Automation (if created or supplied)"
  value       = local.exastro_filesystem_id_effective
}

output "cmdbuild_r2u_filesystem_id" {
  description = "EFS ID used for CMDBuild READY2USE (if created or supplied)"
  value       = local.cmdbuild_r2u_filesystem_id_effective
}

output "keycloak_filesystem_id" {
  description = "EFS ID used for Keycloak (if created or supplied)"
  value       = local.keycloak_filesystem_id_effective
}

output "odoo_filesystem_id" {
  description = "EFS ID used for Odoo (if created or supplied)"
  value       = local.odoo_filesystem_id_effective
}

output "pgadmin_filesystem_id" {
  description = "EFS ID used for pgAdmin (if created or supplied)"
  value       = local.pgadmin_filesystem_id_effective
}

output "growi_filesystem_id" {
  description = "EFS ID used for GROWI (if created or supplied)"
  value       = local.growi_filesystem_id_effective
}

output "orangehrm_filesystem_id" {
  description = "EFS ID used for OrangeHRM (if created or supplied)"
  value       = local.orangehrm_filesystem_id_effective
}

output "gitlab_data_filesystem_id" {
  description = "EFS ID used for GitLab data (if created or supplied)"
  value       = local.gitlab_data_filesystem_id_effective
}

output "gitlab_config_filesystem_id" {
  description = "EFS ID used for GitLab config (if created or supplied)"
  value       = local.gitlab_config_filesystem_id_effective
}

output "rds" {
  description = "RDS instance details (if created)"
  value = {
    identifier     = try(aws_db_instance.this[0].id, null)
    endpoint       = try(aws_db_instance.this[0].address, null)
    port           = try(aws_db_instance.this[0].port, null)
    engine         = try(aws_db_instance.this[0].engine, null)
    engine_version = try(aws_db_instance.this[0].engine_version, null)
  }
}

output "rds_postgresql" {
  description = "PostgreSQL RDS connection details and password retrieval helper (if created)"
  value = {
    host               = var.create_rds ? try(aws_db_instance.this[0].address, null) : null
    port               = var.create_rds ? try(aws_db_instance.this[0].port, null) : null
    database           = var.create_rds ? var.pg_db_name : null
    username           = var.create_rds ? local.master_username : null
    password_parameter = var.create_rds ? local.db_password_parameter_name : null
    password_get_command = var.create_rds ? trimspace(join(" ", compact([
      "aws ssm get-parameter",
      "--with-decryption",
      "--name ${local.db_password_parameter_name}",
      var.aws_profile != null ? "--profile ${var.aws_profile}" : null,
      var.region != null ? "--region ${var.region}" : null,
      "--query Parameter.Value",
      "--output text"
    ]))) : null
  }
}

output "rds_mysql" {
  description = "MySQL RDS connection details and password retrieval helper (if created)"
  value = {
    host               = var.create_mysql_rds ? try(aws_db_instance.mysql[0].address, null) : null
    port               = var.create_mysql_rds ? try(aws_db_instance.mysql[0].port, null) : null
    database           = var.create_mysql_rds ? local.mysql_db_name_value : null
    username           = var.create_mysql_rds ? local.mysql_db_username_value : null
    password_parameter = var.create_mysql_rds ? local.mysql_db_password_parameter_name : null
    password_get_command = var.create_mysql_rds ? trimspace(join(" ", compact([
      "aws ssm get-parameter",
      "--with-decryption",
      "--name ${local.mysql_db_password_parameter_name}",
      var.aws_profile != null ? "--profile ${var.aws_profile}" : null,
      var.region != null ? "--region ${var.region}" : null,
      "--query Parameter.Value",
      "--output text"
    ]))) : null
  }
}

output "initial_credentials" {
  description = "Initial admin credentials (user/password SSM) for selected services. Passwords are stored in SSM SecureString."
  sensitive   = true
  value = {
    zulip = {
      username     = null
      password_ssm = null
    }
    exastro_web = {
      username     = null
      password_ssm = null
    }
    exastro_api = {
      username     = null
      password_ssm = null
    }
    odoo = {
      username     = var.create_ecs && var.create_odoo ? "admin" : null
      password_ssm = var.create_ecs && var.create_odoo ? local.odoo_admin_password_parameter_name : null
    }
    keycloak = {
      username_ssm = var.create_ecs && var.create_keycloak ? local.keycloak_admin_username_parameter_name : null
      password_ssm = var.create_ecs && var.create_keycloak ? local.keycloak_admin_password_parameter_name : null
    }
    n8n = {
      username     = null
      password_ssm = null
    }
    gitlab = {
      username     = null
      password_ssm = null
    }
    pgadmin = {
      username     = var.create_ecs && var.create_pgadmin ? "admin@${local.hosted_zone_name_input}" : null
      password_ssm = var.create_ecs && var.create_pgadmin ? local.pgadmin_default_password_parameter_name : null
    }
    phpmyadmin = {
      username     = null
      password_ssm = null
    }
    orangehrm = {
      username_ssm = var.create_ecs && var.create_orangehrm ? local.orangehrm_admin_username_parameter_name : null
      password_ssm = var.create_ecs && var.create_orangehrm ? local.orangehrm_admin_password_parameter_name : null
    }
  }
}

output "service_admin_info" {
  description = "Initial admin URLs and credential pointers per service (password values are not exposed; console links point to SSM SecureString entries)"
  value = {
    n8n = {
      admin_url                  = var.create_ecs && var.create_n8n ? "https://${local.n8n_host}/" : null
      admin_username             = null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "Create the first workspace user on initial visit; no default admin credentials are stored."
    }
    zulip = {
      admin_url                  = var.create_ecs && var.create_zulip ? "https://${local.zulip_host}/" : null
      admin_username             = null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "Create the first Zulip organization admin during initial signup; no default admin credentials are stored."
    }
    exastro_web = {
      admin_url                  = var.create_ecs && var.create_exastro_web_server ? "https://${local.exastro_web_host}/" : null
      admin_username             = null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "Exastro ITA web UI; default credentials are managed externally (not stored in Terraform)."
    }
    exastro_api = {
      admin_url                  = var.create_ecs && var.create_exastro_api_admin ? "https://${local.exastro_api_host}/" : null
      admin_username             = null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "Exastro ITA API admin; credentials/keys are managed externally (not stored in Terraform)."
    }
    keycloak = {
      admin_url                  = var.create_ecs && var.create_keycloak ? "https://${local.keycloak_host}/admin" : null
      admin_username             = var.create_ecs && var.create_keycloak ? var.keycloak_admin_username : null
      admin_username_console_url = local.admin_param_console_urls.keycloak_admin_username
      admin_password_console_url = local.admin_param_console_urls.keycloak_admin_password
      notes                      = "Keycloak Admin Console; username/password are stored in SSM SecureString. Use the console link to view secrets."
    }
    odoo = {
      admin_url                  = var.create_ecs && var.create_odoo ? "https://${local.odoo_host}/web/login" : null
      admin_username             = var.create_ecs && var.create_odoo ? "admin" : null
      admin_username_console_url = null
      admin_password_console_url = local.admin_param_console_urls.odoo_admin_password
      notes                      = "Odoo backend login; the admin password is stored in SSM SecureString. Use the console link to reveal it."
    }
    pgadmin = {
      admin_url                  = var.create_ecs && var.create_pgadmin ? "https://${local.pgadmin_host}/" : null
      admin_username             = var.create_ecs && var.create_pgadmin ? "admin@${local.hosted_zone_name_input}" : null
      admin_username_console_url = null
      admin_password_console_url = local.admin_param_console_urls.pgadmin_default_password
      notes                      = "pgAdmin default user; the password is stored in SSM SecureString. Use the console link to reveal it."
    }
    phpmyadmin = {
      admin_url                  = var.create_ecs && var.create_phpmyadmin ? "https://${local.phpmyadmin_host}/" : null
      admin_username             = null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "phpMyAdmin does not create a default application login; sign in with your database credentials. The blowfish secret is stored in SSM at ${local.phpmyadmin_blowfish_secret_parameter_name}."
    }
    gitlab = {
      admin_url                  = var.create_ecs && var.create_gitlab ? "https://${local.gitlab_host}/users/sign_in" : null
      admin_username             = var.create_ecs && var.create_gitlab ? "root" : null
      admin_username_console_url = null
      admin_password_console_url = null
      notes                      = "GitLab initial root password is generated on first start and written to /etc/gitlab/initial_root_password and container logs; not stored in SSM."
    }
  }
}
