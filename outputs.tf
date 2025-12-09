output "vpc_id" {
  description = "ID of the newly created VPC"
  value       = module.stack.vpc_id
}

output "hosted_zone_id" {
  description = "Managed Route53 hosted zone ID"
  value       = module.stack.hosted_zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the managed hosted zone"
  value       = module.stack.hosted_zone_name_servers
}

output "hosted_zone_name" {
  description = "Managed Route53 hosted zone name (root domain)"
  value       = module.stack.hosted_zone_name
}

output "db_credentials_ssm_parameters" {
  description = "SSM parameter names for DB credentials/connection (if created)"
  value       = module.stack.db_credentials_ssm_parameters
}

output "local_image_dir" {
  description = "Local directory to store pulled Docker image tarballs (for scripts)"
  value       = var.local_image_dir
}

output "aws_profile" {
  description = "Default AWS CLI profile for scripts"
  value       = var.aws_profile
}

output "ecr_namespace" {
  description = "ECR namespace/prefix"
  value       = var.ecr_namespace
}

output "ecr_repo_n8n" {
  description = "ECR repository name for n8n"
  value       = var.ecr_repo_n8n
}

output "ecr_repo_zulip" {
  description = "ECR repository name for Zulip"
  value       = var.ecr_repo_zulip
}

output "ecr_repo_main_svc" {
  description = "ECR repository name for main-svc"
  value       = var.ecr_repo_main_svc
}

output "ecr_repo_gitlab" {
  description = "ECR repository name for GitLab Omnibus"
  value       = var.ecr_repo_gitlab
}

output "ecr_repo_keycloak" {
  description = "ECR repository name for Keycloak"
  value       = var.ecr_repo_keycloak
}

output "ecr_repo_exastro_it_automation_web_server" {
  description = "ECR repository name for Exastro IT Automation web server"
  value       = var.ecr_repo_exastro_it_automation_web_server
}

output "ecr_repo_exastro_it_automation_api_admin" {
  description = "ECR repository name for Exastro IT Automation API admin"
  value       = var.ecr_repo_exastro_it_automation_api_admin
}

output "ecr_repo_odoo" {
  description = "ECR repository name for Odoo"
  value       = var.ecr_repo_odoo
}

output "ecr_repo_pgadmin" {
  description = "ECR repository name for pgAdmin"
  value       = var.ecr_repo_pgadmin
}

output "ecr_repo_phpmyadmin" {
  description = "ECR repository name for phpMyAdmin"
  value       = var.ecr_repo_phpmyadmin
}

output "ecr_repositories" {
  description = "ECR repositories (namespace/repo)"
  value = {
    n8n         = "${var.ecr_namespace}/${var.ecr_repo_n8n}"
    zulip       = "${var.ecr_namespace}/${var.ecr_repo_zulip}"
    main_svc    = "${var.ecr_namespace}/${var.ecr_repo_main_svc}"
    gitlab      = "${var.ecr_namespace}/${var.ecr_repo_gitlab}"
    odoo        = "${var.ecr_namespace}/${var.ecr_repo_odoo}"
    keycloak    = "${var.ecr_namespace}/${var.ecr_repo_keycloak}"
    pgadmin     = "${var.ecr_namespace}/${var.ecr_repo_pgadmin}"
    phpmyadmin  = "${var.ecr_namespace}/${var.ecr_repo_phpmyadmin}"
    exastro_web = "${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_web_server}"
    exastro_api = "${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_api_admin}"
  }
}

output "ecr_image_uris" {
  description = "ECR image URIs (latest tag) for pushing/pulling"
  value = {
    n8n         = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_n8n}:latest"
    zulip       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_zulip}:latest"
    main_svc    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_main_svc}:latest"
    gitlab      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_gitlab}:latest"
    odoo        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_odoo}:latest"
    keycloak    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_keycloak}:latest"
    pgadmin     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_pgadmin}:latest"
    phpmyadmin  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_phpmyadmin}:latest"
    exastro_web = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_web_server}:latest"
    exastro_api = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_namespace}/${var.ecr_repo_exastro_it_automation_api_admin}:latest"
  }
}

output "n8n_image_tag" {
  description = "n8n image tag"
  value       = var.n8n_image_tag
}

output "gitlab_omnibus_image_tag" {
  description = "GitLab Omnibus image tag"
  value       = var.gitlab_omnibus_image_tag
}

