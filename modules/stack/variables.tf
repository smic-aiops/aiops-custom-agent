variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "platform" {
  description = "Platform or business unit name"
  type        = string
  default     = "aiops"
}

variable "name_prefix" {
  description = "Prefix used for naming resources; defaults to \"<environment>-<platform>\" when null"
  type        = string
  default     = null
}

variable "existing_vpc_id" {
  description = "If set, use this existing VPC instead of creating a new one (e.g., prod-aiops-vpc)"
  type        = string
  default     = null
}

variable "existing_internet_gateway_id" {
  description = "If set, reuse this internet gateway instead of creating a new one"
  type        = string
  default     = null
}

variable "existing_nat_gateway_id" {
  description = "If set, reuse this NAT gateway instead of creating a new one"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "172.24.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets with name, cidr, and az"
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  default = null
}

variable "private_subnets" {
  description = "List of private subnets with name, cidr, and az"
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  default = null
}

variable "efs_prevent_destroy" {
  description = "When true, protect managed EFS file systems from destruction"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "When true, enable deletion protection on RDS instances"
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "When true, skip creating a final snapshot on RDS deletion (PostgreSQL)"
  type        = bool
  default     = true
}

variable "pg_db_username" {
  description = "Master username for the PostgreSQL instance"
  type        = string
  default     = null
}

variable "pg_db_password" {
  description = "Master password for the PostgreSQL instance"
  type        = string
  sensitive   = true
  default     = null
}

