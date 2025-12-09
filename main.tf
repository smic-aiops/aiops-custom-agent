terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.1"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

module "stack" {
  source = "./modules/stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  region                                    = var.region
  efs_prevent_destroy                       = var.efs_prevent_destroy
  rds_deletion_protection                   = var.rds_deletion_protection
  rds_skip_final_snapshot                   = var.rds_skip_final_snapshot
  existing_internet_gateway_id              = var.existing_internet_gateway_id
  existing_nat_gateway_id                   = var.existing_nat_gateway_id
  create_n8n                                = var.create_n8n
  create_zulip                              = var.create_zulip
  create_pgadmin                            = var.create_pgadmin
  create_phpmyadmin                         = var.create_phpmyadmin
  create_main_svc                           = var.create_main_svc
  create_keycloak                           = var.create_keycloak
  create_odoo                               = var.create_odoo
  create_gitlab                             = var.create_gitlab
  manage_keycloak_clients                   = var.manage_keycloak_clients
  create_cmdbuild_r2u                       = var.create_cmdbuild_r2u
  create_exastro_web_server                 = var.create_exastro_web
  create_exastro_api_admin                  = var.create_exastro_api
  create_growi                              = var.create_growi
  create_cmdbuild_r2u_efs                   = var.create_cmdbuild_r2u_efs
  create_growi_docdb                        = var.create_growi_docdb
  create_growi_efs                          = var.create_growi_efs
  create_orangehrm                          = var.create_orangehrm
  create_orangehrm_efs                      = var.create_orangehrm_efs
  create_mysql_rds                          = var.create_mysql_rds
  mysql_rds_skip_final_snapshot             = var.mysql_rds_skip_final_snapshot
  enable_exastro_web                        = var.enable_exastro_web
  enable_exastro_api                        = var.enable_exastro_api
  enable_cmdbuild_r2u                       = var.enable_cmdbuild_r2u
  create_ssm_parameters                     = var.create_ssm_parameters
  enable_n8n_autostop                       = var.enable_n8n_autostop
  enable_exastro_web_autostop               = var.enable_exastro_web_autostop
  enable_exastro_api_autostop               = var.enable_exastro_api_autostop
  enable_cmdbuild_r2u_autostop              = var.enable_cmdbuild_r2u_autostop
  n8n_desired_count                         = var.n8n_desired_count
  enable_zulip_autostop                     = var.enable_zulip_autostop
  zulip_desired_count                       = var.zulip_desired_count
  main_svc_desired_count                    = var.main_svc_desired_count
  enable_main_svc_autostop                  = var.enable_main_svc_autostop
  enable_pgadmin_autostop                   = var.enable_pgadmin_autostop
  enable_phpmyadmin_autostop                = var.enable_phpmyadmin_autostop
  enable_keycloak_autostop                  = var.enable_keycloak_autostop
  enable_odoo_autostop                      = var.enable_odoo_autostop
  enable_growi_autostop                     = var.enable_growi_autostop
  enable_orangehrm_autostop                 = var.enable_orangehrm_autostop
  pgadmin_desired_count                     = var.pgadmin_desired_count
  phpmyadmin_desired_count                  = var.phpmyadmin_desired_count
  keycloak_desired_count                    = var.keycloak_desired_count
  exastro_web_server_desired_count          = var.exastro_web_server_desired_count
  exastro_api_admin_desired_count           = var.exastro_api_admin_desired_count
  gitlab_desired_count                      = var.gitlab_desired_count
  odoo_desired_count                        = var.odoo_desired_count
  cmdbuild_r2u_desired_count                = var.cmdbuild_r2u_desired_count
  growi_desired_count                       = var.growi_desired_count
  orangehrm_desired_count                   = var.orangehrm_desired_count
  enable_gitlab_autostop                    = var.enable_gitlab_autostop
  ecr_namespace                             = var.ecr_namespace
  keycloak_base_url                         = var.keycloak_base_url
  keycloak_admin_username                   = var.keycloak_admin_username
  keycloak_admin_password                   = var.keycloak_admin_password
  ecr_repo_n8n                              = var.ecr_repo_n8n
  ecr_repo_zulip                            = var.ecr_repo_zulip
  ecr_repo_main_svc                         = var.ecr_repo_main_svc
  ecr_repo_gitlab                           = var.ecr_repo_gitlab
  ecr_repo_pgadmin                          = var.ecr_repo_pgadmin
  ecr_repo_phpmyadmin                       = var.ecr_repo_phpmyadmin
  ecr_repo_keycloak                         = var.ecr_repo_keycloak
  ecr_repo_cmdbuild                         = var.ecr_repo_cmdbuild
  ecr_repo_cmdbuild_r2u                     = var.ecr_repo_cmdbuild_r2u
  ecr_repo_exastro_it_automation_web_server = var.ecr_repo_exastro_it_automation_web_server
  ecr_repo_exastro_it_automation_api_admin  = var.ecr_repo_exastro_it_automation_api_admin
  ecr_repo_odoo                             = var.ecr_repo_odoo
  gitlab_omnibus_image_tag                  = var.gitlab_omnibus_image_tag
  keycloak_image_tag                        = var.keycloak_image_tag
  pgadmin_image_tag                         = var.pgadmin_image_tag
  phpmyadmin_image_tag                      = var.phpmyadmin_image_tag
  growi_image_tag                           = var.growi_image_tag
  cmdbuild_r2u_image_tag                    = var.cmdbuild_r2u_image_tag
  orangehrm_image_tag                       = var.orangehrm_image_tag
  cmdbuild_image_tag                        = var.cmdbuild_image_tag
  enable_n8n_keycloak                       = var.enable_n8n_keycloak
  enable_zulip_keycloak                     = var.enable_zulip_keycloak
  enable_gitlab_keycloak                    = var.enable_gitlab_keycloak
  enable_pgadmin_keycloak                   = var.enable_pgadmin_keycloak
  enable_odoo_keycloak                      = var.enable_odoo_keycloak
  enable_phpmyadmin_keycloak                = var.enable_phpmyadmin_keycloak
  enable_main_svc_keycloak                  = var.enable_main_svc_keycloak
  enable_service_control                    = var.enable_service_control
  enable_exastro_web_keycloak               = var.enable_exastro_web_keycloak
  enable_exastro_api_keycloak               = var.enable_exastro_api_keycloak
  enable_growi_keycloak                     = var.enable_growi_keycloak
  enable_cmdbuild_r2u_keycloak              = var.enable_cmdbuild_r2u_keycloak
  cmdbuild_r2u_oidc_client_id               = var.cmdbuild_r2u_oidc_client_id
  cmdbuild_r2u_oidc_client_secret           = var.cmdbuild_r2u_oidc_client_secret
  enable_orangehrm_keycloak                 = var.enable_orangehrm_keycloak
  n8n_smtp_username                         = var.n8n_smtp_username
  n8n_smtp_password                         = var.n8n_smtp_password
  zulip_smtp_username                       = var.zulip_smtp_username
  zulip_smtp_password                       = var.zulip_smtp_password
  zulip_environment                         = var.zulip_environment
  zulip_missing_dictionaries                = var.zulip_missing_dictionaries
  keycloak_smtp_username                    = var.keycloak_smtp_username
  keycloak_smtp_password                    = var.keycloak_smtp_password
  odoo_smtp_username                        = var.odoo_smtp_username
  odoo_smtp_password                        = var.odoo_smtp_password
  gitlab_smtp_username                      = var.gitlab_smtp_username
  gitlab_smtp_password                      = var.gitlab_smtp_password
  pgadmin_smtp_username                     = var.pgadmin_smtp_username
  pgadmin_smtp_password                     = var.pgadmin_smtp_password
  growi_smtp_username                       = var.growi_smtp_username
  growi_smtp_password                       = var.growi_smtp_password
  cmdbuild_smtp_username                    = var.cmdbuild_smtp_username
  cmdbuild_smtp_password                    = var.cmdbuild_smtp_password
  cmdbuild_r2u_environment                  = var.cmdbuild_r2u_environment
  cmdbuild_r2u_secrets                      = var.cmdbuild_r2u_secrets
  cmdbuild_r2u_ssm_params                   = var.cmdbuild_r2u_ssm_params
  cmdbuild_r2u_db_name                      = var.cmdbuild_r2u_db_name
  cmdbuild_r2u_db_username                  = var.cmdbuild_r2u_db_username
  cmdbuild_r2u_db_password                  = var.cmdbuild_r2u_db_password
  cmdbuild_r2u_filesystem_path              = var.cmdbuild_r2u_filesystem_path
  cmdbuild_r2u_filesystem_id                = var.cmdbuild_r2u_filesystem_id
  cmdbuild_r2u_efs_availability_zone        = var.cmdbuild_r2u_efs_availability_zone
  orangehrm_smtp_username                   = var.orangehrm_smtp_username
  orangehrm_smtp_password                   = var.orangehrm_smtp_password
  ecs_task_cpu                              = var.ecs_task_cpu
  ecs_task_memory                           = var.ecs_task_memory
  exastro_web_task_cpu                      = var.exastro_web_task_cpu
  exastro_web_task_memory                   = var.exastro_web_task_memory
  exastro_api_task_cpu                      = var.exastro_api_task_cpu
  exastro_api_task_memory                   = var.exastro_api_task_memory
  main_svc_task_cpu                         = var.main_svc_task_cpu
  main_svc_task_memory                      = var.main_svc_task_memory
  keycloak_task_cpu                         = var.keycloak_task_cpu
  keycloak_task_memory                      = var.keycloak_task_memory
  pgadmin_task_cpu                          = var.pgadmin_task_cpu
  pgadmin_task_memory                       = var.pgadmin_task_memory
  phpmyadmin_task_cpu                       = var.phpmyadmin_task_cpu
  phpmyadmin_task_memory                    = var.phpmyadmin_task_memory
  growi_task_cpu                            = var.growi_task_cpu
  growi_task_memory                         = var.growi_task_memory
  n8n_task_cpu                              = var.n8n_task_cpu
  n8n_task_memory                           = var.n8n_task_memory
  zulip_task_cpu                            = var.zulip_task_cpu
  zulip_task_memory                         = var.zulip_task_memory
  odoo_task_cpu                             = var.odoo_task_cpu
  odoo_task_memory                          = var.odoo_task_memory
  cmdbuild_r2u_task_cpu                     = var.cmdbuild_r2u_task_cpu
  cmdbuild_r2u_task_memory                  = var.cmdbuild_r2u_task_memory
  orangehrm_task_cpu                        = var.orangehrm_task_cpu
  orangehrm_task_memory                     = var.orangehrm_task_memory
  gitlab_task_cpu                           = var.gitlab_task_cpu
  gitlab_task_memory                        = var.gitlab_task_memory
  main_svc_control_api_base_url             = var.main_svc_control_api_base_url
  zulip_image_tag                           = var.zulip_image_tag
  growi_docdb_engine_version                = var.growi_docdb_engine_version
  docdb_deletion_protection                 = var.docdb_deletion_protection
  docdb_skip_final_snapshot                 = var.docdb_skip_final_snapshot
  growi_docdb_final_snapshot_identifier     = var.growi_docdb_final_snapshot_identifier
}