output "zulip_image_tag" {
  description = "Zulip image tag"
  value       = var.zulip_image_tag
}

output "main_svc_image_tag" {
  description = "Main-svc (nginx) image tag"
  value       = var.main_svc_image_tag
}

output "keycloak_image_tag" {
  description = "Keycloak image tag"
  value       = var.keycloak_image_tag
}

output "odoo_image_tag" {
  description = "Odoo image tag"
  value       = var.odoo_image_tag
}

output "growi_image_tag" {
  description = "GROWI image tag"
  value       = var.growi_image_tag
}

output "orangehrm_image_tag" {
  description = "OrangeHRM image tag"
  value       = var.orangehrm_image_tag
}

output "pgadmin_image_tag" {
  description = "pgAdmin image tag"
  value       = var.pgadmin_image_tag
}

output "phpmyadmin_image_tag" {
  description = "phpMyAdmin image tag"
  value       = var.phpmyadmin_image_tag
}

output "cmdbuild_image_tag" {
  description = "CMDBuild image tag"
  value       = var.cmdbuild_image_tag
}

output "cmdbuild_r2u_image_tag" {
  description = "CMDBuild Ready2Use image tag"
  value       = var.cmdbuild_r2u_image_tag
}

output "exastro_it_automation_web_server_image_tag" {
  description = "Exastro IT Automation web server image (repo:tag)"
  value       = var.exastro_it_automation_web_server_image_tag
}

output "exastro_it_automation_api_admin_image_tag" {
  description = "Exastro IT Automation API admin image (repo:tag)"
  value       = var.exastro_it_automation_api_admin_image_tag
}

output "image_architecture" {
  description = "Container platform/architecture"
  value       = var.image_architecture
}

output "ecs_cluster" {
  description = "ECS cluster info (if created)"
  value = {
    name               = try(module.stack.ecs_cluster.name, null)
    arn                = try(module.stack.ecs_cluster.arn, null)
    execution_role_arn = try(module.stack.ecs_cluster.execution_role_arn, null)
    task_role_arn      = try(module.stack.ecs_cluster.task_role_arn, null)
  }
}

output "service_urls" {
  description = "Endpoints for user-facing services"
  value       = module.stack.service_urls
}

output "enabled_services" {
  description = "ECS services enabled for deployment"
  value       = module.stack.enabled_services
}

output "main_svc_control_api_base_url" {
  description = "Base URL for the main-svc control API (set via var.main_svc_control_api_base_url)"
  value       = module.stack.main_svc_control_api_base_url
}

output "service_control_api_base_url" {
  description = "Base URL for the service control API (n8n/zulip/main-svc/keycloak/odoo/pgadmin/phpmyadmin/gitlab)"
  value       = module.stack.service_control_api_base_url
}

output "n8n_filesystem_id" {
  description = "EFS ID used for n8n persistent storage (if enabled)"
  value       = module.stack.n8n_filesystem_id
}

output "zulip_filesystem_id" {
  description = "EFS ID used for Zulip persistent storage (if enabled)"
  value       = module.stack.zulip_filesystem_id
}

output "exastro_filesystem_id" {
  description = "EFS ID used for Exastro IT Automation persistent storage (if enabled)"
  value       = module.stack.exastro_filesystem_id
}

output "cmdbuild_r2u_filesystem_id" {
  description = "EFS ID used for CMDBuild READY2USE persistent storage (if enabled)"
  value       = module.stack.cmdbuild_r2u_filesystem_id
}

output "rds" {
  description = "RDS instance details (if created)"
  value       = module.stack.rds
}

output "rds_postgresql" {
  description = "PostgreSQL RDS connection details and password retrieval helper (if created)"
  value       = module.stack.rds_postgresql
}

output "rds_mysql" {
  description = "MySQL RDS connection details and password retrieval helper (if created)"
  value       = module.stack.rds_mysql
}

output "initial_credentials" {
  description = "Initial admin credentials (SSM parameter names) for selected services"
  value       = module.stack.initial_credentials
  sensitive   = true
}

output "service_admin_info" {
  description = "Initial admin URLs and credential pointers per service (password values are not exposed; console links point to SSM SecureString entries)"
  value       = module.stack.service_admin_info
}

output "zulip_dependencies" {
  description = "Zulip dependency endpoints and SSM parameter names"
  value       = module.stack.zulip_dependencies
}
