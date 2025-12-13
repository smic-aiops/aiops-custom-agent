locals {
  account_id = data.aws_caller_identity.current.account_id
  enabled_services = var.create_ecs ? compact([
    var.create_n8n ? "n8n" : "",
    var.create_exastro_web_server ? "exastro-web" : "",
    var.create_exastro_api_admin ? "exastro-api" : "",
    var.create_sulu ? "sulu" : "",
    var.create_keycloak ? "keycloak" : "",
    var.create_odoo ? "odoo" : "",
    var.create_pgadmin ? "pgadmin" : "",
    var.create_phpmyadmin ? "phpmyadmin" : "",
    var.create_gitlab ? "gitlab" : "",
    var.create_growi ? "growi" : "",
    var.create_cmdbuild_r2u ? "cmdbuild-r2u" : "",
    var.create_orangehrm ? "orangehrm" : "",
    var.create_zulip ? "zulip" : ""
  ]) : []
  ecr_uri_n8n              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_n8n}:latest"
  ecr_uri_exastro_web      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_web_server}:latest"
  ecr_uri_exastro_api      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_api_admin}:latest"
  sulu_image_tag_effective = var.sulu_image_tag != null && var.sulu_image_tag != "" ? var.sulu_image_tag : "latest"
  ecr_uri_sulu             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_sulu}:${local.sulu_image_tag_effective}"
  ecr_uri_sulu_nginx       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_sulu_nginx}:${local.sulu_image_tag_effective}"
  ecr_uri_pgadmin          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_pgadmin}:latest"
  ecr_uri_phpmyadmin       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_phpmyadmin}:latest"
  ecr_uri_keycloak         = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_keycloak}:latest"
  ecr_uri_odoo             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_odoo}:latest"
  ecr_uri_gitlab           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_gitlab}:latest"
  ecr_uri_growi            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_growi}:latest"
  ecr_uri_cmdbuild_r2u     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_cmdbuild_r2u}:latest"
  ecr_uri_orangehrm        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_orangehrm}:latest"
  ecr_uri_zulip            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_zulip}:latest"
  keycloak_realm           = "master"
  keycloak_issuer_url      = "https://keycloak.${local.hosted_zone_name_input}/realms/${local.keycloak_realm}"
  keycloak_auth_url        = "${local.keycloak_issuer_url}/protocol/openid-connect/auth"
  keycloak_token_url       = "${local.keycloak_issuer_url}/protocol/openid-connect/token"
  keycloak_userinfo_url    = "${local.keycloak_issuer_url}/protocol/openid-connect/userinfo"
  default_ssm_params_n8n = {
    DB_USER            = local.n8n_db_username_parameter_name
    DB_PASSWORD        = local.n8n_db_password_parameter_name
    DB_HOST            = local.db_host_parameter_name
    DB_PORT            = local.db_port_parameter_name
    DB_NAME            = local.n8n_db_name_parameter_name
    N8N_ENCRYPTION_KEY = "/${local.name_prefix}/n8n/encryption_key"
  }
  optional_smtp_params_n8n = local.n8n_smtp_username_value != null && local.n8n_smtp_password_value != null ? {
    N8N_SMTP_USER = local.n8n_smtp_username_parameter_name
    N8N_SMTP_PASS = local.n8n_smtp_password_parameter_name
  } : {}
  default_ssm_params_exastro = {
    DB_HOST     = local.db_host_parameter_name
    DB_PORT     = local.db_port_parameter_name
    DB_DATABASE = local.oase_db_name_parameter_name
    DB_USER     = local.oase_db_username_parameter_name
    DB_PASSWORD = local.oase_db_password_parameter_name
  }
  # Prefer user-supplied filesystem IDs only when they are non-null/non-empty; otherwise fall back to the discovered/created EFS IDs.
  n8n_efs_id = (
    var.n8n_filesystem_id != null && var.n8n_filesystem_id != "" ? var.n8n_filesystem_id :
    try(local.n8n_filesystem_id_effective, null)
  )
  sulu_efs_id = (
    var.sulu_filesystem_id != null && var.sulu_filesystem_id != "" ? var.sulu_filesystem_id :
    try(local.sulu_filesystem_id_effective, null)
  )
  zulip_efs_id = (
    var.zulip_filesystem_id != null && var.zulip_filesystem_id != "" ? var.zulip_filesystem_id :
    try(local.zulip_filesystem_id_effective, null)
  )
  pgadmin_efs_id = (
    var.pgadmin_filesystem_id != null && var.pgadmin_filesystem_id != "" ? var.pgadmin_filesystem_id :
    try(local.pgadmin_filesystem_id_effective, null)
  )
  exastro_efs_id = (
    var.exastro_filesystem_id != null && var.exastro_filesystem_id != "" ? var.exastro_filesystem_id :
    try(local.exastro_filesystem_id_effective, null)
  )
  keycloak_efs_id      = try(local.keycloak_filesystem_id_effective, null)
  odoo_efs_id          = try(local.odoo_filesystem_id_effective, null)
  gitlab_data_efs_id   = local.gitlab_data_filesystem_id_effective
  gitlab_config_efs_id = local.gitlab_config_filesystem_id_effective
  growi_efs_id         = try(local.growi_filesystem_id_effective, null)
  orangehrm_efs_id     = try(local.orangehrm_filesystem_id_effective, null)
  cmdbuild_r2u_efs_id  = try(local.cmdbuild_r2u_filesystem_id_effective, null)
  default_environment_n8n = {
    N8N_SMTP_SENDER         = "no-reply@${local.hosted_zone_name_input}"
    N8N_SMTP_HOST           = "email-smtp.${var.region}.amazonaws.com"
    N8N_SMTP_PORT           = "587"
    N8N_SMTP_SSL            = "false"
    N8N_HOST                = "n8n.${local.hosted_zone_name_input}"
    N8N_PORT                = "5678"
    N8N_PROTOCOL            = "https"
    N8N_EDITOR_BASE_URL     = "https://n8n.${local.hosted_zone_name_input}/"
    N8N_PUBLIC_API_BASE_URL = "https://n8n.${local.hosted_zone_name_input}/"
    N8N_METRICS             = "true"
    GENERIC_TIMEZONE        = "Asia/Tokyo"
  }
  default_environment_keycloak = {
    KC_PROXY                            = "edge"
    KC_PROXY_HEADERS                    = "xforwarded"
    KC_HTTP_ENABLED                     = "true"
    KC_HTTP_MANAGEMENT_ENABLED          = "true"
    KC_HTTP_MANAGEMENT_PORT             = "9000"
    KC_HOSTNAME                         = "keycloak.${local.hosted_zone_name_input}"
    KC_HOSTNAME_STRICT                  = "false"
    KC_HOSTNAME_STRICT_HTTPS            = "true"
    KEYCLOAK_FRONTEND_URL               = "https://keycloak.${local.hosted_zone_name_input}/realms/master/"
    KC_METRICS_ENABLED                  = "false"
    KC_HEALTH_ENABLED                   = "true"
    KC_DB                               = "postgres"
    KC_SPI_EMAIL_SMTP_HOST              = "email-smtp.${var.region}.amazonaws.com"
    KC_SPI_EMAIL_SMTP_PORT              = "587"
    KC_SPI_EMAIL_SMTP_FROM              = "no-reply@${local.hosted_zone_name_input}"
    KC_SPI_EMAIL_SMTP_FROM_DISPLAY_NAME = "Keycloak"
    KC_SPI_EMAIL_SMTP_AUTH              = "true"
    KC_SPI_EMAIL_SMTP_STARTTLS          = "true"
    KEYCLOAK_IMPORT                     = "${var.keycloak_filesystem_path}/import/realm-ja.json"
    KEYCLOAK_IMPORT_STRATEGY            = "IGNORE_EXISTING"
    TZ                                  = "Asia/Tokyo"
    LANG                                = "ja_JP.UTF-8"
    LANGUAGE                            = "ja_JP:ja"
    LC_ALL                              = "ja_JP.UTF-8"
  }
  default_environment_odoo = {
    DB_SSLMODE             = "require"
    PGSSLMODE              = "require"
    PROXY_MODE             = "True"
    SMTP_SERVER            = "email-smtp.${var.region}.amazonaws.com"
    SMTP_PORT              = "587"
    ODOO_OIDC_ISSUER       = "https://keycloak.${local.hosted_zone_name_input}/realms/master"
    ODOO_OIDC_REDIRECT_URI = "https://odoo.${local.hosted_zone_name_input}/auth_oauth/signin"
    ODOO_OIDC_SCOPES       = "openid profile email"
    ODOO_ADDONS_PATH       = "/usr/lib/python3/dist-packages/odoo/addons,${var.odoo_filesystem_path}/extra-addons"
    TZ                     = "Asia/Tokyo"
    LANG                   = "ja_JP.UTF-8"
    LC_ALL                 = "ja_JP.UTF-8"
  }
  # pgAdmin expects PGADMIN_CONFIG_* values as valid Python literals; quote strings so config_distro.py parses correctly.
  default_environment_pgadmin = {
    PGADMIN_DEFAULT_EMAIL                  = "admin@${local.hosted_zone_name_input}"
    PGADMIN_CONFIG_AUTHENTICATION_SOURCES  = jsonencode(["oauth2"])
    PGADMIN_CONFIG_OAUTH2_AUTO_CREATE_USER = "True"
    PGADMIN_CONFIG_DEFAULT_LANGUAGE        = jsonencode("ja")
    PGADMIN_CONFIG_MAIL_SERVER             = jsonencode("email-smtp.${var.region}.amazonaws.com")
    PGADMIN_CONFIG_MAIL_PORT               = "587"
    PGADMIN_CONFIG_MAIL_USE_SSL            = "False"
    PGADMIN_CONFIG_MAIL_USE_TLS            = "True"
    PGADMIN_CONFIG_MAIL_DEFAULT_SENDER     = jsonencode("admin@${local.hosted_zone_name_input}")
    PGADMIN_CONFIG_OAUTH2_CONFIG = jsonencode([
      {
        OAUTH2_NAME                = "keycloak"
        OAUTH2_DISPLAY_NAME        = "Keycloak"
        OAUTH2_CLIENT_ID           = "$${PGADMIN_OIDC_CLIENT_ID}"
        OAUTH2_CLIENT_SECRET       = "$${PGADMIN_OIDC_CLIENT_SECRET}"
        OAUTH2_SERVER_METADATA_URL = "https://keycloak.${local.hosted_zone_name_input}/realms/master/.well-known/openid-configuration"
        OAUTH2_AUTHORIZATION_URL   = "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/auth"
        OAUTH2_TOKEN_URL           = "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/token"
        OAUTH2_API_BASE_URL        = "https://keycloak.${local.hosted_zone_name_input}/realms/master"
        OAUTH2_USERINFO_ENDPOINT   = "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/userinfo"
        OAUTH2_SCOPE               = "openid email profile"
        OAUTH2_USERNAME_CLAIM      = "preferred_username"
        OAUTH2_ICON                = "fa-key"
        OAUTH2_BUTTON_COLOR        = "#2C4F9E"
      }
    ])
  }
  default_environment_phpmyadmin = {
    PMA_ABSOLUTE_URI = "https://phpmyadmin.${local.hosted_zone_name_input}/"
    PMA_ARBITRARY    = "1"
    UPLOAD_LIMIT     = "64M"
    TZ               = "Asia/Tokyo"
  }
  default_environment_gitlab = {
    GITLAB_OMNIBUS_CONFIG = <<-EOT
      external_url 'https://gitlab.${local.hosted_zone_name_input}'
      postgresql['enable'] = false
      nginx['listen_port'] = 80
      nginx['listen_https'] = false
      nginx['redirect_http_to_https'] = false
      letsencrypt['enable'] = false
      gitlab_rails['time_zone'] = 'Asia/Tokyo'
      gitlab_rails['db_adapter'] = 'postgresql'
      gitlab_rails['db_encoding'] = 'unicode'
      gitlab_rails['db_host'] = ENV['GITLAB_DB_HOST']
      gitlab_rails['db_port'] = (ENV['GITLAB_DB_PORT'] || '5432')
      gitlab_rails['db_username'] = ENV['GITLAB_DB_USER']
      gitlab_rails['db_password'] = ENV['GITLAB_DB_PASSWORD']
      gitlab_rails['db_database'] = ENV['GITLAB_DB_NAME']
      gitlab_rails['db_sslmode'] = 'require'
      gitlab_rails['gitlab_email_from'] = "gitlab@${local.hosted_zone_name_input}"
      gitlab_rails['gitlab_email_display_name'] = 'GitLab'
      gitlab_rails['gitlab_email_reply_to'] = "noreply@${local.hosted_zone_name_input}"
      gitlab_rails['smtp_enable'] = true
      gitlab_rails['smtp_address'] = "email-smtp.${var.region}.amazonaws.com"
      gitlab_rails['smtp_port'] = 587
      gitlab_rails['smtp_domain'] = '${local.hosted_zone_name_input}'
      gitlab_rails['smtp_authentication'] = 'login'
      gitlab_rails['smtp_enable_starttls_auto'] = true
      gitlab_rails['smtp_tls'] = false
      gitlab_rails['smtp_user_name'] = ENV['GITLAB_SMTP_USER'] if ENV['GITLAB_SMTP_USER']
      gitlab_rails['smtp_password'] = ENV['GITLAB_SMTP_PASS'] if ENV['GITLAB_SMTP_PASS']
      # Honor TLS termination at ALB
      nginx['custom_nginx_config'] = "proxy_set_header X-Forwarded-Proto https;"

      gitlab_rails['omniauth_enabled'] = true
      gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']
      gitlab_rails['omniauth_block_auto_created_users'] = false
      gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']
      gitlab_rails['omniauth_providers'] = [
        {
          name: 'openid_connect',
          label: 'Keycloak',
          args: {
            name: 'openid_connect',
            scope: ['openid','profile','email'],
            response_type: 'code',
            issuer: 'https://keycloak.${local.hosted_zone_name_input}/realms/master',
            discovery: true,
            client_auth_method: 'basic',
            uid_field: 'preferred_username',
            client_id: ENV['GITLAB_OIDC_CLIENT_ID'],
            client_secret: ENV['GITLAB_OIDC_CLIENT_SECRET'],
            redirect_uri: 'https://gitlab.${local.hosted_zone_name_input}/users/auth/openid_connect/callback'
          }
        }
      ]
    EOT
  }
  default_environment_growi = {
    PORT                = "3000"
    APP_PORT            = "3000"
    NODE_ENV            = "production"
    FILE_UPLOAD         = "local"
    FORCE_WWW           = "false"
    PORT0               = "3000"
    PUBLIC_URL          = "https://growi.${local.hosted_zone_name_input}"
    MAILER_ENABLED      = "true"
    MAILER_SMTP_HOST    = "email-smtp.${var.region}.amazonaws.com"
    MAILER_SMTP_PORT    = "587"
    MAILER_FROM         = "no-reply@${local.hosted_zone_name_input}"
    MAILER_SMTP_SECURE  = "false"
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/rds-combined-ca-bundle.pem"
  }
  default_environment_cmdbuild_r2u = {
    CMDBUILD_DUMP          = "ready2use"
    CMDBUILD_SMTP_SERVER   = "email-smtp.${var.region}.amazonaws.com"
    CMDBUILD_SMTP_PORT     = "587"
    CMDBUILD_SMTP_STARTTLS = "true"
    CMDBUILD_EMAIL_FROM    = "no-reply@${local.hosted_zone_name_input}"
    JAVA_OPTS              = "-Duser.language=ja -Duser.country=JP -Duser.timezone=Asia/Tokyo"
  }
  default_environment_orangehrm = {
    NAMI_LOG_LEVEL             = "info"
    ALLOW_EMPTY_PASSWORD       = "no"
    BITNAMI_DEBUG              = "false"
    ORANGEHRM_HTTP_PORT_NUMBER = "8080"
    ORANGEHRM_USERNAME         = var.orangehrm_admin_username
    ORANGEHRM_EMAIL            = "admin@${local.hosted_zone_name_input}"
    ORANGEHRM_SMTP_HOST        = "email-smtp.${var.region}.amazonaws.com"
    ORANGEHRM_SMTP_PORT_NUMBER = "587"
    ORANGEHRM_SMTP_PROTOCOL    = "tls"
    ORANGEHRM_SMTP_AUTH        = "true"
    TZ                         = "Asia/Tokyo"
  }
  default_environment_zulip = {
    SETTINGS_FLAVOR                      = "production"
    SETTING_EXTERNAL_HOST                = local.zulip_host
    SETTING_EMAIL_HOST                   = "email-smtp.${var.region}.amazonaws.com"
    SETTING_EMAIL_PORT                   = "587"
    SETTING_EMAIL_USE_TLS                = "True"
    SETTING_EMAIL_USE_SSL                = "False"
    SETTING_NOREPLY_EMAIL_ADDRESS        = "noreply@${local.hosted_zone_name_input}"
    SETTING_ZULIP_ADMINISTRATOR          = "admin@${local.hosted_zone_name_input}"
    ZULIP_EXTERNAL_HOST                  = local.zulip_host
    EXTERNAL_HOST                        = local.zulip_host
    ZULIP_ADMINISTRATOR                  = "admin@${local.hosted_zone_name_input}"
    DISABLE_HTTPS                        = "true"
    SSL_CERTIFICATE_GENERATION           = "false"
    ZULIP_SETTING_TIME_ZONE              = "Asia/Tokyo"
    ZULIP_SETTING_DEFAULT_LANGUAGE       = "ja"
    RABBITMQ_HOST                        = "127.0.0.1"
    SETTING_RABBITMQ_HOST                = "127.0.0.1"
    RABBITMQ_PORT                        = "5672"
    SETTING_RABBITMQ_PORT                = "5672"
    REDIS_HOST                           = "127.0.0.1"
    SETTING_REDIS_HOST                   = "127.0.0.1"
    REDIS_PORT                           = "6379"
    SETTING_REDIS_PORT                   = "6379"
    SECRETS_redis_password               = ""
    SECRETS_rate_limiting_redis_password = ""
    MEMCACHED_HOST                       = "127.0.0.1:11211"
    SETTING_MEMCACHED_LOCATION           = "127.0.0.1:11211"
    OPEN_REALM_CREATION                  = "True"
  }
  zulip_keycloak_environment = var.enable_zulip_keycloak ? {
    ZULIP_AUTH_BACKENDS                                 = "EmailAuthBackend,GenericOpenIdConnectBackend"
    SETTING_SOCIAL_AUTH_OIDC_FULL_NAME_VALIDATED        = var.zulip_oidc_full_name_validated ? "True" : "False"
    SETTING_SOCIAL_AUTH_OIDC_PKCE_ENABLED               = var.zulip_oidc_pkce_enabled ? "True" : "False"
    SETTING_SOCIAL_AUTH_OIDC_PKCE_CODE_CHALLENGE_METHOD = var.zulip_oidc_pkce_code_challenge_method
  } : {}
  default_environment_sulu = {
    APP_ENV                   = "prod"
    DEFAULT_URI               = "https://${local.sulu_host}"
    APP_SHARE_DIR             = var.sulu_share_dir
    SEAL_DSN                  = "loupe:///var/indexes"
    LOCK_DSN                  = "semaphore"
    REDIS_URL                 = "redis://127.0.0.1:6379"
    LOUPE_DSN                 = "loupe:///var/indexes"
    TZ                        = "Asia/Tokyo"
    SULU_ADMIN_EMAIL          = "admin@${local.hosted_zone_name_input}"
    SULU_HOST                 = local.sulu_host
    SULU_KEYCLOAK_HOST        = local.keycloak_host
    SULU_KEYCLOAK_REALM       = local.keycloak_realm
    SULU_SSO_DEFAULT_ROLE_KEY = var.sulu_sso_default_role_key
    SULU_SSO_CLIENT_ID        = ""
    SULU_SSO_CLIENT_SECRET    = ""
  }
  keycloak_env_common = {
    KEYCLOAK_ISSUER_URL   = local.keycloak_issuer_url
    KEYCLOAK_AUTH_URL     = local.keycloak_auth_url
    KEYCLOAK_TOKEN_URL    = local.keycloak_token_url
    KEYCLOAK_USERINFO_URL = local.keycloak_userinfo_url
  }
  exastro_web_keycloak_environment  = var.enable_exastro_web_keycloak ? local.keycloak_env_common : {}
  exastro_api_keycloak_environment  = var.enable_exastro_api_keycloak ? local.keycloak_env_common : {}
  cmdbuild_r2u_keycloak_environment = var.enable_cmdbuild_r2u_keycloak ? local.keycloak_env_common : {}
  orangehrm_keycloak_environment    = var.enable_orangehrm_keycloak ? local.keycloak_env_common : {}
  growi_keycloak_environment = var.enable_growi_keycloak ? {
    OIDC_ENABLED                = "true"
    OIDC_PROVIDER_NAME          = "Keycloak"
    OIDC_ISSUER                 = local.keycloak_issuer_url
    OIDC_AUTHORIZATION_ENDPOINT = local.keycloak_auth_url
    OIDC_TOKEN_ENDPOINT         = local.keycloak_token_url
    OIDC_USERINFO_ENDPOINT      = local.keycloak_userinfo_url
    OIDC_SCOPES                 = "openid email profile"
    OIDC_REDIRECT_URI           = "https://growi.${local.hosted_zone_name_input}/_api/v3/auth/oidc/callback"
  } : {}
  default_ssm_params_keycloak = {
    KC_DB_URL               = local.keycloak_db_url_parameter_name
    KC_DB_HOST              = local.keycloak_db_host_parameter_name
    KC_DB_PORT              = local.keycloak_db_port_parameter_name
    KC_DB_NAME              = local.keycloak_db_name_parameter_name
    KC_DB_USERNAME          = local.keycloak_db_username_parameter_name
    KC_DB_PASSWORD          = local.keycloak_db_password_parameter_name
    KEYCLOAK_ADMIN          = local.keycloak_admin_username_parameter_name
    KEYCLOAK_ADMIN_PASSWORD = local.keycloak_admin_password_parameter_name
  }
  default_ssm_params_odoo = {
    DB_HOST        = local.db_host_parameter_name
    DB_PORT        = local.db_port_parameter_name
    HOST           = local.db_host_parameter_name
    PORT           = local.db_port_parameter_name
    DB_USER        = local.odoo_db_username_parameter_name
    DB_PASSWORD    = local.odoo_db_password_parameter_name
    USER           = local.odoo_db_username_parameter_name
    PASSWORD       = local.odoo_db_password_parameter_name
    DB_NAME        = local.odoo_db_name_parameter_name
    ADMIN_PASSWORD = local.odoo_admin_password_parameter_name
  }
  default_ssm_params_pgadmin = {
    PGADMIN_DEFAULT_PASSWORD = local.pgadmin_default_password_parameter_name
  }
  default_ssm_params_phpmyadmin = {
    PMA_BLOWFISH_SECRET = local.phpmyadmin_blowfish_secret_parameter_name
  }
  default_ssm_params_gitlab = {
    GITLAB_DB_HOST     = local.gitlab_db_host_parameter_name
    GITLAB_DB_PORT     = local.gitlab_db_port_parameter_name
    GITLAB_DB_NAME     = local.gitlab_db_name_parameter_name
    GITLAB_DB_USER     = local.gitlab_db_username_parameter_name
    GITLAB_DB_PASSWORD = local.gitlab_db_password_parameter_name
  }
  default_ssm_params_growi = {
    MONGO_URI = local.growi_mongo_uri_parameter_name
  }
  default_ssm_params_cmdbuild_r2u = {
    POSTGRES_HOST     = local.cmdbuild_r2u_db_host_parameter_name
    POSTGRES_PORT     = local.cmdbuild_r2u_db_port_parameter_name
    POSTGRES_DB       = local.cmdbuild_r2u_db_name_parameter_name
    POSTGRES_USER     = local.cmdbuild_r2u_db_username_parameter_name
    POSTGRES_PASSWORD = local.cmdbuild_r2u_db_password_parameter_name
  }
  default_ssm_params_orangehrm = {
    MARIADB_HOST                = local.mysql_db_host_parameter_name
    MARIADB_PORT_NUMBER         = local.mysql_db_port_parameter_name
    ORANGEHRM_DATABASE_NAME     = local.mysql_db_name_parameter_name
    ORANGEHRM_DATABASE_USER     = local.mysql_db_username_parameter_name
    ORANGEHRM_DATABASE_PASSWORD = local.mysql_db_password_parameter_name
  }
  default_ssm_params_zulip_base = {
    DB_HOST                   = local.db_host_parameter_name
    DB_PORT                   = local.db_port_parameter_name
    DB_HOST_PORT              = local.db_port_parameter_name
    DB_NAME                   = local.zulip_db_name_parameter_name
    DB_USER                   = local.zulip_db_username_parameter_name
    DB_PASSWORD               = local.zulip_db_password_parameter_name
    SECRETS_postgres_password = local.zulip_db_password_parameter_name
    RABBITMQ_USERNAME         = local.zulip_mq_username_parameter_name
    SETTING_RABBITMQ_USER     = local.zulip_mq_username_parameter_name
    RABBITMQ_PASSWORD         = local.zulip_mq_password_parameter_name
    SECRETS_rabbitmq_password = local.zulip_mq_password_parameter_name
    SECRET_KEY                = local.zulip_secret_key_parameter_name
    SECRETS_secret_key        = local.zulip_secret_key_parameter_name
  }
  default_ssm_params_zulip_oidc = var.enable_zulip_keycloak ? {
    OIDC_CLIENT_ID                        = local.zulip_oidc_client_id_parameter_name
    OIDC_CLIENT_SECRET                    = local.zulip_oidc_client_secret_parameter_name
    SETTING_SOCIAL_AUTH_OIDC_ENABLED_IDPS = local.zulip_oidc_idps_parameter_name
    SECRETS_social_auth_oidc_secret       = local.zulip_oidc_client_secret_parameter_name
  } : {}
  optional_smtp_params_keycloak = merge(
    local.keycloak_smtp_username_value != null ? { KC_SPI_EMAIL_SMTP_USER = local.keycloak_smtp_username_parameter_name } : {},
    local.keycloak_smtp_password_value != null ? { KC_SPI_EMAIL_SMTP_PASSWORD = local.keycloak_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_zulip = merge(
    local.zulip_smtp_username_value != null ? { SETTING_EMAIL_HOST_USER = local.zulip_smtp_username_parameter_name } : {},
    local.zulip_smtp_password_value != null ? { SECRETS_email_password = local.zulip_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_odoo = merge(
    local.odoo_smtp_username_value != null ? { SMTP_USER = local.odoo_smtp_username_parameter_name } : {},
    local.odoo_smtp_password_value != null ? { SMTP_PASSWORD = local.odoo_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_gitlab = merge(
    local.gitlab_smtp_username_value != null ? { GITLAB_SMTP_USER = local.gitlab_smtp_username_parameter_name } : {},
    local.gitlab_smtp_password_value != null ? { GITLAB_SMTP_PASS = local.gitlab_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_pgadmin = merge(
    local.pgadmin_smtp_username_value != null ? { PGADMIN_CONFIG_MAIL_USERNAME = local.pgadmin_smtp_username_parameter_name } : {},
    local.pgadmin_smtp_password_value != null ? { PGADMIN_CONFIG_MAIL_PASSWORD = local.pgadmin_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_growi = merge(
    local.growi_smtp_username_value != null ? { MAILER_SMTP_USER = local.growi_smtp_username_parameter_name } : {},
    local.growi_smtp_password_value != null ? { MAILER_SMTP_PASSWORD = local.growi_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_cmdbuild_r2u = merge(
    local.cmdbuild_smtp_username_value != null ? { CMDBUILD_SMTP_USERNAME = local.cmdbuild_smtp_username_parameter_name } : {},
    local.cmdbuild_smtp_password_value != null ? { CMDBUILD_SMTP_PASSWORD = local.cmdbuild_smtp_password_parameter_name } : {}
  )
  optional_smtp_params_orangehrm = merge(
    local.orangehrm_smtp_username_value != null ? { ORANGEHRM_SMTP_USER = local.orangehrm_smtp_username_parameter_name } : {},
    local.orangehrm_smtp_password_value != null ? { ORANGEHRM_SMTP_PASSWORD = local.orangehrm_smtp_password_parameter_name } : {}
  )
  optional_oidc_params_odoo = var.enable_odoo_keycloak && local.odoo_oidc_client_id_value != null && local.odoo_oidc_client_secret_value != null ? {
    ODOO_OIDC_CLIENT_ID     = local.odoo_oidc_client_id_parameter_name
    ODOO_OIDC_CLIENT_SECRET = local.odoo_oidc_client_secret_parameter_name
  } : {}
  optional_oidc_params_gitlab = var.enable_gitlab_keycloak && local.gitlab_oidc_client_id_value != null && local.gitlab_oidc_client_secret_value != null ? {
    GITLAB_OIDC_CLIENT_ID     = local.gitlab_oidc_client_id_parameter_name
    GITLAB_OIDC_CLIENT_SECRET = local.gitlab_oidc_client_secret_parameter_name
  } : {}
  optional_oidc_params_pgadmin = var.enable_pgadmin_keycloak && local.pgadmin_oidc_client_id_value != null && local.pgadmin_oidc_client_secret_value != null ? {
    PGADMIN_OIDC_CLIENT_ID     = local.pgadmin_oidc_client_id_parameter_name
    PGADMIN_OIDC_CLIENT_SECRET = local.pgadmin_oidc_client_secret_parameter_name
  } : {}
}

resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset(local.enabled_services)

  name              = "/aws/ecs/${local.name_prefix}-${each.key}"
  retention_in_days = var.ecs_logs_retention_days

  tags = merge(local.tags, { Name = "${local.name_prefix}-${each.key}-logs" })
}

locals {
  ssm_param_arns_n8n          = { for k, v in merge(local.default_ssm_params_n8n, var.n8n_db_ssm_params, var.n8n_ssm_params, local.optional_smtp_params_n8n) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_exastro_web  = { for k, v in merge(local.default_ssm_params_exastro, var.exastro_web_server_ssm_params) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_exastro_api  = { for k, v in merge(local.default_ssm_params_exastro, var.exastro_api_admin_ssm_params) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_pgadmin      = { for k, v in merge(local.default_ssm_params_pgadmin, var.pgadmin_ssm_params, local.optional_smtp_params_pgadmin, local.optional_oidc_params_pgadmin) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_phpmyadmin   = { for k, v in merge(local.default_ssm_params_phpmyadmin, var.phpmyadmin_ssm_params) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_keycloak     = { for k, v in merge(local.default_ssm_params_keycloak, var.keycloak_db_ssm_params, var.keycloak_ssm_params, local.optional_smtp_params_keycloak) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_odoo         = { for k, v in merge(local.default_ssm_params_odoo, var.odoo_ssm_params, local.optional_smtp_params_odoo, local.optional_oidc_params_odoo) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_gitlab       = { for k, v in merge(local.default_ssm_params_gitlab, var.gitlab_db_ssm_params, var.gitlab_ssm_params, local.optional_smtp_params_gitlab, local.optional_oidc_params_gitlab) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_growi        = { for k, v in merge(local.default_ssm_params_growi, var.growi_ssm_params, local.optional_smtp_params_growi) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_cmdbuild_r2u = { for k, v in merge(local.default_ssm_params_cmdbuild_r2u, var.cmdbuild_r2u_ssm_params, local.optional_smtp_params_cmdbuild_r2u) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_orangehrm    = { for k, v in merge(local.default_ssm_params_orangehrm, var.orangehrm_ssm_params, local.optional_smtp_params_orangehrm) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_zulip        = { for k, v in merge(local.default_ssm_params_zulip_base, local.default_ssm_params_zulip_oidc, var.zulip_db_ssm_params, var.zulip_ssm_params, local.optional_smtp_params_zulip) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  sulu_ssm_core_params = {
    APP_SECRET   = local.sulu_app_secret_parameter_name
    DATABASE_URL = local.sulu_database_url_parameter_name
    MAILER_DSN   = local.sulu_mailer_dsn_parameter_name
  }
  sulu_ssm_oidc_params = var.enable_sulu_keycloak ? {
    SULU_SSO_CLIENT_ID     = local.sulu_oidc_client_id_parameter_name
    SULU_SSO_CLIENT_SECRET = local.sulu_oidc_client_secret_parameter_name
  } : {}
  ssm_param_arns_sulu = { for k, v in merge(local.sulu_ssm_core_params, local.sulu_ssm_oidc_params) : k => (can(regex("^arn:aws:ssm", v)) ? v : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}") }
  ssm_param_arns_exastro_web_oidc = var.enable_exastro_web_keycloak ? { for k, v in {
    KEYCLOAK_CLIENT_ID     = local.exastro_web_oidc_client_id_parameter_name
    KEYCLOAK_CLIENT_SECRET = local.exastro_web_oidc_client_secret_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" } : {}
  ssm_param_arns_exastro_api_oidc = var.enable_exastro_api_keycloak ? { for k, v in {
    KEYCLOAK_CLIENT_ID     = local.exastro_api_oidc_client_id_parameter_name
    KEYCLOAK_CLIENT_SECRET = local.exastro_api_oidc_client_secret_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" } : {}
  ssm_param_arns_growi_oidc = var.enable_growi_keycloak ? { for k, v in {
    OIDC_CLIENT_ID     = local.growi_oidc_client_id_parameter_name
    OIDC_CLIENT_SECRET = local.growi_oidc_client_secret_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" } : {}
  ssm_param_arns_cmdbuild_r2u_oidc = var.enable_cmdbuild_r2u_keycloak ? { for k, v in {
    KEYCLOAK_CLIENT_ID     = local.cmdbuild_r2u_oidc_client_id_parameter_name
    KEYCLOAK_CLIENT_SECRET = local.cmdbuild_r2u_oidc_client_secret_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" } : {}
  ssm_param_arns_orangehrm_oidc = var.enable_orangehrm_keycloak ? { for k, v in {
    KEYCLOAK_CLIENT_ID     = local.orangehrm_oidc_client_id_parameter_name
    KEYCLOAK_CLIENT_SECRET = local.orangehrm_oidc_client_secret_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" } : {}
  db_ssm_param_arns = { for k, v in {
    DB_ADMIN_USER     = local.db_username_parameter_name
    DB_ADMIN_PASSWORD = local.db_password_parameter_name
    DB_HOST           = local.db_host_parameter_name
    DB_PORT           = local.db_port_parameter_name
  } : k => "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}" }
}

locals {
  pgadmin_secret_names = toset(concat(
    [for s in var.pgadmin_secrets : s.name],
    keys(local.ssm_param_arns_pgadmin)
  ))

  # Auto-quote PGADMIN_CONFIG_* plain strings so pgAdmin's config_distro.py stays valid Python.
  pgadmin_environment_effective = {
    for k, v in merge(local.default_environment_pgadmin, coalesce(var.pgadmin_environment, {})) :
    k => (
      startswith(k, "PGADMIN_CONFIG_") &&
      !can(regex("^\\s*['\"\\[{]", v)) &&
      !can(regex("^(True|False|None)$", v)) &&
      !can(regex("^[-+]?\\d+(\\.\\d+)?$", v))
      ? jsonencode(v) : v
    ) if !contains(local.pgadmin_secret_names, k)
  }

  phpmyadmin_secret_names = toset(concat(
    [for s in var.phpmyadmin_secrets : s.name],
    keys(local.ssm_param_arns_phpmyadmin)
  ))

  phpmyadmin_environment_effective = {
    for k, v in merge(local.default_environment_phpmyadmin, var.phpmyadmin_environment) :
    k => v if !contains(local.phpmyadmin_secret_names, k)
  }
}

locals {
  odoo_var_secrets_map       = { for s in var.odoo_secrets : s.name => (can(regex("^arn:aws:ssm", s.valueFrom)) ? s.valueFrom : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(s.valueFrom, "/") ? s.valueFrom : "/${s.valueFrom}"}") }
  gitlab_var_secrets_map     = { for s in var.gitlab_secrets : s.name => (can(regex("^arn:aws:ssm", s.valueFrom)) ? s.valueFrom : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(s.valueFrom, "/") ? s.valueFrom : "/${s.valueFrom}"}") }
  pgadmin_var_secrets_map    = { for s in var.pgadmin_secrets : s.name => (can(regex("^arn:aws:ssm", s.valueFrom)) ? s.valueFrom : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(s.valueFrom, "/") ? s.valueFrom : "/${s.valueFrom}"}") }
  phpmyadmin_var_secrets_map = { for s in var.phpmyadmin_secrets : s.name => (can(regex("^arn:aws:ssm", s.valueFrom)) ? s.valueFrom : "arn:aws:ssm:${var.region}:${local.account_id}:parameter${startswith(s.valueFrom, "/") ? s.valueFrom : "/${s.valueFrom}"}") }

  odoo_secrets_effective = [
    for name, value in merge(local.odoo_var_secrets_map, local.ssm_param_arns_odoo) : {
      name      = name
      valueFrom = value
    }
  ]
  gitlab_secrets_effective = [
    for name, value in merge(local.gitlab_var_secrets_map, local.ssm_param_arns_gitlab) : {
      name      = name
      valueFrom = value
    }
  ]
  pgadmin_secrets_effective = [
    for name, value in merge(local.pgadmin_var_secrets_map, local.ssm_param_arns_pgadmin) : {
      name      = name
      valueFrom = value
    }
  ]
  phpmyadmin_secrets_effective = [
    for name, value in merge(local.phpmyadmin_var_secrets_map, local.ssm_param_arns_phpmyadmin) : {
      name      = name
      valueFrom = value
    }
  ]
}

locals {
  ecs_base_container = {
    cpu       = 0
    memory    = null
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = ""
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
}

resource "aws_ecs_task_definition" "n8n" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  family                   = "${local.name_prefix}-n8n"
  cpu                      = coalesce(var.n8n_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.n8n_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.n8n_efs_id != null ? [1] : []
    content {
      name = "n8n-data"
      efs_volume_configuration {
        file_system_id     = local.n8n_efs_id
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
    local.n8n_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "n8n-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.n8n_filesystem_path}"
            chown -R 1000:1000 "${var.n8n_filesystem_path}"
          EOT
        ]
        mountPoints = [
          {
            sourceVolume  = "n8n-data"
            containerPath = var.n8n_filesystem_path
            readOnly      = false
          }
        ]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["n8n"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "n8n-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            echo "Installing PostgreSQL client (15.x) to match RDS 15.x..."
            apk add --no-cache postgresql15-client >/dev/null

            db_host="$${DB_HOST:-}"
            db_port="$${DB_PORT:-5432}"
            db_user="$${DB_USER:-}"
            db_pass="$${DB_PASSWORD:-}"
            db_name="$${DB_NAME:-}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            export PGPASSWORD="$${db_pass}"

            echo "Waiting for PostgreSQL to become available..."
            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 2
            done

            role_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname = '$${db_user}'" || true)"
            if [ "$${role_exists}" != "1" ]; then
              echo "Creating role $${db_user}..."
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE ROLE \"$${db_user}\" WITH LOGIN PASSWORD '$${db_pass}';" || true
            fi

            db_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$${db_name}'" || true)"
            if [ "$${db_exists}" != "1" ]; then
              echo "Creating database $${db_name}..."
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE DATABASE \"$${db_name}\" OWNER \"$${db_user}\";"
            else
              echo "Database $${db_name} already exists."
            fi
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_n8n : { name = k, valueFrom = v }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["n8n"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "n8n"
        image = local.ecr_uri_n8n
        user  = "1000:1000"
        portMappings = [{
          containerPort = 5678
          hostPort      = 5678
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(local.default_environment_n8n, var.n8n_environment) : { name = k, value = v }]
        secrets = concat(
          var.n8n_secrets,
          [for k, v in local.ssm_param_arns_n8n : { name = k, valueFrom = v }]
        )
        entryPoint = [var.n8n_shell_path, "-c"]
        command = [
          <<-EOT
            set -eu

            if ! command -v psql >/dev/null 2>&1; then
              echo "psql client not found in image; aborting startup."
              exit 1
            fi

            db_host="$${DB_HOST:-}"
            db_port="$${DB_PORT:-5432}"
            db_user="$${DB_USER:-}"
            db_name="$${DB_NAME:-}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_name}" ] || [ -z "$${DB_PASSWORD:-}" ]; then
              echo "Database connection variables are not fully defined; aborting startup."
              exit 1
            fi

            export PGPASSWORD="$${DB_PASSWORD}"

            echo "Waiting for PostgreSQL to become available..."
            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 3
            done

            n8n_bin="$(command -v n8n || true)"
            if [ -z "$${n8n_bin}" ]; then
              echo "n8n binary not found in PATH; aborting."
              exit 1
            fi

            exec "$${n8n_bin}" start
          EOT
        ]
        mountPoints = local.n8n_efs_id != null ? [
          {
            sourceVolume  = "n8n-data"
            containerPath = var.n8n_filesystem_path
            readOnly      = false
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["n8n"].name
          })
        })
        dependsOn = concat(
          local.n8n_efs_id != null ? [
            {
              containerName = "n8n-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "n8n-db-init"
              condition     = "COMPLETE"
            }
          ]
        )
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-td" })
}

resource "aws_ecs_task_definition" "exastro_web" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  family                   = "${local.name_prefix}-exastro-web"
  cpu                      = coalesce(var.exastro_web_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.exastro_web_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = [1]
    content {
      name = "exastro-storage"
      dynamic "efs_volume_configuration" {
        for_each = local.exastro_efs_id != null ? [1] : []
        content {
          file_system_id     = local.exastro_efs_id
          root_directory     = "/"
          transit_encryption = "ENABLED"
          authorization_config {
            access_point_id = null
            iam             = "DISABLED"
          }
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.exastro_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "exastro-web-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.exastro_filesystem_path}"
            chown -R 1000:1000 "${var.exastro_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "exastro-storage"
          containerPath = var.exastro_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["exastro-web"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name  = "exastro-web"
        image = local.ecr_uri_exastro_web
        user  = "1000:1000"
        portMappings = [{
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(var.exastro_web_server_environment, local.exastro_web_keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.exastro_web_server_secrets,
          [for k, v in local.ssm_param_arns_exastro_web : { name = k, valueFrom = v }],
          var.enable_exastro_web_keycloak ? [for k, v in local.ssm_param_arns_exastro_web_oidc : { name = k, valueFrom = v }] : []
        )
        mountPoints = local.exastro_efs_id != null ? [
          {
            sourceVolume  = "exastro-storage"
            containerPath = var.exastro_filesystem_path
            readOnly      = false
          }
        ] : []
        dependsOn = local.exastro_efs_id != null ? [
          {
            containerName = "exastro-web-fs-init"
            condition     = "COMPLETE"
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["exastro-web"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-td" })
}

resource "aws_ecs_task_definition" "exastro_api_admin" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  family                   = "${local.name_prefix}-exastro-api"
  cpu                      = coalesce(var.exastro_api_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.exastro_api_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = [1]
    content {
      name = "exastro-storage"
      dynamic "efs_volume_configuration" {
        for_each = local.exastro_efs_id != null ? [1] : []
        content {
          file_system_id     = local.exastro_efs_id
          root_directory     = "/"
          transit_encryption = "ENABLED"
          authorization_config {
            access_point_id = null
            iam             = "DISABLED"
          }
        }
      }
    }
  }

  container_definitions = jsonencode(concat(
    local.exastro_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "exastro-api-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.exastro_filesystem_path}"
            chown -R 1000:1000 "${var.exastro_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "exastro-storage"
          containerPath = var.exastro_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["exastro-api"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name  = "exastro-api"
        image = local.ecr_uri_exastro_api
        user  = "1000:1000"
        portMappings = [{
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(var.exastro_api_admin_environment, local.exastro_api_keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.exastro_api_admin_secrets,
          [for k, v in local.ssm_param_arns_exastro_api : { name = k, valueFrom = v }],
          var.enable_exastro_api_keycloak ? [for k, v in local.ssm_param_arns_exastro_api_oidc : { name = k, valueFrom = v }] : []
        )
        mountPoints = local.exastro_efs_id != null ? [
          {
            sourceVolume  = "exastro-storage"
            containerPath = var.exastro_filesystem_path
            readOnly      = false
          }
        ] : []
        dependsOn = local.exastro_efs_id != null ? [
          {
            containerName = "exastro-api-fs-init"
            condition     = "COMPLETE"
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["exastro-api"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-td" })
}

resource "aws_ecs_task_definition" "sulu" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  family                   = "${local.name_prefix}-sulu"
  cpu                      = coalesce(var.sulu_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.sulu_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.sulu_efs_id != null ? [1] : []
    content {
      name = "sulu-share"
      efs_volume_configuration {
        file_system_id     = local.sulu_efs_id
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
    local.sulu_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "sulu-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.sulu_filesystem_path}"
            chown -R 33:33 "${var.sulu_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "sulu-share"
          containerPath = var.sulu_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["sulu"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name      = "redis"
        image     = "redis:7-alpine"
        essential = true
        portMappings = [{
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }]
        healthCheck = {
          command     = ["CMD-SHELL", "redis-cli ping | grep PONG"]
          interval    = 10
          timeout     = 5
          retries     = 5
          startPeriod = 10
        }
        mountPoints = local.sulu_efs_id != null ? [
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_filesystem_path
            readOnly      = false
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs["sulu"].name
            "awslogs-stream-prefix" = "redis"
          })
        })
      }),
      merge(local.ecs_base_container, {
        name      = "loupe-indexer"
        image     = "public.ecr.aws/docker/library/alpine:3.20"
        essential = false
        command   = ["sh", "-c", "sleep infinity"]
        mountPoints = local.sulu_efs_id != null ? [
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_filesystem_path
            readOnly      = false
          },
          {
            sourceVolume  = "sulu-share"
            containerPath = "/var/indexes"
            readOnly      = false
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs["sulu"].name
            "awslogs-stream-prefix" = "loupe"
          })
        })
      }),
      merge(local.ecs_base_container, {
        name       = "init-db"
        image      = local.ecr_uri_sulu
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command    = ["/app/docker/init-db.sh"]
        environment = [
          {
            name  = "APP_ENV"
            value = "prod"
          },
          {
            name  = "REDIS_URL"
            value = "redis://127.0.0.1:6379"
          },
          {
            name  = "LOUPE_DSN"
            value = "loupe:///var/indexes"
          }
        ]
        secrets = concat(
          var.sulu_secrets,
          [for k, v in local.ssm_param_arns_sulu : { name = k, valueFrom = v }]
        )
        mountPoints = local.sulu_efs_id != null ? [
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_filesystem_path
            readOnly      = false
          },
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_share_dir
            readOnly      = false
          },
          {
            sourceVolume  = "sulu-share"
            containerPath = "/var/www/html/var/indexes"
            readOnly      = false
          }
        ] : []
        dependsOn = concat(
          local.sulu_efs_id != null ? [
            {
              containerName = "sulu-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "redis"
              condition     = "HEALTHY"
            },
            {
              containerName = "loupe-indexer"
              condition     = "START"
            }
          ]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs["sulu"].name
            "awslogs-stream-prefix" = "init-db"
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "php-fpm"
        image = local.ecr_uri_sulu
        user  = "0:0"
        portMappings = [{
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }]
        environment = [
          for k, v in merge(local.default_environment_sulu, coalesce(var.sulu_environment, {})) :
          {
            name  = k
            value = v
          }
        ]
        secrets = concat(
          var.sulu_secrets,
          [for k, v in local.ssm_param_arns_sulu : { name = k, valueFrom = v }]
        )
        mountPoints = local.sulu_efs_id != null ? [
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_filesystem_path
            readOnly      = false
          },
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_share_dir
            readOnly      = false
          },
          {
            sourceVolume  = "sulu-share"
            containerPath = "/var/www/html/var/indexes"
            readOnly      = false
          }
        ] : []
        dependsOn = concat(
          local.sulu_efs_id != null ? [
            {
              containerName = "sulu-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "init-db"
              condition     = "SUCCESS"
            },
            {
              containerName = "redis"
              condition     = "HEALTHY"
            },
            {
              containerName = "loupe-indexer"
              condition     = "START"
            }
          ]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs["sulu"].name
            "awslogs-stream-prefix" = "php"
          })
        })
      }),
      merge(local.ecs_base_container, {
        name      = "nginx"
        image     = local.ecr_uri_sulu_nginx
        essential = true
        portMappings = [{
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }]
        mountPoints = local.sulu_efs_id != null ? [
          {
            sourceVolume  = "sulu-share"
            containerPath = var.sulu_share_dir
            readOnly      = false
          }
        ] : []
        dependsOn = [
          {
            containerName = "php-fpm"
            condition     = "START"
          }
        ]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group"         = aws_cloudwatch_log_group.ecs["sulu"].name
            "awslogs-stream-prefix" = "nginx"
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-sulu-td" })
}

resource "aws_ecs_task_definition" "keycloak" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  family                   = "${local.name_prefix}-keycloak"
  cpu                      = coalesce(var.keycloak_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.keycloak_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.keycloak_efs_id != null ? [1] : []
    content {
      name = "keycloak-data"
      efs_volume_configuration {
        file_system_id     = local.keycloak_efs_id
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
    local.keycloak_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "keycloak-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.keycloak_filesystem_path}/tmp"
            chown -R 1000:0 "${var.keycloak_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "keycloak-data"
          containerPath = var.keycloak_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["keycloak"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "keycloak-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            apk add --no-cache postgresql15-client >/dev/null

            db_host="$${KC_DB_HOST:-}"
            db_port="$${KC_DB_PORT:-5432}"
            db_user="$${KC_DB_USERNAME:-}"
            db_pass="$${KC_DB_PASSWORD:-}"
            db_name="$${KC_DB_NAME:-keycloak}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            export PGPASSWORD="$${db_pass}"

            echo "Waiting for PostgreSQL to become available..."
            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 2
            done

            role_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname = '$${db_user}'" || true)"
            if [ "$${role_exists}" != "1" ]; then
              echo "Creating role $${db_user}..."
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE ROLE \"$${db_user}\" WITH LOGIN PASSWORD '$${db_pass}';" || true
            fi

            db_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$${db_name}'" || true)"
            if [ "$${db_exists}" != "1" ]; then
              echo "Creating database $${db_name}..."
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE DATABASE \"$${db_name}\" OWNER \"$${db_user}\";"
            else
              echo "Database $${db_name} already exists."
            fi
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_keycloak : { name = k, valueFrom = v }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["keycloak"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name       = "keycloak-realm-import"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            import_dir="${var.keycloak_filesystem_path}/import"
            mkdir -p "$${import_dir}"
            cat > "$${import_dir}/realm-ja.json" <<'JSON'
{
  "realm": "master",
  "enabled": true,
  "internationalizationEnabled": true,
  "defaultLocale": "ja",
  "supportedLocales": ["ja", "en"],
  "smtpServer": {
    "auth": "true",
    "from": "no-reply@${local.hosted_zone_name_input}",
    "fromDisplayName": "Keycloak",
    "host": "email-smtp.${var.region}.amazonaws.com",
    "port": "587",
    "replyTo": "no-reply@${local.hosted_zone_name_input}",
    "replyToDisplayName": "Keycloak",
    "starttls": "true",
    "ssl": "false"
  }
}
JSON
            chown -R 1000:0 "$${import_dir}"
          EOT
        ]
        mountPoints = local.keycloak_efs_id != null ? [{
          sourceVolume  = "keycloak-data"
          containerPath = var.keycloak_filesystem_path
          readOnly      = false
        }] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["keycloak"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name    = "keycloak"
        image   = local.ecr_uri_keycloak
        user    = "1000:0"
        command = ["start"]
        portMappings = [{
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          }, {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(local.default_environment_keycloak, var.keycloak_environment) : { name = k, value = v }]
        secrets = concat(
          var.keycloak_secrets,
          [for k, v in local.ssm_param_arns_keycloak : { name = k, valueFrom = v }]
        )
        mountPoints = local.keycloak_efs_id != null ? [{
          sourceVolume  = "keycloak-data"
          containerPath = var.keycloak_filesystem_path
          readOnly      = false
        }] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["keycloak"].name
          })
        })
        dependsOn = concat(
          local.keycloak_efs_id != null ? [
            {
              containerName = "keycloak-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [
            {
              containerName = "keycloak-db-init"
              condition     = "COMPLETE"
            },
            {
              containerName = "keycloak-realm-import"
              condition     = "COMPLETE"
            }
          ]
        )
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-td" })
}

resource "aws_ecs_task_definition" "odoo" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  family                   = "${local.name_prefix}-odoo"
  cpu                      = coalesce(var.odoo_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.odoo_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.odoo_efs_id != null ? [1] : []
    content {
      name = "odoo-data"
      efs_volume_configuration {
        file_system_id     = local.odoo_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    merge(local.ecs_base_container, {
      name       = "odoo-db-init"
      image      = "public.ecr.aws/docker/library/alpine:3.19"
      essential  = false
      entryPoint = ["/bin/sh", "-c"]
      command = [
        <<-EOT
          set -eu
          apk add --no-cache postgresql15-client >/dev/null

          db_host="$${ODOO_DB_HOST:-$${DB_HOST:-$${HOST:-}}}"
          db_port="$${ODOO_DB_PORT:-$${DB_PORT:-$${PORT:-5432}}}"
          db_admin="$${DB_ADMIN_USER:-$${USER:-}}"
          db_admin_pass="$${DB_ADMIN_PASSWORD:-$${DB_PASSWORD:-$${PASSWORD:-}}}"
          db_user="$${ODOO_DB_USER:-$${DB_USER:-$${USER:-}}}"
          db_pass="$${ODOO_DB_PASSWORD:-$${DB_PASSWORD:-$${PASSWORD:-}}}"
          db_name="$${ODOO_DB_NAME:-$${DB_NAME:-$${DATABASE:-}}}"

          if [ -z "$${db_admin}" ]; then
            db_admin="$${db_user}"
          fi
          if [ -z "$${db_admin_pass}" ]; then
            db_admin_pass="$${db_pass}"
          fi

          if [ -z "$${db_host}" ] || [ -z "$${db_admin}" ] || [ -z "$${db_admin_pass}" ] || [ -z "$${db_name}" ]; then
            echo "Database variables are incomplete."
            exit 1
          fi

          export PGPASSWORD="$${db_admin_pass}"

          echo "Waiting for PostgreSQL to become available..."
          until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" >/dev/null 2>&1; do
            sleep 2
          done

          role_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" -d postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname = '$${db_user}'" || true)"
          if [ "$${role_exists}" != "1" ] && [ -n "$${db_user}" ] && [ -n "$${db_pass}" ]; then
            echo "Creating role $${db_user} with the provided password..."
            psql -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" -d postgres -c "CREATE ROLE \"$${db_user}\" WITH LOGIN PASSWORD '$${db_pass}';" || true
            role_exists="1"
          fi

          if [ "$${role_exists}" == "1" ] && [ -n "$${db_user}" ] && [ -n "$${db_pass}" ]; then
            echo "Ensuring password for role $${db_user} is up to date..."
            psql -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" -d postgres -c "ALTER ROLE \"$${db_user}\" WITH LOGIN PASSWORD '$${db_pass}';" || true
          fi

          owner="$${db_user}"
          if [ -z "$${db_user}" ] || [ "$${role_exists}" != "1" ]; then
            echo "Role $${db_user:-<empty>} not found. Using admin user $${db_admin} as owner."
            owner="$${db_admin}"
          fi

          db_exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$${db_name}'" || true)"
          if [ "$${db_exists}" != "1" ]; then
            echo "Creating database $${db_name} owned by $${owner}..."
            psql -h "$${db_host}" -p "$${db_port}" -U "$${db_admin}" -d postgres -c "CREATE DATABASE \"$${db_name}\" OWNER \"$${owner}\";"
          else
            echo "Database $${db_name} already exists."
          fi

          mkdir -p "${var.odoo_filesystem_path}/.local/share/Odoo"
          mkdir -p "${var.odoo_filesystem_path}/extra-addons"
          chown -R 101:101 "${var.odoo_filesystem_path}"
        EOT
      ]
      # Avoid duplicate secret names (e.g., DB_HOST) by merging the maps first.
      secrets = [for k, v in merge(local.db_ssm_param_arns, local.ssm_param_arns_odoo) : { name = k, valueFrom = v }]
      mountPoints = local.odoo_efs_id != null ? [{
        sourceVolume  = "odoo-data"
        containerPath = var.odoo_filesystem_path
        readOnly      = false
      }] : []
      logConfiguration = merge(local.ecs_base_container.logConfiguration, {
        options = merge(local.ecs_base_container.logConfiguration.options, {
          "awslogs-group" = aws_cloudwatch_log_group.ecs["odoo"].name
        })
      })
    }),
    merge(local.ecs_base_container, {
      name  = "odoo"
      image = local.ecr_uri_odoo
      user  = "101:101"
      portMappings = [{
        containerPort = 8069
        hostPort      = 8069
        protocol      = "tcp"
      }]
      mountPoints = local.odoo_efs_id != null ? [{
        sourceVolume  = "odoo-data"
        containerPath = var.odoo_filesystem_path
        readOnly      = false
      }] : []
      environment = [for k, v in merge(local.default_environment_odoo, var.odoo_environment) : { name = k, value = v }]
      secrets     = local.odoo_secrets_effective
      logConfiguration = merge(local.ecs_base_container.logConfiguration, {
        options = merge(local.ecs_base_container.logConfiguration.options, {
          "awslogs-group" = aws_cloudwatch_log_group.ecs["odoo"].name
        })
      })
      dependsOn = [
        {
          containerName = "odoo-db-init"
          condition     = "COMPLETE"
        }
      ]
    })
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-td" })
}

resource "aws_ecs_task_definition" "gitlab" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  family                   = "${local.name_prefix}-gitlab"
  cpu                      = var.gitlab_task_cpu
  memory                   = var.gitlab_task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.gitlab_data_efs_id != null ? [1] : []
    content {
      name = "gitlab-data"
      efs_volume_configuration {
        file_system_id     = local.gitlab_data_efs_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = null
          iam             = "DISABLED"
        }
      }
    }
  }

  dynamic "volume" {
    for_each = local.gitlab_config_efs_id != null ? [1] : []
    content {
      name = "gitlab-config"
      efs_volume_configuration {
        file_system_id     = local.gitlab_config_efs_id
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
    (local.gitlab_data_efs_id != null || local.gitlab_config_efs_id != null) ? [
      merge(local.ecs_base_container, {
        name       = "gitlab-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            if [ -d "${var.gitlab_data_filesystem_path}" ]; then
              chown -R 998:998 "${var.gitlab_data_filesystem_path}"
            fi
            if [ -d "${var.gitlab_config_mount_base}" ]; then
              chown -R 998:998 "${var.gitlab_config_mount_base}"
            fi
          EOT
        ]
        mountPoints = concat(
          local.gitlab_data_efs_id != null ? [{
            sourceVolume  = "gitlab-data"
            containerPath = var.gitlab_data_filesystem_path
            readOnly      = false
          }] : [],
          local.gitlab_config_efs_id != null ? [{
            sourceVolume  = "gitlab-config"
            containerPath = var.gitlab_config_mount_base
            readOnly      = false
          }] : []
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["gitlab"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name       = "gitlab-db-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            apk add --no-cache postgresql15-client >/dev/null

            db_host="$${GITLAB_DB_HOST:-}"
            db_port="$${GITLAB_DB_PORT:-5432}"
            db_user="$${GITLAB_DB_USER:-}"
            db_pass="$${GITLAB_DB_PASSWORD:-}"
            db_name="$${GITLAB_DB_NAME:-gitlabhq_production}"

            if [ -z "$${db_host}" ] || [ -z "$${db_user}" ] || [ -z "$${db_pass}" ] || [ -z "$${db_name}" ]; then
              echo "Database variables are incomplete."
              exit 1
            fi

            export PGPASSWORD="$${db_pass}"

            echo "Waiting for PostgreSQL $${db_host}:$${db_port} ..."
            until pg_isready -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" >/dev/null 2>&1; do
              sleep 3
            done

            exists="$(psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$${db_name}'" || true)"
            if [ "$${exists}" != "1" ]; then
              echo "Creating database $${db_name} owned by $${db_user}..."
              psql -h "$${db_host}" -p "$${db_port}" -U "$${db_user}" -d postgres -c "CREATE DATABASE \"$${db_name}\" OWNER \"$${db_user}\";"
            else
              echo "Database $${db_name} already exists."
            fi
          EOT
        ]
        secrets = [for k, v in local.ssm_param_arns_gitlab : { name = k, valueFrom = v }]
        mountPoints = concat(
          local.gitlab_data_efs_id != null ? [{
            sourceVolume  = "gitlab-data"
            containerPath = var.gitlab_data_filesystem_path
            readOnly      = false
          }] : [],
          local.gitlab_config_efs_id != null ? concat(
            [{
              sourceVolume  = "gitlab-config"
              containerPath = var.gitlab_config_mount_base
              readOnly      = false
            }],
            [for p in var.gitlab_config_bind_paths : {
              sourceVolume  = "gitlab-config"
              containerPath = p
              readOnly      = false
            }]
          ) : []
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["gitlab"].name
          })
        })
      }),
      merge(local.ecs_base_container, {
        name  = "gitlab"
        image = local.ecr_uri_gitlab
        portMappings = [{
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }]
        environment = [for k, v in merge(local.default_environment_gitlab, var.gitlab_environment) : { name = k, value = v }]
        secrets     = local.gitlab_secrets_effective
        mountPoints = concat(
          local.gitlab_data_efs_id != null ? [{
            sourceVolume  = "gitlab-data"
            containerPath = var.gitlab_data_filesystem_path
            readOnly      = false
          }] : [],
          local.gitlab_config_efs_id != null ? concat(
            [{
              sourceVolume  = "gitlab-config"
              containerPath = var.gitlab_config_mount_base
              readOnly      = false
            }],
            [for p in var.gitlab_config_bind_paths : {
              sourceVolume  = "gitlab-config"
              containerPath = p
              readOnly      = false
            }]
          ) : []
        )
        dependsOn = concat(
          (local.gitlab_data_efs_id != null || local.gitlab_config_efs_id != null) ? [
            {
              containerName = "gitlab-fs-init"
              condition     = "COMPLETE"
            }
          ] : [],
          [{
            condition     = "SUCCESS"
            containerName = "gitlab-db-init"
          }]
        )
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["gitlab"].name
          })
        })
      })
    ]
  ))

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-td" })
}

resource "aws_ecs_task_definition" "pgadmin" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  family                   = "${local.name_prefix}-pgadmin"
  cpu                      = coalesce(var.pgadmin_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.pgadmin_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  dynamic "volume" {
    for_each = local.pgadmin_efs_id != null ? [1] : []
    content {
      name = "pgadmin-data"
      efs_volume_configuration {
        file_system_id     = local.pgadmin_efs_id
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
    local.pgadmin_efs_id != null ? [
      merge(local.ecs_base_container, {
        name       = "pgadmin-fs-init"
        image      = "public.ecr.aws/docker/library/alpine:3.19"
        essential  = false
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -eu
            mkdir -p "${var.pgadmin_filesystem_path}"
            chown -R 5050:5050 "${var.pgadmin_filesystem_path}"
          EOT
        ]
        mountPoints = [{
          sourceVolume  = "pgadmin-data"
          containerPath = var.pgadmin_filesystem_path
          readOnly      = false
        }]
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["pgadmin"].name
          })
        })
      })
    ] : [],
    [
      merge(local.ecs_base_container, {
        name  = "pgadmin"
        image = local.ecr_uri_pgadmin
        user  = "5050:5050"
        portMappings = [{
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }]
        entryPoint = ["/bin/sh", "-c"]
        command = [
          <<-EOT
            set -euo pipefail

            if [ -n "$${PGADMIN_OIDC_CLIENT_ID:-}" ] && [ -n "$${PGADMIN_OIDC_CLIENT_SECRET:-}" ]; then
              export PGADMIN_CONFIG_OAUTH2_CONFIG="$(python - <<'PY'
            import json
            import os

            cfg = {
                "OAUTH2_NAME": "keycloak",
                "OAUTH2_DISPLAY_NAME": "Keycloak",
                "OAUTH2_CLIENT_ID": os.environ["PGADMIN_OIDC_CLIENT_ID"],
                "OAUTH2_CLIENT_SECRET": os.environ["PGADMIN_OIDC_CLIENT_SECRET"],
                "OAUTH2_SERVER_METADATA_URL": "https://keycloak.${local.hosted_zone_name_input}/realms/master/.well-known/openid-configuration",
                "OAUTH2_AUTHORIZATION_URL": "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/auth",
                "OAUTH2_TOKEN_URL": "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/token",
                "OAUTH2_API_BASE_URL": "https://keycloak.${local.hosted_zone_name_input}/realms/master",
                "OAUTH2_USERINFO_ENDPOINT": "https://keycloak.${local.hosted_zone_name_input}/realms/master/protocol/openid-connect/userinfo",
                "OAUTH2_SCOPE": "openid email profile",
                "OAUTH2_USERNAME_CLAIM": "preferred_username",
                "OAUTH2_ICON": "fa-key",
                "OAUTH2_BUTTON_COLOR": "#2C4F9E",
            }

            print(json.dumps([cfg]))
            PY
              )"
            fi

            exec /entrypoint.sh
          EOT
        ]
        mountPoints = local.pgadmin_efs_id != null ? [{
          sourceVolume  = "pgadmin-data"
          containerPath = var.pgadmin_filesystem_path
          readOnly      = false
        }] : []
        environment = [for k, v in local.pgadmin_environment_effective : { name = k, value = v }]
        secrets     = local.pgadmin_secrets_effective
        dependsOn = local.pgadmin_efs_id != null ? [
          {
            containerName = "pgadmin-fs-init"
            condition     = "COMPLETE"
          }
        ] : []
        logConfiguration = merge(local.ecs_base_container.logConfiguration, {
          options = merge(local.ecs_base_container.logConfiguration.options, {
            "awslogs-group" = aws_cloudwatch_log_group.ecs["pgadmin"].name
          })
        })
      })
    ]
  ))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-td" })
}

resource "aws_ecs_task_definition" "phpmyadmin" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  family                   = "${local.name_prefix}-phpmyadmin"
  cpu                      = coalesce(var.phpmyadmin_task_cpu, var.ecs_task_cpu)
  memory                   = coalesce(var.phpmyadmin_task_memory, var.ecs_task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  container_definitions = jsonencode([
    merge(local.ecs_base_container, {
      name  = "phpmyadmin"
      image = local.ecr_uri_phpmyadmin
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      environment = [for k, v in local.phpmyadmin_environment_effective : { name = k, value = v }]
      secrets     = local.phpmyadmin_secrets_effective
      logConfiguration = merge(local.ecs_base_container.logConfiguration, {
        options = merge(local.ecs_base_container.logConfiguration.options, {
          "awslogs-group" = aws_cloudwatch_log_group.ecs["phpmyadmin"].name
        })
      })
    })
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.image_architecture_cpu
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-phpmyadmin-td" })
}