variable "n8n_db_password" {
  description = "Database password for n8n (optional, auto-generated if null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_db_password" {
  description = "Database password for Zulip (optional, auto-generated if null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "keycloak_db_username" {
  description = "Database username for Keycloak (defaults to master username when null)"
  type        = string
  default     = null
}

variable "keycloak_db_password" {
  description = "Database password for Keycloak (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password (SecureString in SSM when set; auto-generated when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_db_username" {
  description = "Database username for Odoo (defaults to master username when null)"
  type        = string
  default     = null
}

variable "odoo_db_password" {
  description = "Database password for Odoo (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_admin_password" {
  description = "Odoo admin_passwd value (SecureString in SSM when set; auto-generated when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_db_username" {
  description = "Database username for GitLab (defaults to master username when null)"
  type        = string
  default     = null
}

variable "gitlab_db_password" {
  description = "Database password for GitLab (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_r2u_db_password" {
  description = "Database password for CMDBuild Ready2Use"
  type        = string
  sensitive   = true
  default     = null
}

variable "growi_db_password" {
  description = "Database password for GROWI (DocumentDB)"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_db_password" {
  description = "Database password for OrangeHRM"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_admin_password" {
  description = "Application admin password for OrangeHRM (SecureString in SSM when set; auto-generated when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "oase_db_username" {
  description = "Database username for Exastro OASE (defaults to master username when null)"
  type        = string
  default     = null
}

variable "oase_db_password" {
  description = "Database password for Exastro OASE (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "exastro_pf_db_username" {
  description = "Database username for Exastro ITA Platform DB (defaults to master username when null)"
  type        = string
  default     = null
}

variable "exastro_pf_db_password" {
  description = "Database password for Exastro ITA Platform DB (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "exastro_ita_db_username" {
  description = "Database username for Exastro ITA Application DB (defaults to master username when null)"
  type        = string
  default     = null
}

variable "exastro_ita_db_password" {
  description = "Database password for Exastro ITA Application DB (defaults to master password when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "create_rds" {
  description = "Whether to create/manage the RDS instance"
  type        = bool
  default     = true
}

variable "rds_identifier" {
  description = "Identifier for the RDS instance; defaults to <name_prefix>-pg"
  type        = string
  default     = null
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Max allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.15"
}

variable "rds_backup_retention" {
  description = "Backup retention days"
  type        = number
  default     = 1
}

variable "create_db_credentials_parameters" {
  description = "Create SSM parameters for DB username/password"
  type        = bool
  default     = true
}

variable "db_username_parameter_name" {
  description = "SSM parameter name for DB username; defaults to /<name_prefix>/db/username"
  type        = string
  default     = null
}

variable "db_password_parameter_name" {
  description = "SSM parameter name for DB password; defaults to /<name_prefix>/db/password"
  type        = string
  default     = null
}

variable "hosted_zone_name" {
  description = "Hosted zone name to manage"
  type        = string
  default     = "smic-aiops.jp"
}

variable "keycloak_base_url" {
  description = "Base URL for Keycloak admin endpoint (defaults to https://keycloak.<hosted_zone_name>)"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Existing hosted zone ID to use when hosted_zone_name is not provided"
  type        = string
  default     = null
}

variable "hosted_zone_comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "hosted_zone_force_destroy" {
  description = "Whether to allow deletion of all records when destroying the zone"
  type        = bool
  default     = false
}

variable "hosted_zone_tag_name" {
  description = "Value for Name tag on hosted zone; defaults to hosted_zone_name"
  type        = string
  default     = null
}

variable "create_hosted_zone" {
  description = "Create the hosted zone if not found (set true to create a new public zone)"
  type        = bool
  default     = false
}

variable "control_subdomain" {
  description = "Subdomain for the business-site control UI (e.g., control)"
  type        = string
  default     = "control"
}

variable "service_subdomain_map" {
  description = <<EOF
Overrides for service subdomain prefixes. Keys match the internal service IDs
(e.g., n8n, zulip, gitlab); values are the label prepended to the shared root
hosted zone.
EOF
  type        = map(string)
  default = {
    n8n          = "n8n"
    zulip        = "zulip"
    exastro_web  = "ita-web"
    exastro_api  = "ita-api"
    main_svc     = "main-svc"
    pgadmin      = "pgadmin"
    phpmyadmin   = "phpmyadmin"
    keycloak     = "keycloak"
    odoo         = "odoo"
    gitlab       = "gitlab"
    growi        = "growi"
    cmdbuild_r2u = "cmdbuild"
    orangehrm    = "orangehrm"
  }
}

variable "n8n_filesystem_id" {
  description = "Existing EFS ID to mount for n8n (if not creating new)"
  type        = string
  default     = null
}

variable "n8n_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "zulip_filesystem_id" {
  description = "Existing EFS ID to mount for Zulip (if not creating new)"
  type        = string
  default     = null
}

variable "pgadmin_filesystem_id" {
  description = "Existing EFS ID to mount for pgAdmin (if not creating new)"
  type        = string
  default     = null
}

variable "keycloak_filesystem_id" {
  description = "Existing EFS ID to mount for Keycloak (if not creating new)"
  type        = string
  default     = null
}

variable "odoo_filesystem_id" {
  description = "Existing EFS ID to mount for Odoo (if not creating new)"
  type        = string
  default     = null
}

variable "gitlab_data_filesystem_id" {
  description = "Existing EFS ID to mount for GitLab data (/var/opt/gitlab)"
  type        = string
  default     = null
}

variable "gitlab_config_filesystem_id" {
  description = "Existing EFS ID to mount for GitLab config (/etc/gitlab, /etc/letsencrypt)"
  type        = string
  default     = null
}

variable "exastro_filesystem_id" {
  description = "Existing EFS ID to mount for Exastro IT Automation (if not creating new)"
  type        = string
  default     = null
}

variable "cmdbuild_r2u_filesystem_id" {
  description = "Existing EFS ID to mount for CMDBuild READY2USE (if not creating new)"
  type        = string
  default     = null
}

variable "growi_filesystem_id" {
  description = "Existing EFS ID to mount for GROWI (if not creating new)"
  type        = string
  default     = null
}

variable "orangehrm_filesystem_id" {
  description = "Existing EFS ID to mount for OrangeHRM (if not creating new)"
  type        = string
  default     = null
}

variable "zulip_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "pgadmin_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "keycloak_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "odoo_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "gitlab_data_efs_availability_zone" {
  description = "AZ for GitLab data One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "gitlab_config_efs_availability_zone" {
  description = "AZ for GitLab config One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "exastro_efs_availability_zone" {
  description = "AZ for Exastro One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "cmdbuild_r2u_efs_availability_zone" {
  description = "AZ for CMDBuild READY2USE One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "growi_efs_availability_zone" {
  description = "AZ for GROWI One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "orangehrm_efs_availability_zone" {
  description = "AZ for OrangeHRM One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "create_n8n" {
  description = "Whether to create n8n service resources"
  type        = bool
  default     = true
}

variable "create_zulip" {
  description = "Whether to create Zulip service resources"
  type        = bool
  default     = true
}

variable "create_main_svc" {
  description = "Whether to create main-svc service resources"
  type        = bool
  default     = true
}

variable "create_pgadmin" {
  description = "Whether to create pgAdmin service resources"
  type        = bool
  default     = true
}

variable "create_phpmyadmin" {
  description = "Whether to create phpMyAdmin service resources"
  type        = bool
  default     = true
}

variable "create_keycloak" {
  description = "Whether to create Keycloak service resources"
  type        = bool
  default     = true
}

variable "manage_keycloak_clients" {
  description = "Create/update Keycloak OIDC clients and store their credentials in SSM via Terraform"
  type        = bool
  default     = false
}

variable "create_odoo" {
  description = "Whether to create Odoo service resources"
  type        = bool
  default     = true
}

variable "create_gitlab" {
  description = "Whether to create GitLab Omnibus service resources"
  type        = bool
  default     = true
}

variable "enable_gitlab_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into GitLab task definition"
  type        = bool
  default     = true
}

variable "enable_exastro_web" {
  description = "Flag to enable Exastro web service (tfvars-driven toggle)"
  type        = bool
  default     = false
}

variable "enable_exastro_api" {
  description = "Flag to enable Exastro API service (tfvars-driven toggle)"
  type        = bool
  default     = false
}

variable "enable_cmdbuild_r2u" {
  description = "Flag to enable CMDBuild Ready2Use service (tfvars-driven toggle)"
  type        = bool
  default     = false
}

variable "enable_n8n_autostop" {
  description = "Whether to enable n8n idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_exastro_web_autostop" {
  description = "Whether to enable Exastro web idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_exastro_api_autostop" {
  description = "Whether to enable Exastro API idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "n8n_desired_count" {
  description = "Default desired count for n8n ECS service"
  type        = number
  default     = 1
}

variable "enable_zulip_autostop" {
  description = "Whether to enable Zulip idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = false
}

variable "enable_main_svc_autostop" {
  description = "Whether to enable main-svc idle auto-stop (reserved for future use)"
  type        = bool
  default     = false
}

variable "enable_main_svc_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into main-svc task definition"
  type        = bool
  default     = false
}

variable "zulip_desired_count" {
  description = "Default desired count for Zulip ECS service"
  type        = number
  default     = 1
}

variable "main_svc_desired_count" {
  description = "Default desired count for main-svc ECS service"
  type        = number
  default     = 1
}

variable "exastro_web_server_desired_count" {
  description = "Default desired count for Exastro IT Automation web server ECS service"
  type        = number
  default     = 1
}

variable "exastro_api_admin_desired_count" {
  description = "Default desired count for Exastro IT Automation API admin ECS service"
  type        = number
  default     = 1
}

variable "enable_pgadmin_autostop" {
  description = "Whether to enable pgAdmin idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_phpmyadmin_autostop" {
  description = "Whether to enable phpMyAdmin idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_keycloak_autostop" {
  description = "Whether to enable Keycloak idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = false
}

variable "enable_odoo_autostop" {
  description = "Whether to enable Odoo idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_odoo_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Odoo task definition"
  type        = bool
  default     = true
}

variable "pgadmin_desired_count" {
  description = "Default desired count for pgAdmin ECS service"
  type        = number
  default     = 1
}

variable "phpmyadmin_desired_count" {
  description = "Default desired count for phpMyAdmin ECS service"
  type        = number
  default     = 1
}

variable "enable_pgadmin_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into pgAdmin task definition"
  type        = bool
  default     = true
}

variable "enable_phpmyadmin_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into phpMyAdmin task definition"
  type        = bool
  default     = false
}

variable "keycloak_desired_count" {
  description = "Default desired count for Keycloak ECS service"
  type        = number
  default     = 1
}

variable "odoo_desired_count" {
  description = "Default desired count for Odoo ECS service"
  type        = number
  default     = 1
}

variable "gitlab_desired_count" {
  description = "Default desired count for GitLab ECS service"
  type        = number
  default     = 1
}

variable "enable_gitlab_autostop" {
  description = "Whether to enable GitLab idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_n8n_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into n8n task definition"
  type        = bool
  default     = false
}

variable "n8n_oidc_client_id" {
  description = "Keycloak OIDC client ID for n8n (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "n8n_oidc_client_secret" {
  description = "Keycloak OIDC client secret for n8n (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "n8n_smtp_username" {
  description = "SES SMTP username for n8n (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "n8n_smtp_password" {
  description = "SES SMTP password for n8n (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "keycloak_smtp_username" {
  description = "SES SMTP username for Keycloak (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "keycloak_smtp_password" {
  description = "SES SMTP password for Keycloak (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_smtp_username" {
  description = "SES SMTP username for Odoo (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_smtp_password" {
  description = "SES SMTP password for Odoo (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_smtp_username" {
  description = "SES SMTP username for GitLab (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_smtp_password" {
  description = "SES SMTP password for GitLab (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "pgadmin_smtp_username" {
  description = "SES SMTP username for pgAdmin (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "pgadmin_smtp_password" {
  description = "SES SMTP password for pgAdmin (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "growi_smtp_username" {
  description = "SES SMTP username for GROWI (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "growi_smtp_password" {
  description = "SES SMTP password for GROWI (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_smtp_username" {
  description = "SES SMTP username for CMDBuild R2U (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_smtp_password" {
  description = "SES SMTP password for CMDBuild R2U (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_smtp_username" {
  description = "SES SMTP username for OrangeHRM (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_smtp_password" {
  description = "SES SMTP password for OrangeHRM (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ses_smtp_user_name" {
  description = "SES SMTP IAM user name override (defaults to <name_prefix>-ses-smtp)"
  type        = string
  default     = null
}

variable "ses_smtp_policy_name" {
  description = "SES SMTP IAM policy name override (defaults to <name_prefix>-ses-send-email)"
  type        = string
  default     = null
}

variable "enable_service_control" {
  description = "Enable service control API + waiting pages"
  type        = bool
  default     = true
}

variable "ses_domain" {
  description = "SES domain identity (defaults to hosted_zone_name_input)"
  type        = string
  default     = null
}

variable "zulip_mq_password" {
  description = "Password for Amazon MQ (RabbitMQ) broker used by Zulip"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_secret_key" {
  description = "Override for Zulip SECRET_KEY (generate when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_oidc_client_id" {
  description = "OIDC client ID for Zulip SSO (stored in SSM SecureString)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_oidc_client_secret" {
  description = "OIDC client secret for Zulip SSO (stored in SSM SecureString)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_oidc_idps_yaml" {
  description = "Override SOCIAL_AUTH_OIDC_ENABLED_IDPS YAML payload; defaults to Keycloak config when null"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_growi_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into GROWI task definition"
  type        = bool
  default     = false
}

variable "growi_oidc_client_id" {
  description = "Keycloak OIDC client ID for GROWI (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "growi_oidc_client_secret" {
  description = "Keycloak OIDC client secret for GROWI (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_cmdbuild_r2u_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into CMDBuild Ready2Use task definition"
  type        = bool
  default     = false
}

variable "cmdbuild_r2u_oidc_client_id" {
  description = "Keycloak OIDC client ID for CMDBuild Ready2Use (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_r2u_oidc_client_secret" {
  description = "Keycloak OIDC client secret for CMDBuild Ready2Use (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_orangehrm_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into OrangeHRM task definition"
  type        = bool
  default     = false
}

variable "orangehrm_oidc_client_id" {
  description = "Keycloak OIDC client ID for OrangeHRM (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_oidc_client_secret" {
  description = "Keycloak OIDC client secret for OrangeHRM (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_smtp_username" {
  description = "SES SMTP username for Zulip (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_smtp_password" {
  description = "SES SMTP password for Zulip (stored as SecureString in SSM if set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_exastro_web_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Exastro web task definition"
  type        = bool
  default     = false
}

variable "exastro_web_oidc_client_id" {
  description = "Keycloak OIDC client ID for Exastro web (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "exastro_web_oidc_client_secret" {
  description = "Keycloak OIDC client secret for Exastro web (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_exastro_api_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Exastro API task definition"
  type        = bool
  default     = false
}

variable "exastro_api_oidc_client_id" {
  description = "Keycloak OIDC client ID for Exastro API (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "exastro_api_oidc_client_secret" {
  description = "Keycloak OIDC client secret for Exastro API (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_oidc_client_id" {
  description = "Keycloak OIDC client ID for Odoo (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_oidc_client_secret" {
  description = "Keycloak OIDC client secret for Odoo (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_oidc_client_id" {
  description = "Keycloak OIDC client ID for GitLab (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_oidc_client_secret" {
  description = "Keycloak OIDC client secret for GitLab (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "pgadmin_oidc_client_id" {
  description = "Keycloak OIDC client ID for pgAdmin (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "pgadmin_oidc_client_secret" {
  description = "Keycloak OIDC client secret for pgAdmin (stored in SSM when set)"
  type        = string
  sensitive   = true
  default     = null
}

variable "local_image_dir" {
  description = "Local directory to store pulled Docker image tarballs (used by scripts)"
  type        = string
  default     = null
}

variable "aws_profile" {
  description = "Default AWS CLI profile to use in scripts"
  type        = string
  default     = null
}

variable "ecr_namespace" {
  description = "ECR repository namespace/prefix"
  type        = string
  default     = null
}

variable "ecr_repo_n8n" {
  description = "ECR repository name for n8n"
  type        = string
  default     = null
}

variable "ecr_repo_zulip" {
  description = "ECR repository name for Zulip"
  type        = string
  default     = null
}

variable "ecr_repo_main_svc" {
  description = "ECR repository name for main-svc"
  type        = string
  default     = null
}

variable "ecr_repo_gitlab" {
  description = "ECR repository name for GitLab Omnibus"
  type        = string
  default     = null
}

variable "ecr_repo_keycloak" {
  description = "ECR repository name for Keycloak"
  type        = string
  default     = null
}

variable "ecr_repo_exastro_it_automation_web_server" {
  description = "ECR repository name for Exastro IT Automation web server"
  type        = string
  default     = null
}

variable "ecr_repo_exastro_it_automation_api_admin" {
  description = "ECR repository name for Exastro IT Automation API admin"
  type        = string
  default     = null
}

variable "ecr_repo_odoo" {
  description = "ECR repository name for Odoo"
  type        = string
  default     = null
}

variable "ecr_repo_pgadmin" {
  description = "ECR repository name for pgAdmin"
  type        = string
  default     = null
}

variable "ecr_repo_phpmyadmin" {
  description = "ECR repository name for phpMyAdmin"
  type        = string
  default     = null
}

variable "n8n_image_tag" {
  description = "n8n image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "gitlab_omnibus_image_tag" {
  description = "GitLab Omnibus image tag to pull/build"
  type        = string
  default     = null
}

variable "main_svc_image_tag" {
  description = "Main-svc base image tag (nginx alpine)"
  type        = string
  default     = null
}

variable "keycloak_image_tag" {
  description = "Keycloak image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "odoo_image_tag" {
  description = "Odoo image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "growi_image_tag" {
  description = "GROWI image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "orangehrm_image_tag" {
  description = "OrangeHRM image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "pgadmin_image_tag" {
  description = "Image tag for pgAdmin"
  type        = string
  default     = null
}

variable "phpmyadmin_image_tag" {
  description = "Image tag for phpMyAdmin"
  type        = string
  default     = "5.2.3"
}

variable "cmdbuild_image_tag" {
  description = "CMDBuild image tag to use for pulls/builds (application)"
  type        = string
  default     = null
}

variable "cmdbuild_r2u_image_tag" {
  description = "CMDBuild Ready2Use image tag to use for pulls/builds"
  type        = string
  default     = null
}

variable "exastro_it_automation_web_server_image_tag" {
  description = "Exastro IT Automation web server image (repo:tag)"
  type        = string
  default     = null
}

variable "exastro_it_automation_api_admin_image_tag" {
  description = "Exastro IT Automation API admin image (repo:tag)"
  type        = string
  default     = null
}

variable "image_architecture" {
  description = "Container platform/architecture (e.g., linux/amd64, linux/arm64)"
  type        = string
  default     = null
}

variable "cmdbuild_r2u_db_name" {
  description = "Database name for CMDBuild Ready2Use"
  type        = string
  default     = "cmdbuild"
}

variable "cmdbuild_r2u_db_username" {
  description = "Database username for CMDBuild Ready2Use"
  type        = string
  default     = "cmdbuild"
}

variable "cmdbuild_r2u_desired_count" {
  description = "Default desired count for CMDBuild Ready2Use ECS service"
  type        = number
  default     = 1
}

variable "cmdbuild_r2u_environment" {
  description = "Environment variables for CMDBuild Ready2Use container"
  type        = map(string)
  default     = null
}

variable "cmdbuild_r2u_filesystem_path" {
  description = "Container path to mount persistent volume for CMDBuild READY2USE"
  type        = string
  default     = "/cmdbuild/data"
}

variable "cmdbuild_r2u_secrets" {
  description = "Secrets (name/valueFrom) for CMDBuild Ready2Use container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "cmdbuild_r2u_ssm_params" {
  description = "SSM params to inject into CMDBuild Ready2Use container"
  type        = map(string)
  default     = null
}

variable "create_cmdbuild_r2u" {
  description = "Whether to create CMDBuild Ready2Use service resources"
  type        = bool
  default     = true
}

variable "create_cmdbuild_r2u_efs" {
  description = "Whether to create an EFS (One Zone) for CMDBuild READY2USE persistent files"
  type        = bool
  default     = true
}

variable "create_ecs" {
  type    = bool
  default = true
}

variable "create_exastro_api_admin" {
  description = "Whether to create Exastro IT Automation API admin resources"
  type        = bool
  default     = true
}

variable "create_exastro_efs" {
  type    = bool
  default = true
}

variable "create_exastro_web_server" {
  description = "Whether to create Exastro IT Automation web server resources"
  type        = bool
  default     = true
}

variable "create_gitlab_config_efs" {
  type    = bool
  default = true
}

variable "create_gitlab_data_efs" {
  type    = bool
  default = true
}

variable "create_growi" {
  description = "Whether to create GROWI service resources"
  type        = bool
  default     = true
}

variable "create_growi_docdb" {
  description = "Whether to create a DocumentDB cluster for GROWI"
  type        = bool
  default     = true
}

variable "create_growi_efs" {
  description = "Whether to create an EFS (One Zone) for GROWI persistent files"
  type        = bool
  default     = true
}

variable "create_keycloak_efs" {
  type    = bool
  default = true
}

variable "create_n8n_efs" {
  type    = bool
  default = true
}

variable "create_odoo_efs" {
  type    = bool
  default = true
}

variable "create_orangehrm" {
  description = "Whether to create OrangeHRM service resources"
  type        = bool
  default     = true
}

variable "create_orangehrm_efs" {
  description = "Whether to create an EFS (One Zone) for OrangeHRM persistent files"
  type        = bool
  default     = true
}

variable "create_mysql_rds" {
  description = "Whether to create a dedicated MySQL RDS instance"
  type        = bool
  default     = true
}

variable "mysql_db_name" {
  description = "Database name for the dedicated MySQL RDS"
  type        = string
  default     = "appdb"
}

variable "mysql_db_username" {
  description = "Database username for the dedicated MySQL RDS"
  type        = string
  default     = "admin"
}

variable "mysql_db_password" {
  description = "Database password for the dedicated MySQL RDS (auto-generated when null)"
  type        = string
  sensitive   = true
  default     = null
}

variable "mysql_rds_skip_final_snapshot" {
  description = "When true, skip creating a final snapshot on MySQL RDS deletion"
  type        = bool
  default     = true
}

variable "create_pgadmin_efs" {
  type    = bool
  default = true
}

variable "create_ses" {
  description = "Whether to create SES domain identity/DKIM and Route53 records"
  type        = bool
  default     = true
}

variable "create_zulip_efs" {
  type    = bool
  default = true
}

variable "create_ssm_parameters" {
  description = "Whether this module should create/update SSM parameters (set false when external scripts manage SSM)"
  type        = bool
  default     = true
}

variable "pg_db_name" {
  type    = string
  default = "appDB"
}

variable "ecr_repo_cmdbuild" {
  description = "ECR repository name for CMDBuild (vanilla)"
  type        = string
  default     = "cmdbuild"
}

variable "ecr_repo_cmdbuild_r2u" {
  description = "ECR repository name for CMDBuild Ready2Use"
  type        = string
  default     = "cmdbuild-r2u"
}

variable "ecr_repo_growi" {
  description = "ECR repository name for GROWI"
  type        = string
  default     = "growi"
}

variable "ecr_repo_orangehrm" {
  description = "ECR repository name for OrangeHRM"
  type        = string
  default     = "orangehrm"
}

variable "ecs_logs_retention_days" {
  type    = number
  default = 14
}

variable "ecs_task_cpu" {
  type    = number
  default = 512
}

variable "ecs_task_memory" {
  type    = number
  default = 1024
}

variable "exastro_web_task_cpu" {
  description = "Override CPU units for Exastro web task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "exastro_web_task_memory" {
  description = "Override memory (MB) for Exastro web task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "exastro_api_task_cpu" {
  description = "Override CPU units for Exastro API task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "exastro_api_task_memory" {
  description = "Override memory (MB) for Exastro API task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "main_svc_task_cpu" {
  description = "Override CPU units for main-svc task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "main_svc_task_memory" {
  description = "Override memory (MB) for main-svc task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "keycloak_task_cpu" {
  description = "Override CPU units for Keycloak task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "keycloak_task_memory" {
  description = "Override memory (MB) for Keycloak task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "pgadmin_task_cpu" {
  description = "Override CPU units for pgAdmin task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "pgadmin_task_memory" {
  description = "Override memory (MB) for pgAdmin task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "phpmyadmin_task_cpu" {
  description = "Override CPU units for phpMyAdmin task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "phpmyadmin_task_memory" {
  description = "Override memory (MB) for phpMyAdmin task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "growi_task_cpu" {
  description = "Override CPU units for GROWI task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "growi_task_memory" {
  description = "Override memory (MB) for GROWI task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "n8n_task_cpu" {
  description = "Override CPU units for n8n task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "n8n_task_memory" {
  description = "Override memory (MB) for n8n task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "zulip_task_cpu" {
  description = "Override CPU units for Zulip task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "zulip_task_memory" {
  description = "Override memory (MB) for Zulip task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "odoo_task_cpu" {
  description = "Override CPU units for Odoo task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "odoo_task_memory" {
  description = "Override memory (MB) for Odoo task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "cmdbuild_r2u_task_cpu" {
  description = "Override CPU units for CMDBuild R2U task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "cmdbuild_r2u_task_memory" {
  description = "Override memory (MB) for CMDBuild R2U task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "orangehrm_task_cpu" {
  description = "Override CPU units for OrangeHRM task definition (null to use ecs_task_cpu)"
  type        = number
  default     = null
}

variable "orangehrm_task_memory" {
  description = "Override memory (MB) for OrangeHRM task definition (null to use ecs_task_memory)"
  type        = number
  default     = null
}

variable "enable_cmdbuild_r2u_autostop" {
  description = "Whether to enable CMDBuild Ready2Use idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_growi_autostop" {
  description = "Whether to enable GROWI idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_main_svc_control_api" {
  type    = bool
  default = true
}

variable "enable_orangehrm_autostop" {
  description = "Whether to enable OrangeHRM idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_ses_smtp_auto" {
  type    = bool
  default = true
}

variable "enable_zulip_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Zulip task definition"
  type        = bool
  default     = true
}

variable "exastro_api_admin_environment" {
  description = "Environment variables for Exastro IT Automation API admin container"
  type        = map(string)
  default     = null
}

variable "exastro_common_environment" {
  description = "Common environment variables to inject into Exastro containers"
  type        = map(string)
  default = {
    "TZ" : "Asia/Tokyo"
  }
}

variable "exastro_api_admin_secrets" {
  description = "Secrets (name/valueFrom) for Exastro API admin container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "exastro_api_admin_ssm_params" {
  description = "SSM params to inject into Exastro API admin"
  type        = map(string)
  default = {
    "SMTP_USERNAME" : "/prod-aiops/exastro-api/smtp/username",
    "SMTP_PASSWORD" : "/prod-aiops/exastro-api/smtp/password",
    "SMTP_HOST" : "email-smtp.ap-northeast-1.amazonaws.com",
    "SMTP_PORT" : "587"
  }
}

variable "exastro_filesystem_path" {
  type    = string
  default = "/exastro/share"
}

variable "exastro_ita_db_name" {
  description = "Database name for Exastro ITA Application DB"
  type        = string
  default     = "itadb"
}

variable "exastro_pf_db_name" {
  description = "Database name for Exastro ITA Platform DB"
  type        = string
  default     = "pfdb"
}

variable "exastro_web_server_environment" {
  description = "Environment variables for Exastro IT Automation web server container"
  type        = map(string)
  default     = {}
}

variable "exastro_web_server_secrets" {
  description = "Secrets (name/valueFrom) for Exastro web server container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "exastro_web_server_ssm_params" {
  description = "SSM params to inject into Exastro web server"
  type        = map(string)
  default = {
    "SMTP_USERNAME" : "/prod-aiops/exastro-web/smtp/username",
    "SMTP_PASSWORD" : "/prod-aiops/exastro-web/smtp/password",
    "SMTP_HOST" : "email-smtp.ap-northeast-1.amazonaws.com",
    "SMTP_PORT" : "587"
  }
}

variable "gitlab_config_bind_paths" {
  type = list(string)
  default = [
    "/etc/gitlab",
    "/etc/letsencrypt"
  ]
}

variable "gitlab_config_mount_base" {
  type    = string
  default = "/mnt/gitlab-config"
}

variable "gitlab_data_filesystem_path" {
  type    = string
  default = "/var/opt/gitlab"
}

variable "gitlab_db_name" {
  description = "Logical database name used by GitLab Omnibus"
  type        = string
  default     = "gitlabhq_production"
}

variable "gitlab_db_ssm_params" {
  type        = map(string)
  description = "SSM params for GitLab DB connectivity (host/port/name/user/password)"
  default     = null
}

variable "gitlab_environment" {
  type    = map(string)
  default = null
}

variable "gitlab_health_check_grace_period_seconds" {
  description = "Grace period for GitLab ECS service load balancer health checks (seconds)"
  type        = number
  default     = 900
}

variable "gitlab_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = [
    {
      "name" : "GITLAB_OIDC_CLIENT_ID",
      "valueFrom" : "/prod-aiops/gitlab/oidc/client_id"
    },
    {
      "name" : "GITLAB_OIDC_CLIENT_SECRET",
      "valueFrom" : "/prod-aiops/gitlab/oidc/client_secret"
    }
  ]
}

variable "gitlab_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach GitLab SSH (port 22); leave empty to disable."
  type        = list(string)
  default     = []
}

variable "gitlab_ssm_params" {
  type    = map(string)
  default = null
}

variable "gitlab_task_cpu" {
  description = "CPU units for GitLab task definition (default 4 vCPU)"
  type        = number
  default     = 4096
}

variable "gitlab_task_memory" {
  description = "Memory (MB) for GitLab task definition"
  type        = number
  default     = 16384
}

variable "growi_db_name" {
  description = "Database name for GROWI (DocumentDB)"
  type        = string
  default     = "growi"
}

variable "growi_db_username" {
  description = "Database username for GROWI (DocumentDB)"
  type        = string
  default     = "growiuser"
}

variable "growi_desired_count" {
  description = "Default desired count for GROWI ECS service"
  type        = number
  default     = 1
}

variable "growi_docdb_engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "docdb_deletion_protection" {
  description = "Whether to enable deletion protection on the GROWI DocumentDB cluster"
  type        = bool
  default     = true
}

variable "growi_docdb_instance_class" {
  description = "DocumentDB instance class for GROWI"
  type        = string
  default     = "db.t4g.medium"
}

variable "growi_docdb_instance_count" {
  description = "Number of DocumentDB instances for GROWI"
  type        = number
  default     = 1
}

variable "docdb_skip_final_snapshot" {
  description = "When true, skip creating a final snapshot for the GROWI DocumentDB cluster"
  type        = bool
  default     = true
}

variable "growi_docdb_final_snapshot_identifier" {
  description = "Optional final snapshot identifier for the GROWI DocumentDB cluster; if null and a final snapshot is required, Terraform generates one automatically."
  type        = string
  default     = null
}

variable "growi_environment" {
  description = "Environment variables for GROWI container"
  type        = map(string)
  default     = null
}

variable "growi_filesystem_path" {
  description = "Container path to mount persistent volume for GROWI"
  type        = string
  default     = "/data"
}

variable "growi_secrets" {
  description = "Secrets (name/valueFrom) for GROWI container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "growi_ssm_params" {
  description = "SSM params to inject into GROWI container (e.g., Mongo URI, root URL)"
  type        = map(string)
  default     = null
}

variable "image_architecture_cpu" {
  type    = string
  default = "X86_64"
}

variable "keycloak_admin_username" {
  description = "Keycloak admin username (SecureString in SSM when set; defaults to admin)"
  type        = string
  default     = "admin"
}

variable "keycloak_db_name" {
  description = "Logical database name used by Keycloak"
  type        = string
  default     = "keycloak"
}

variable "keycloak_db_ssm_params" {
  description = "SSM params for Keycloak DB connectivity (host/port/name/user/password/url)"
  type        = map(string)
  default     = null
}

variable "keycloak_environment" {
  type = map(string)
  default = {
    "KC_PROXY" : "edge",
    "KC_PROXY_HEADERS" : "xforwarded",
    "KC_HTTP_ENABLED" : "true",
    "KC_HOSTNAME_STRICT" : "false",
    "KC_HOSTNAME_STRICT_HTTPS" : "false",
    "KC_METRICS_ENABLED" : "false",
    "KC_HEALTH_ENABLED" : "true",
    "KC_FEATURES" : "token-exchange"
  }
}

variable "keycloak_filesystem_path" {
  type    = string
  default = "/opt/keycloak/data"
}

variable "keycloak_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "keycloak_ssm_params" {
  description = "SSM params specific to Keycloak (overrides defaults)"
  type        = map(string)
  default     = null
}

variable "main_svc_control_api_base_url" {
  description = "Base URL for the main-svc control API (if externally provided)"
  type        = string
  default     = null
}

variable "main_svc_environment" {
  type    = map(string)
  default = {}
}

variable "main_svc_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "n8n_db_name" {
  type    = string
  default = "n8napp"
}

variable "n8n_db_ssm_params" {
  description = "SSM params for n8n DB connectivity (host/port/name)"
  type        = map(string)
  default     = null
}

variable "n8n_db_username" {
  type    = string
  default = "n8nuser"
}

variable "n8n_environment" {
  type = map(string)
  default = {
    "N8N_SMTP_HOST" : "email-smtp.ap-northeast-1.amazonaws.com",
    "N8N_SMTP_PORT" : "587",
    "N8N_SMTP_SSL" : "false"
  }
}

variable "n8n_filesystem_path" {
  type    = string
  default = "/home/node/.n8n"
}

variable "n8n_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "n8n_shell_path" {
  type    = string
  default = "/bin/ash"
}

variable "n8n_ssm_params" {
  type = map(string)
  default = {
    "N8N_SMTP_USER" : "/prod-aiops/n8n/smtp/username",
    "N8N_SMTP_PASS" : "/prod-aiops/n8n/smtp/password"
  }
}

variable "oase_db_name" {
  description = "Logical database name used by Exastro OASE"
  type        = string
  default     = "OASE_DB"
}

variable "odoo_db_name" {
  description = "Logical database name used by Odoo"
  type        = string
  default     = "odooapp"
}

variable "odoo_environment" {
  type    = map(string)
  default = null
}

variable "odoo_filesystem_path" {
  type    = string
  default = "/var/lib/odoo"
}

variable "odoo_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = [
    {
      "name" : "ODOO_OIDC_CLIENT_ID",
      "valueFrom" : "/prod-aiops/odoo/oidc/client_id"
    },
    {
      "name" : "ODOO_OIDC_CLIENT_SECRET",
      "valueFrom" : "/prod-aiops/odoo/oidc/client_secret"
    }
  ]
}

variable "odoo_ssm_params" {
  description = "SSM params specific to Odoo DB/auth (overrides defaults)"
  type        = map(string)
  default     = null
}

variable "orangehrm_admin_username" {
  description = "Application admin username for OrangeHRM"
  type        = string
  default     = "admin"
}

variable "orangehrm_db_name" {
  description = "Database name for OrangeHRM (MySQL/MariaDB)"
  type        = string
  default     = "orangehrm"
}

variable "orangehrm_db_username" {
  description = "Database username for OrangeHRM (MySQL/MariaDB)"
  type        = string
  default     = "orangehrm"
}

variable "orangehrm_desired_count" {
  description = "Default desired count for OrangeHRM ECS service"
  type        = number
  default     = 1
}

variable "orangehrm_environment" {
  description = "Environment variables for OrangeHRM container"
  type        = map(string)
  default     = null
}

variable "orangehrm_filesystem_path" {
  description = "Container path to mount persistent volume for OrangeHRM"
  type        = string
  default     = "/bitnami"
}

variable "mysql_rds_allocated_storage" {
  description = "Allocated storage (GB) for MySQL RDS (OrangeHRM)"
  type        = number
  default     = 20
}

variable "mysql_rds_backup_retention" {
  description = "Backup retention days for MySQL RDS (OrangeHRM)"
  type        = number
  default     = 1
}

variable "mysql_rds_engine_version" {
  description = "MySQL engine version for MySQL RDS (OrangeHRM)"
  type        = string
  default     = "8.0"
}

variable "mysql_rds_instance_class" {
  description = "RDS instance class for MySQL (OrangeHRM)"
  type        = string
  default     = "db.t3.micro"
}

variable "orangehrm_secrets" {
  description = "Secrets (name/valueFrom) for OrangeHRM container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "orangehrm_ssm_params" {
  description = "SSM params to inject into OrangeHRM container"
  type        = map(string)
  default     = null
}

variable "pgadmin_environment" {
  description = "Environment variables for pgAdmin container"
  type        = map(string)
  default     = null
}

variable "pgadmin_filesystem_path" {
  type    = string
  default = "/var/lib/pgadmin"
}

variable "pgadmin_secrets" {
  description = "Secrets (name/valueFrom) for pgAdmin container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = [
    {
      "name" : "PGADMIN_OIDC_CLIENT_ID",
      "valueFrom" : "/prod-aiops/pgadmin/oidc/client_id"
    },
    {
      "name" : "PGADMIN_OIDC_CLIENT_SECRET",
      "valueFrom" : "/prod-aiops/pgadmin/oidc/client_secret"
    }
  ]
}

variable "pgadmin_ssm_params" {
  description = "SSM params specific to pgAdmin (e.g., default password)"
  type        = map(string)
  default     = null
  validation {
    condition = var.pgadmin_ssm_params == null ? true : alltrue([
      for v in values(var.pgadmin_ssm_params) : can(regex("^arn:aws:ssm:", v)) || startswith(v, "/")
    ])
    error_message = "pgadmin_ssm_params の値は SSM パス（/xxx）または SSM ARN を指定してください。平文値を渡したい場合は pgadmin_environment を使ってください。"
  }
}

variable "phpmyadmin_environment" {
  description = "Environment variables for phpMyAdmin container"
  type        = map(string)
  default     = null
}

variable "phpmyadmin_secrets" {
  description = "Secrets (name/valueFrom) for phpMyAdmin container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "phpmyadmin_ssm_params" {
  description = "SSM params to inject into phpMyAdmin container"
  type        = map(string)
  default     = null
}

variable "service_control_api_base_url" {
  description = "Base URL for the service control API (if externally provided)"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "waf_enable" {
  type    = bool
  default = true
}

variable "waf_geo_country_codes" {
  type = list(string)
  default = [
    "JP"
  ]
}

variable "waf_log_retention_in_days" {
  type    = number
  default = 30
}

variable "zulip_db_name" {
  type    = string
  default = "zulip"
}

variable "zulip_db_ssm_params" {
  description = "SSM params for Zulip DB connectivity (host/port/name)"
  type        = map(string)
  default     = null
}

variable "zulip_db_username" {
  type    = string
  default = "zulipuser"
}

variable "zulip_environment" {
  type = map(string)
  default = {
    SSL_CERTIFICATE_GENERATION = "self-signed"
    DISABLE_HTTPS              = "True"
  }
}

variable "zulip_missing_dictionaries" {
  description = "Set postgresql.missing_dictionaries for Zulip (useful on managed PostgreSQL like RDS without hunspell dictionaries)"
  type        = bool
  default     = true
}

variable "zulip_filesystem_path" {
  type    = string
  default = "/data"
}

variable "zulip_image_tag" {
  description = "Zulip image tag to pull/build"
  type        = string
  default     = null
}

variable "zulip_memcached_node_type" {
  description = "ElastiCache node type for Zulip Memcached"
  type        = string
  default     = "cache.t4g.micro"
}

variable "zulip_memcached_nodes" {
  description = "Number of cache nodes for Zulip Memcached cluster"
  type        = number
  default     = 1
}

variable "zulip_memcached_parameter_group" {
  description = "ElastiCache Memcached parameter group name"
  type        = string
  default     = "default.memcached1.6"
}

variable "zulip_mq_deployment_mode" {
  description = "Deployment mode for Amazon MQ broker"
  type        = string
  default     = "SINGLE_INSTANCE"
}

variable "zulip_mq_engine_version" {
  description = "Amazon MQ RabbitMQ engine version for Zulip"
  type        = string
  default     = "3.13"
}

variable "zulip_mq_instance_type" {
  description = "Amazon MQ host instance type for Zulip (RabbitMQ)"
  type        = string
  default     = "mq.t3.micro"
}

variable "zulip_mq_port" {
  description = "Listener port for Amazon MQ (RabbitMQ) broker"
  type        = number
  default     = 5671
}

variable "zulip_mq_username" {
  description = "Username for Amazon MQ (RabbitMQ) broker used by Zulip"
  type        = string
  default     = "zulip"
}

variable "zulip_redis_engine_version" {
  description = "ElastiCache Redis engine version for Zulip"
  type        = string
  default     = "7.1"
}

variable "zulip_redis_maintenance_window" {
  description = "Preferred maintenance window for Zulip Redis (UTC cron window)"
  type        = string
  default     = "sun:18:00-sun:19:00"
}

variable "zulip_redis_node_type" {
  description = "ElastiCache node type for Zulip Redis"
  type        = string
  default     = "cache.t4g.micro"
}

variable "zulip_redis_parameter_group" {
  description = "ElastiCache Redis parameter group name"
  type        = string
  default     = "default.redis7"
}

variable "zulip_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "zulip_ssm_params" {
  type    = map(string)
  default = null
}
