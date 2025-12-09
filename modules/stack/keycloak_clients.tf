locals {
  keycloak_base_url_raw = coalesce(
    var.keycloak_base_url,
    local.hosted_zone_name_input != null ? "https://keycloak.${local.hosted_zone_name_input}" : null
  )
  keycloak_base_url_normalized = local.keycloak_base_url_raw != null ? trimspace(local.keycloak_base_url_raw) : null
  keycloak_base_url_effective = local.keycloak_base_url_normalized != null && local.keycloak_base_url_normalized != "" ? (
    can(regex("^https?://", local.keycloak_base_url_normalized)) ? local.keycloak_base_url_normalized : "https://${local.keycloak_base_url_normalized}"
  ) : null
  keycloak_admin_username_effective = coalesce(local.keycloak_admin_username_value, var.keycloak_admin_username)
  keycloak_admin_password_for_management = try(coalesce(
    var.keycloak_admin_password,
    try(local.keycloak_admin_params_from_ssm[local.keycloak_admin_password_parameter_name], null)
  ), null)
  manage_keycloak_clients_effective = var.manage_keycloak_clients && var.create_ecs && var.create_keycloak && local.ssm_writes_enabled && local.keycloak_base_url_effective != null && local.keycloak_admin_password_for_management != null
  keycloak_admin_password_effective = local.keycloak_admin_password_value
}

locals {
  keycloak_client_definitions = local.manage_keycloak_clients_effective ? {
    n8n = {
      enabled       = var.enable_n8n_keycloak && var.create_n8n
      host          = local.n8n_host
      redirect_uris = ["https://${local.n8n_host}/*"]
      web_origins   = ["https://${local.n8n_host}"]
      root_url      = "https://${local.n8n_host}"
      display_name  = "n8n"
    }
    zulip = {
      enabled       = var.enable_zulip_keycloak && var.create_zulip
      host          = local.zulip_host
      redirect_uris = ["https://${local.zulip_host}/*"]
      web_origins   = ["https://${local.zulip_host}"]
      root_url      = "https://${local.zulip_host}"
      display_name  = "zulip"
    }
    "exastro-web" = {
      enabled       = var.enable_exastro_web_keycloak && var.create_exastro_web_server
      host          = local.exastro_web_host
      redirect_uris = ["https://${local.exastro_web_host}/*"]
      web_origins   = ["https://${local.exastro_web_host}"]
      root_url      = "https://${local.exastro_web_host}"
      display_name  = "exastro-web"
    }
    "exastro-api" = {
      enabled       = var.enable_exastro_api_keycloak && var.create_exastro_api_admin
      host          = local.exastro_api_host
      redirect_uris = ["https://${local.exastro_api_host}/*"]
      web_origins   = ["https://${local.exastro_api_host}"]
      root_url      = "https://${local.exastro_api_host}"
      display_name  = "exastro-api"
    }
    growi = {
      enabled       = var.enable_growi_keycloak && var.create_growi
      host          = local.growi_host
      redirect_uris = ["https://${local.growi_host}/_api/v3/auth/oidc/callback"]
      web_origins   = ["https://${local.growi_host}"]
      root_url      = "https://${local.growi_host}"
      display_name  = "growi"
    }
    "cmdbuild-r2u" = {
      enabled       = var.enable_cmdbuild_r2u_keycloak && var.create_cmdbuild_r2u
      host          = local.cmdbuild_r2u_host
      redirect_uris = ["https://${local.cmdbuild_r2u_host}/*"]
      web_origins   = ["https://${local.cmdbuild_r2u_host}"]
      root_url      = "https://${local.cmdbuild_r2u_host}"
      display_name  = "cmdbuild-r2u"
    }
    orangehrm = {
      enabled       = var.enable_orangehrm_keycloak && var.create_orangehrm
      host          = local.orangehrm_host
      redirect_uris = ["https://${local.orangehrm_host}/*"]
      web_origins   = ["https://${local.orangehrm_host}"]
      root_url      = "https://${local.orangehrm_host}"
      display_name  = "orangehrm"
    }
    odoo = {
      enabled       = var.create_odoo && var.enable_odoo_keycloak
      host          = local.odoo_host
      redirect_uris = ["https://${local.odoo_host}/auth_oauth/signin"]
      web_origins   = ["https://${local.odoo_host}"]
      root_url      = "https://${local.odoo_host}"
      display_name  = "odoo"
    }
    gitlab = {
      enabled       = var.create_gitlab && var.enable_gitlab_keycloak
      host          = local.gitlab_host
      redirect_uris = ["https://${local.gitlab_host}/users/auth/openid_connect/callback"]
      web_origins   = ["https://${local.gitlab_host}"]
      root_url      = "https://${local.gitlab_host}"
      display_name  = "gitlab"
    }
    pgadmin = {
      enabled       = var.create_pgadmin && var.enable_pgadmin_keycloak
      host          = local.pgadmin_host
      redirect_uris = ["https://${local.pgadmin_host}/*"]
      web_origins   = ["https://${local.pgadmin_host}"]
      root_url      = "https://${local.pgadmin_host}"
      display_name  = "pgadmin"
    }
  } : {}

  keycloak_client_definitions_enabled = {
    for name, cfg in local.keycloak_client_definitions :
    name => cfg if cfg.enabled && cfg.host != null
  }
}

provider "keycloak" {
  alias          = "management"
  client_id      = "admin-cli"
  username       = local.keycloak_admin_username_effective
  password       = local.keycloak_admin_password_for_management
  url            = coalesce(local.keycloak_base_url_effective, "https://example.invalid")
  realm          = local.keycloak_realm
  base_path      = ""
  client_timeout = 30
  initial_login  = local.manage_keycloak_clients_effective
}

# Create clients only when management is enabled; provider initial_login above prevents failures during bootstrap.
module "keycloak_clients_manager" {
  source = "./keycloak_clients_manager"
  count  = local.manage_keycloak_clients_effective ? 1 : 0

  providers = {
    keycloak.management = keycloak.management
  }

  keycloak_base_url  = local.keycloak_base_url_effective
  keycloak_realm     = local.keycloak_realm
  admin_username     = local.keycloak_admin_username_effective
  admin_password     = local.keycloak_admin_password_for_management
  client_definitions = local.keycloak_client_definitions_enabled

  depends_on = [
    aws_ecs_service.keycloak
  ]
}

locals {
  # Managed clients are only populated when manage_keycloak_clients_effective is true; keep as map for safe lookups.
  keycloak_managed_clients = local.manage_keycloak_clients_effective ? tomap(module.keycloak_clients_manager[0].managed_clients) : tomap({})
}
