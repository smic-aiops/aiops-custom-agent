# General infrastructure settings

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-northeast-1"
}

variable "keycloak_base_url" {
  description = "Base URL for Keycloak admin endpoint (defaults to https://keycloak.<hosted_zone_name>)"
  type        = string
  default     = null
}

variable "keycloak_realm" {
  description = "Keycloak realm used for service logins when Keycloak is deployed via this repo"
  type        = string
  default     = "master"
}

variable "service_control_keycloak_client_id" {
  description = "Keycloak client identifier used by the service control UI"
  type        = string
  default     = "service-control"
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

variable "efs_prevent_destroy" {
  description = "When true, protect managed EFS file systems from destruction"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "When true, enable deletion protection on RDS instances"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "When true, skip creating a final snapshot on RDS deletion (PostgreSQL)"
  type        = bool
  default     = true
}

variable "image_architecture" {
  description = "Container platform/architecture (e.g., linux/amd64, linux/arm64)"
  type        = string
  default     = "linux/amd64"
}

variable "local_image_dir" {
  description = "Local directory to store pulled Docker image tarballs (used by scripts)"
  type        = string
  default     = "./images"
}

variable "aws_profile" {
  description = "Default AWS CLI profile to use in scripts"
  type        = string
  default     = "Admin-AIOps"
}

variable "ecr_namespace" {
  description = "ECR repository namespace/prefix"
  type        = string
  default     = "aiops"
}

variable "create_ssm_parameters" {
  description = "Whether modules/stack should create/update SSM parameters (set false when managed by external scripts)"
  type        = bool
  default     = true
}

variable "enable_service_control" {
  description = "Enable service control API + waiting pages"
  type        = bool
  default     = true
}

variable "root_redirect_target_url" {
  description = "Target URL for apex/www domain redirects (set null to disable redirect buckets)"
  type        = string
  default     = "https://github.com/smic-aiops/aiops-custom-agent/blob/main/environment-usage-guide.md"
}

variable "service_control_lambda_reserved_concurrency" {
  description = "Reserved concurrency for the service control API Lambda (set to guarantee capacity and avoid throttling; set to null to disable)"
  type        = number
  default     = null
}

variable "service_control_schedule_overrides" {
  description = "Overrides for service control automation schedule (weekday/weekend/holiday start/stop/idle)"
  type = map(object({
    enabled            = bool
    start_time         = string
    stop_time          = string
    idle_minutes       = number
    weekday_start_time = optional(string)
    weekday_stop_time  = optional(string)
    holiday_start_time = optional(string)
    holiday_stop_time  = optional(string)
  }))
  default = {}
}

variable "enable_efs_backup" {
  description = "Enable EFS backup configuration when true"
  type        = bool
  default     = false
}

# Keycloak management

variable "create_keycloak" {
  description = "Whether to create Keycloak service resources"
  type        = bool
  default     = true
}

variable "keycloak_admin_username" {
  description = "Keycloak admin username (used by Terraform to manage clients)"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password (used by Terraform to manage clients)"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_keycloak_autostop" {
  description = "Whether to enable Keycloak idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = false
}

variable "keycloak_desired_count" {
  description = "Default desired count for Keycloak ECS service"
  type        = number
  default     = 1
}

variable "keycloak_task_cpu" {
  description = "Override CPU units for Keycloak task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "keycloak_task_memory" {
  description = "Override memory (MB) for Keycloak task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_keycloak" {
  description = "ECR repository name for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "keycloak_image_tag" {
  description = "Keycloak image tag to use for pulls/builds"
  type        = string
  default     = "26.4.7"
}

variable "keycloak_smtp_username" {
  description = "SES SMTP username for Keycloak"
  type        = string
  sensitive   = true
  default     = null
}

variable "keycloak_smtp_password" {
  description = "SES SMTP password for Keycloak"
  type        = string
  sensitive   = true
  default     = null
}

# OIDC IdP YAML overrides (populated by scripts/create_keycloak_client_for_service.sh)

variable "exastro_web_oidc_idps_yaml" {
  description = "Optional override for Exastro Web Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: exastro-web
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "exastro_api_oidc_idps_yaml" {
  description = "Optional override for Exastro API Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: exastro-api
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "sulu_oidc_idps_yaml" {
  description = "Optional override for sulu Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: sulu
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "keycloak_oidc_idps_yaml" {
  description = "Optional override for Keycloak service Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: keycloak
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "odoo_oidc_idps_yaml" {
  description = "Optional override for Odoo Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: odoo
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "pgadmin_oidc_idps_yaml" {
  description = "Optional override for pgAdmin Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: pgadmin
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "gitlab_oidc_idps_yaml" {
  description = "Optional override for GitLab Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: gitlab
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "growi_oidc_idps_yaml" {
  description = "Optional override for GROWI Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: growi
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "cmdbuild_r2u_oidc_idps_yaml" {
  description = "Optional override for CMDBuild Ready2Use Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: cmdbuild-r2u
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "orangehrm_oidc_idps_yaml" {
  description = "Optional override for OrangeHRM Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: orangehrm
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "zulip_oidc_idps_yaml" {
  description = "Optional override for Zulip Keycloak IdP YAML when managing SSO credentials externally"
  type        = string
  sensitive   = true
  default     = <<-YAML
    keycloak:
      oidc_url: https://keycloak.smic-aiops.jp/realms/master
      display_name: Keycloak
      client_id: zulip
      secret: null
      api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo
      extra_params:
        scope: openid email profile
  YAML
}

variable "zulip_oidc_client_secret_parameter_name" {
  description = "Existing SSM parameter name/ARN for Zulip OIDC client secret (skip Terraform-managed creation when set)"
  type        = string
  default     = null
}

variable "zulip_oidc_client_secret" {
  description = "OIDC client secret for Zulip SSO (stored in SSM SecureString)"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_oidc_full_name_validated" {
  description = "Whether to set SOCIAL_AUTH_OIDC_FULL_NAME_VALIDATED for Zulip"
  type        = bool
  default     = false
}

variable "zulip_oidc_pkce_enabled" {
  description = "Whether to set SOCIAL_AUTH_OIDC_PKCE_ENABLED for Zulip OIDC"
  type        = bool
  default     = true
}

variable "zulip_oidc_pkce_code_challenge_method" {
  description = "Value for SOCIAL_AUTH_OIDC_PKCE_CODE_CHALLENGE_METHOD (e.g., S256)"
  type        = string
  default     = "S256"
}

# n8n service configuration

variable "create_n8n" {
  description = "Whether to create n8n service resources"
  type        = bool
  default     = true
}

variable "enable_n8n_autostop" {
  description = "Whether to enable n8n idle auto-stop (AppAutoScaling + CloudWatch alarm); disable it while service_control による自動起動・停止スケジュールが有効な時間帯は、スケジュールがライフサイクルを管理するため両者を競合させないよう false にします。"
  type        = bool
  default     = false
}

variable "n8n_desired_count" {
  description = "Default desired count for n8n ECS service"
  type        = number
  default     = 1
}

variable "n8n_task_cpu" {
  description = "Override CPU units for n8n task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "n8n_task_memory" {
  description = "Override memory (MB) for n8n task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_n8n" {
  description = "ECR repository name for n8n"
  type        = string
  default     = "n8n"
}

variable "n8n_image_tag" {
  description = "n8n image tag to use for pulls/builds"
  type        = string
  default     = "1.122.4"
}

variable "n8n_smtp_username" {
  description = "SES SMTP username for n8n"
  type        = string
  sensitive   = true
  default     = null
}

variable "n8n_smtp_password" {
  description = "SES SMTP password for n8n"
  type        = string
  sensitive   = true
  default     = null
}

# Zulip service configuration

variable "create_zulip" {
  description = "Whether to create Zulip service resources"
  type        = bool
  default     = true
}

variable "enable_zulip_autostop" {
  description = "Whether to enable Zulip idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = false
}

variable "enable_zulip_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Zulip task definition"
  type        = bool
  default     = true
}

variable "zulip_desired_count" {
  description = "Default desired count for Zulip ECS service"
  type        = number
  default     = 1
}

variable "zulip_task_cpu" {
  description = "Override CPU units for Zulip task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 2048
}

variable "zulip_task_memory" {
  description = "Override memory (MB) for Zulip task definition (null to use ecs_task_memory)"
  type        = number
  default     = 4096
}

variable "zulip_mq_port" {
  description = "Listener port for Amazon MQ (RabbitMQ) broker used by Zulip"
  type        = number
  default     = 5672
}

variable "ecr_repo_zulip" {
  description = "ECR repository name for Zulip"
  type        = string
  default     = "zulip"
}

variable "zulip_image_tag" {
  description = "Zulip image tag to pull/build"
  type        = string
  default     = "11.4-0"
}

variable "zulip_environment" {
  description = "Additional environment variables for the Zulip task definition"
  type        = map(string)
  default = {
    SSL_CERTIFICATE_GENERATION = "self-signed"
    DISABLE_HTTPS              = "True"
    SETTING_RABBITMQ_USE_TLS   = "False"
    RABBITMQ_USE_TLS           = "false"
  }
}

variable "zulip_missing_dictionaries" {
  description = "Set postgresql.missing_dictionaries for Zulip when running on managed PostgreSQL without hunspell dictionaries"
  type        = bool
  default     = true
}

variable "zulip_smtp_username" {
  description = "SES SMTP username for Zulip"
  type        = string
  sensitive   = true
  default     = null
}

variable "zulip_smtp_password" {
  description = "SES SMTP password for Zulip"
  type        = string
  sensitive   = true
  default     = null
}

# Sulu service control

variable "create_sulu" {
  description = "Whether to create sulu service resources"
  type        = bool
  default     = true
}

variable "create_sulu_efs" {
  description = "Whether to create an EFS for sulu (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "enable_sulu_autostop" {
  description = "Whether to enable sulu idle auto-stop (reserved for future use)"
  type        = bool
  default     = true
}

variable "enable_sulu_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into sulu task definition"
  type        = bool
  default     = false
}

variable "sulu_desired_count" {
  description = "Default desired count for sulu ECS service"
  type        = number
  default     = 0
}

variable "sulu_health_check_grace_period_seconds" {
  description = "Grace period for Sulu ECS service load balancer health checks (seconds)"
  type        = number
  default     = 300
}

variable "sulu_task_cpu" {
  description = "Override CPU units for sulu task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "sulu_task_memory" {
  description = "Override memory (MB) for sulu task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_sulu" {
  description = "ECR repository name for sulu"
  type        = string
  default     = "sulu"
}

variable "ecr_repo_sulu_nginx" {
  description = "ECR repository name for the Sulu nginx companion image"
  type        = string
  default     = "sulu-nginx"
}

variable "sulu_image_tag" {
  description = "Sulu base image tag used for docker/sulu builds (default mirrors the GitHub 3.0.0 release)"
  type        = string
  default     = "3.0.0"
}

variable "sulu_db_name" {
  description = "Logical PostgreSQL database name used by sulu"
  type        = string
  default     = "sulu"
}

variable "sulu_db_username" {
  description = "Optional PostgreSQL username for sulu (falls back to the master user if null)"
  type        = string
  default     = null
}

variable "sulu_share_dir" {
  description = "Filesystem location used as Sulu's share directory (must align with public/uploads/media)"
  type        = string
  default     = "/var/www/html/public/uploads/media"
}

variable "sulu_filesystem_id" {
  description = "Existing EFS ID to mount for sulu uploads/share data"
  type        = string
  default     = null
}

variable "sulu_filesystem_path" {
  description = "Container path where the shared EFS is mounted"
  type        = string
  default     = "/efs"
}

variable "sulu_efs_availability_zone" {
  description = "AZ for One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
}

variable "sulu_app_secret" {
  description = "Override APP_SECRET for the sulu task"
  type        = string
  sensitive   = true
  default     = null
}

variable "sulu_mailer_dsn" {
  description = "Override MAILER_DSN for the sulu task (SES-based value is generated when unset)"
  type        = string
  sensitive   = true
  default     = null
}

variable "sulu_sso_default_role_key" {
  description = "Default role key assigned to Keycloak-authenticated Sulu users"
  type        = string
  default     = "ROLE_USER"
}

# Exastro IT Automation stack

variable "create_exastro_web" {
  description = "Whether to create Exastro web server resources (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "create_exastro_api" {
  description = "Whether to create Exastro API admin resources (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "enable_exastro_web" {
  description = "Flag to enable Exastro web service (used by tfvars only)"
  type        = bool
  default     = false
}

variable "enable_exastro_api" {
  description = "Flag to enable Exastro API service (used by tfvars only)"
  type        = bool
  default     = false
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

variable "enable_exastro_web_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Exastro web task definition"
  type        = bool
  default     = true
}

variable "enable_exastro_api_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into Exastro API task definition"
  type        = bool
  default     = true
}

variable "exastro_web_server_desired_count" {
  description = "Default desired count for Exastro IT Automation web server ECS service"
  type        = number
  default     = 0
}

variable "exastro_api_admin_desired_count" {
  description = "Default desired count for Exastro IT Automation API admin ECS service"
  type        = number
  default     = 0
}

variable "exastro_web_task_cpu" {
  description = "Override CPU units for Exastro web task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "exastro_web_task_memory" {
  description = "Override memory (MB) for Exastro web task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "exastro_api_task_cpu" {
  description = "Override CPU units for Exastro API task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "exastro_api_task_memory" {
  description = "Override memory (MB) for Exastro API task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_exastro_it_automation_web_server" {
  description = "ECR repository name for Exastro IT Automation web server"
  type        = string
  default     = "exastro-it-automation-web-server"
}

variable "exastro_it_automation_web_server_image_tag" {
  description = "Exastro IT Automation web server image (repo:tag)"
  type        = string
  default     = "exastro/exastro-it-automation-web-server:2.7.0"
}

variable "ecr_repo_exastro_it_automation_api_admin" {
  description = "ECR repository name for Exastro IT Automation API admin"
  type        = string
  default     = "exastro-it-automation-api-admin"
}

variable "exastro_it_automation_api_admin_image_tag" {
  description = "Exastro IT Automation API admin image (repo:tag)"
  type        = string
  default     = "exastro/exastro-it-automation-api-admin:2.7.0"
}

# GitLab service

variable "create_gitlab" {
  description = "Whether to create GitLab Omnibus service resources"
  type        = bool
  default     = true
}

variable "enable_gitlab_autostop" {
  description = "Whether to enable GitLab idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_gitlab_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into GitLab task definition"
  type        = bool
  default     = true
}

variable "gitlab_desired_count" {
  description = "Default desired count for GitLab ECS service"
  type        = number
  default     = 0
}

variable "gitlab_task_cpu" {
  description = "CPU units for GitLab task definition (default 4 vCPU)"
  type        = number
  default     = 2048
}

variable "gitlab_task_memory" {
  description = "Memory (MB) for GitLab task definition"
  type        = number
  default     = 4096
}

variable "ecr_repo_gitlab" {
  description = "ECR repository name for GitLab Omnibus"
  type        = string
  default     = "gitlab-omnibus"
}

variable "gitlab_omnibus_image_tag" {
  description = "GitLab Omnibus image tag to pull/build"
  type        = string
  default     = "17.11.7-ce.0"
}

variable "gitlab_smtp_username" {
  description = "SES SMTP username for GitLab"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_smtp_password" {
  description = "SES SMTP password for GitLab"
  type        = string
  sensitive   = true
  default     = null
}

# Odoo service

variable "create_odoo" {
  description = "Whether to create Odoo service resources"
  type        = bool
  default     = true
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

variable "odoo_desired_count" {
  description = "Default desired count for Odoo ECS service"
  type        = number
  default     = 0
}

variable "odoo_task_cpu" {
  description = "Override CPU units for Odoo task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 2048
}

variable "odoo_task_memory" {
  description = "Override memory (MB) for Odoo task definition (null to use ecs_task_memory)"
  type        = number
  default     = 4096
}

variable "ecr_repo_odoo" {
  description = "ECR repository name for Odoo"
  type        = string
  default     = "odoo"
}

variable "odoo_image_tag" {
  description = "Odoo image tag to use for pulls/builds"
  type        = string
  default     = "17.0"
}

variable "odoo_smtp_username" {
  description = "SES SMTP username for Odoo"
  type        = string
  sensitive   = true
  default     = null
}

variable "odoo_smtp_password" {
  description = "SES SMTP password for Odoo"
  type        = string
  sensitive   = true
  default     = null
}

# pgAdmin service

variable "create_pgadmin" {
  description = "Whether to create pgAdmin service resources"
  type        = bool
  default     = true
}

variable "enable_pgadmin_autostop" {
  description = "Whether to enable pgAdmin idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_pgadmin_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into pgAdmin task definition"
  type        = bool
  default     = true
}

variable "pgadmin_desired_count" {
  description = "Default desired count for pgAdmin ECS service"
  type        = number
  default     = 0
}

variable "pgadmin_task_cpu" {
  description = "Override CPU units for pgAdmin task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "pgadmin_task_memory" {
  description = "Override memory (MB) for pgAdmin task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_pgadmin" {
  description = "ECR repository name for pgAdmin"
  type        = string
  default     = "pgadmin"
}

variable "pgadmin_image_tag" {
  description = "Image tag for pgAdmin"
  type        = string
  default     = "9.10.0"
}

variable "pgadmin_smtp_username" {
  description = "SES SMTP username for pgAdmin"
  type        = string
  sensitive   = true
  default     = null
}

variable "pgadmin_smtp_password" {
  description = "SES SMTP password for pgAdmin"
  type        = string
  sensitive   = true
  default     = null
}

# phpMyAdmin service

variable "create_phpmyadmin" {
  description = "Whether to create phpMyAdmin service resources"
  type        = bool
  default     = true
}

variable "enable_phpmyadmin_autostop" {
  description = "Whether to enable phpMyAdmin idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "phpmyadmin_desired_count" {
  description = "Default desired count for phpMyAdmin ECS service"
  type        = number
  default     = 0
}

variable "phpmyadmin_task_cpu" {
  description = "Override CPU units for phpMyAdmin task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "phpmyadmin_task_memory" {
  description = "Override memory (MB) for phpMyAdmin task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_phpmyadmin" {
  description = "ECR repository name for phpMyAdmin"
  type        = string
  default     = "phpmyadmin"
}

variable "phpmyadmin_image_tag" {
  description = "Image tag for phpMyAdmin"
  type        = string
  default     = "5.2.3"
}

variable "enable_phpmyadmin_alb_oidc" {
  description = "Whether to protect phpMyAdmin via ALB OIDC authentication against Keycloak"
  type        = bool
  default     = true
  validation {
    condition     = var.enable_phpmyadmin_alb_oidc == false ? true : (var.phpmyadmin_oidc_client_id != null && var.phpmyadmin_oidc_client_secret != null)
    error_message = "When enable_phpmyadmin_alb_oidc is true, set both phpmyadmin_oidc_client_id and phpmyadmin_oidc_client_secret."
  }
}

variable "phpmyadmin_oidc_client_id" {
  description = "OIDC client ID for ALB-authenticated phpMyAdmin (Keycloak)"
  type        = string
  sensitive   = true
  default     = null
}

variable "phpmyadmin_oidc_client_secret" {
  description = "OIDC client secret for ALB-authenticated phpMyAdmin (Keycloak)"
  type        = string
  sensitive   = true
  default     = null
}

# GROWI service

variable "create_growi" {
  description = "Whether to create GROWI service resources (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "create_growi_docdb" {
  description = "Whether to create a DocumentDB cluster for GROWI (tfvars-only flag)"
  type        = bool
  default     = false
}

variable "growi_db_password" {
  description = "Database password for GROWI (DocumentDB)"
  type        = string
  sensitive   = true
  default     = null
}

variable "create_growi_efs" {
  description = "Whether to create an EFS for GROWI persistent files (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "enable_growi_autostop" {
  description = "Whether to enable GROWI idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_growi_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into GROWI task definition"
  type        = bool
  default     = true
}

variable "growi_desired_count" {
  description = "Default desired count for GROWI ECS service"
  type        = number
  default     = 0
}

variable "growi_task_cpu" {
  description = "Override CPU units for GROWI task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "growi_task_memory" {
  description = "Override memory (MB) for GROWI task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "growi_image_tag" {
  description = "GROWI image tag to use for pulls/builds"
  type        = string
  default     = "7.3.8"
}

variable "growi_docdb_engine_version" {
  description = "DocumentDB engine version for GROWI"
  type        = string
  default     = "5.0.0"
}

variable "docdb_deletion_protection" {
  description = "Whether to enable deletion protection on the GROWI DocumentDB cluster"
  type        = bool
  default     = false
}

variable "docdb_skip_final_snapshot" {
  description = "Skip creating a final snapshot when destroying the GROWI DocumentDB cluster"
  type        = bool
  default     = true
}

variable "growi_docdb_final_snapshot_identifier" {
  description = "Final snapshot identifier to use when skip_final_snapshot is false for GROWI DocumentDB"
  type        = string
  default     = null
}

variable "growi_smtp_username" {
  description = "SES SMTP username for GROWI"
  type        = string
  sensitive   = true
  default     = null
}

variable "growi_smtp_password" {
  description = "SES SMTP password for GROWI"
  type        = string
  sensitive   = true
  default     = null
}

# OrangeHRM service

variable "create_orangehrm" {
  description = "Whether to create OrangeHRM service resources (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "create_orangehrm_efs" {
  description = "Whether to create an EFS for OrangeHRM persistent files (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "create_mysql_rds" {
  description = "Whether to create a dedicated MySQL RDS instance (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "mysql_rds_skip_final_snapshot" {
  description = "When true, skip creating a final snapshot on MySQL RDS deletion"
  type        = bool
  default     = true
}

variable "enable_orangehrm_autostop" {
  description = "Whether to enable OrangeHRM idle auto-stop (AppAutoScaling + CloudWatch alarm)"
  type        = bool
  default     = true
}

variable "enable_orangehrm_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into OrangeHRM task definition"
  type        = bool
  default     = true
}

variable "orangehrm_desired_count" {
  description = "Default desired count for OrangeHRM ECS service"
  type        = number
  default     = 0
}

variable "orangehrm_task_cpu" {
  description = "Override CPU units for OrangeHRM task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "orangehrm_task_memory" {
  description = "Override memory (MB) for OrangeHRM task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "orangehrm_image_tag" {
  description = "OrangeHRM image tag to use for pulls/builds"
  type        = string
  default     = "5.8"
}

variable "orangehrm_smtp_username" {
  description = "SES SMTP username for OrangeHRM"
  type        = string
  sensitive   = true
  default     = null
}

variable "orangehrm_smtp_password" {
  description = "SES SMTP password for OrangeHRM"
  type        = string
  sensitive   = true
  default     = null
}

# CMDBuild (vanilla)

variable "ecr_repo_cmdbuild" {
  description = "ECR repository name for CMDBuild (vanilla)"
  type        = string
  default     = "cmdbuild"
}

variable "cmdbuild_image_tag" {
  description = "CMDBuild image tag to use for pulls/builds (application)"
  type        = string
  default     = "4.1.0"
}

variable "cmdbuild_smtp_username" {
  description = "SES SMTP username for CMDBuild"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_smtp_password" {
  description = "SES SMTP password for CMDBuild"
  type        = string
  sensitive   = true
  default     = null
}

# CMDBuild Ready2Use

variable "create_cmdbuild_r2u" {
  description = "Whether to create CMDBuild Ready2Use resources (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "create_cmdbuild_r2u_efs" {
  description = "Whether to create an EFS for CMDBuild Ready2Use (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "enable_cmdbuild_r2u" {
  description = "Flag to enable CMDBuild Ready2Use service (used by tfvars only)"
  type        = bool
  default     = false
}

variable "enable_cmdbuild_r2u_autostop" {
  description = "Whether to enable CMDBuild Ready2Use idle auto-stop (tfvars-only flag)"
  type        = bool
  default     = true
}

variable "enable_cmdbuild_r2u_keycloak" {
  description = "Whether to inject Keycloak OIDC settings into CMDBuild Ready2Use task definition"
  type        = bool
  default     = true
}

variable "cmdbuild_r2u_desired_count" {
  description = "Default desired count for CMDBuild Ready2Use ECS service"
  type        = number
  default     = 0
}

variable "cmdbuild_r2u_task_cpu" {
  description = "Override CPU units for CMDBuild R2U task definition (null to use ecs_task_cpu)"
  type        = number
  default     = 512
}

variable "cmdbuild_r2u_task_memory" {
  description = "Override memory (MB) for CMDBuild R2U task definition (null to use ecs_task_memory)"
  type        = number
  default     = 1024
}

variable "ecr_repo_cmdbuild_r2u" {
  description = "ECR repository name for CMDBuild Ready2Use"
  type        = string
  default     = "cmdbuild-r2u"
}

variable "cmdbuild_r2u_image_tag" {
  description = "CMDBuild Ready2Use image tag to use for pulls/builds"
  type        = string
  default     = "r2u-2.4-4.1.0"
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

variable "cmdbuild_r2u_db_password" {
  description = "Database password for CMDBuild Ready2Use (stored in SSM)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cmdbuild_r2u_filesystem_path" {
  description = "Container path to mount persistent volume for CMDBuild Ready2Use"
  type        = string
  default     = "/cmdbuild/data"
}

variable "cmdbuild_r2u_filesystem_id" {
  description = "Existing EFS ID to mount for CMDBuild Ready2Use (if not creating new)"
  type        = string
  default     = null
}

variable "cmdbuild_r2u_efs_availability_zone" {
  description = "AZ for CMDBuild Ready2Use One Zone EFS (defaults to first private subnet AZ)"
  type        = string
  default     = null
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

variable "cmdbuild_r2u_environment" {
  description = "Environment variables for CMDBuild Ready2Use container"
  type        = map(string)
  default     = null
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

# ECS task sizing defaults

variable "ecs_task_cpu" {
  type    = number
  default = 512
}

variable "ecs_task_memory" {
  type    = number
  default = 1024
}
