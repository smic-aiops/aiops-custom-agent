locals {
  n8n_efs_name           = "${local.name_prefix}-n8n-efs"
  n8n_efs_sg             = "${local.name_prefix}-n8n-efs-sg"
  n8n_efs_az             = coalesce(var.n8n_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  zulip_efs_name         = "${local.name_prefix}-zulip-efs"
  zulip_efs_sg           = "${local.name_prefix}-zulip-efs-sg"
  zulip_efs_az           = coalesce(var.zulip_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  pgadmin_efs_name       = "${local.name_prefix}-pgadmin-efs"
  pgadmin_efs_sg         = "${local.name_prefix}-pgadmin-efs-sg"
  pgadmin_efs_az         = coalesce(var.pgadmin_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  exastro_efs_name       = "${local.name_prefix}-exastro-efs"
  exastro_efs_sg         = "${local.name_prefix}-exastro-efs-sg"
  exastro_efs_az         = coalesce(var.exastro_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  cmdbuild_r2u_efs_name  = "${local.name_prefix}-cmdbuild-r2u-efs"
  cmdbuild_r2u_efs_sg    = "${local.name_prefix}-cmdbuild-r2u-efs-sg"
  cmdbuild_r2u_efs_az    = coalesce(var.cmdbuild_r2u_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  keycloak_efs_name      = "${local.name_prefix}-keycloak-efs"
  keycloak_efs_sg        = "${local.name_prefix}-keycloak-efs-sg"
  keycloak_efs_az        = coalesce(var.keycloak_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  odoo_efs_name          = "${local.name_prefix}-odoo-efs"
  odoo_efs_sg            = "${local.name_prefix}-odoo-efs-sg"
  odoo_efs_az            = coalesce(var.odoo_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  gitlab_data_efs_name   = "${local.name_prefix}-gitlab-data-efs"
  gitlab_data_efs_sg     = "${local.name_prefix}-gitlab-data-efs-sg"
  gitlab_data_efs_az     = coalesce(var.gitlab_data_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  gitlab_config_efs_name = "${local.name_prefix}-gitlab-config-efs"
  gitlab_config_efs_sg   = "${local.name_prefix}-gitlab-config-efs-sg"
  gitlab_config_efs_az   = coalesce(var.gitlab_config_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
}

data "aws_resourcegroupstaggingapi_resources" "n8n_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.n8n_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "zulip_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.zulip_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "pgadmin_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.pgadmin_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "exastro_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.exastro_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "cmdbuild_r2u_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.cmdbuild_r2u_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "keycloak_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.keycloak_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "odoo_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.odoo_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "gitlab_data_efs" {
  count                 = var.gitlab_data_filesystem_id == null ? 1 : 0
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.gitlab_data_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "gitlab_config_efs" {
  count                 = var.gitlab_config_filesystem_id == null ? 1 : 0
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.gitlab_config_efs_name]
  }
}

locals {
  n8n_existing_efs_id           = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.n8n_efs.resource_tag_mapping_list[0].resource_arn), null)
  zulip_existing_efs_id         = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.zulip_efs.resource_tag_mapping_list[0].resource_arn), null)
  pgadmin_existing_efs_id       = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.pgadmin_efs.resource_tag_mapping_list[0].resource_arn), null)
  exastro_existing_efs_id       = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.exastro_efs.resource_tag_mapping_list[0].resource_arn), null)
  cmdbuild_r2u_existing_efs_id  = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.cmdbuild_r2u_efs.resource_tag_mapping_list[0].resource_arn), null)
  keycloak_existing_efs_id      = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.keycloak_efs.resource_tag_mapping_list[0].resource_arn), null)
  odoo_existing_efs_id          = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.odoo_efs.resource_tag_mapping_list[0].resource_arn), null)
  gitlab_data_existing_efs_id   = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.gitlab_data_efs[0].resource_tag_mapping_list[0].resource_arn), null)
  gitlab_config_existing_efs_id = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.gitlab_config_efs[0].resource_tag_mapping_list[0].resource_arn), null)
}

locals {
  # Keep EFS resources managed unless an explicit filesystem_id is provided.
  create_n8n_efs_effective           = (var.create_n8n_efs || (var.create_ecs && var.create_n8n)) && var.n8n_filesystem_id == null
  create_zulip_efs_effective         = (var.create_zulip_efs || (var.create_ecs && var.create_zulip)) && var.zulip_filesystem_id == null
  create_pgadmin_efs_effective       = (var.create_pgadmin_efs || (var.create_ecs && var.create_pgadmin)) && var.pgadmin_filesystem_id == null
  create_exastro_efs_effective       = (var.create_exastro_efs || (var.create_ecs && (var.create_exastro_web_server || var.create_exastro_api_admin))) && var.exastro_filesystem_id == null
  create_cmdbuild_r2u_efs_effective  = (var.create_cmdbuild_r2u_efs || (var.create_ecs && var.create_cmdbuild_r2u)) && var.cmdbuild_r2u_filesystem_id == null
  create_keycloak_efs_effective      = (var.create_keycloak_efs || (var.create_ecs && var.create_keycloak)) && var.keycloak_filesystem_id == null
  create_odoo_efs_effective          = (var.create_odoo_efs || (var.create_ecs && var.create_odoo)) && var.odoo_filesystem_id == null
  create_gitlab_data_efs_effective   = (var.create_gitlab_data_efs || (var.create_ecs && var.create_gitlab)) && var.gitlab_data_filesystem_id == null
  create_gitlab_config_efs_effective = (var.create_gitlab_config_efs || (var.create_ecs && var.create_gitlab)) && var.gitlab_config_filesystem_id == null
}

resource "aws_security_group" "n8n_efs" {
  count = local.create_n8n_efs_effective && var.n8n_filesystem_id == null ? 1 : 0

  name        = local.n8n_efs_sg
  description = "EFS access for n8n"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.n8n_efs_sg })
}

resource "aws_security_group" "zulip_efs" {
  count = local.create_zulip_efs_effective && var.zulip_filesystem_id == null ? 1 : 0

  name        = local.zulip_efs_sg
  description = "EFS access for Zulip"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.zulip_efs_sg })
}

resource "aws_security_group" "exastro_efs" {
  count = local.create_exastro_efs_effective && var.exastro_filesystem_id == null ? 1 : 0

  name        = local.exastro_efs_sg
  description = "EFS access for Exastro ITA"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.exastro_efs_sg })
}

resource "aws_security_group" "cmdbuild_r2u_efs" {
  count = local.create_cmdbuild_r2u_efs_effective && var.cmdbuild_r2u_filesystem_id == null ? 1 : 0

  name        = local.cmdbuild_r2u_efs_sg
  description = "EFS access for CMDBuild READY2USE"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.cmdbuild_r2u_efs_sg })
}

resource "aws_security_group" "keycloak_efs" {
  count = local.create_keycloak_efs_effective && var.keycloak_filesystem_id == null ? 1 : 0

  name        = local.keycloak_efs_sg
  description = "EFS access for Keycloak"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.keycloak_efs_sg })
}

resource "aws_security_group" "odoo_efs" {
  count = local.create_odoo_efs_effective && var.odoo_filesystem_id == null ? 1 : 0

  name        = local.odoo_efs_sg
  description = "EFS access for Odoo"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.odoo_efs_sg })
}

resource "aws_security_group" "pgadmin_efs" {
  count = local.create_pgadmin_efs_effective && var.pgadmin_filesystem_id == null ? 1 : 0

  name        = local.pgadmin_efs_sg
  description = "EFS access for pgAdmin"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.pgadmin_efs_sg })
}

resource "aws_security_group" "gitlab_data_efs" {
  count = local.create_gitlab_data_efs_effective && var.gitlab_data_filesystem_id == null ? 1 : 0

  name        = local.gitlab_data_efs_sg
  description = "EFS access for GitLab data"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.gitlab_data_efs_sg })
}

resource "aws_security_group" "gitlab_config_efs" {
  count = local.create_gitlab_config_efs_effective && var.gitlab_config_filesystem_id == null ? 1 : 0

  name        = local.gitlab_config_efs_sg
  description = "EFS access for GitLab config"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.gitlab_config_efs_sg })
}

resource "aws_efs_file_system" "n8n" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_n8n_efs_effective && var.n8n_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.n8n_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.n8n_efs_name })
}

locals {
  n8n_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "n8n" {
  count = local.create_n8n_efs_effective ? 1 : 0

  file_system_id  = local.n8n_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.n8n_efs_subnet.name]
  security_groups = [aws_security_group.n8n_efs[0].id]
}

locals {
  n8n_filesystem_id_effective = (
    var.n8n_filesystem_id != null && var.n8n_filesystem_id != "" ? var.n8n_filesystem_id :
    local.n8n_existing_efs_id != null && local.n8n_existing_efs_id != "" ? local.n8n_existing_efs_id :
    local.create_n8n_efs_effective ? try(aws_efs_file_system.n8n[0].id, null) : null
  )
}

resource "aws_efs_file_system" "zulip" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_zulip_efs_effective && var.zulip_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.zulip_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.zulip_efs_name })
}

resource "aws_efs_file_system" "keycloak" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_keycloak_efs_effective && var.keycloak_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.keycloak_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.keycloak_efs_name })
}

resource "aws_efs_file_system" "odoo" {
  count = local.create_odoo_efs_effective && var.odoo_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.odoo_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.odoo_efs_name })
}

resource "aws_efs_file_system" "pgadmin" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_pgadmin_efs_effective && var.pgadmin_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.pgadmin_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.pgadmin_efs_name })
}

resource "aws_efs_file_system" "exastro" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_exastro_efs_effective && var.exastro_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.exastro_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.exastro_efs_name })
}

resource "aws_efs_file_system" "cmdbuild_r2u" {
  # Always keep the managed EFS when not explicitly pointing to an external ID
  count = local.create_cmdbuild_r2u_efs_effective && var.cmdbuild_r2u_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.cmdbuild_r2u_efs_az

  lifecycle_policy {
    transition_to_ia = "AFTER_14_DAYS"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.cmdbuild_r2u_efs_name })
}

resource "aws_efs_file_system" "gitlab_data" {
  count = local.create_gitlab_data_efs_effective && var.gitlab_data_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.gitlab_data_efs_az
  throughput_mode        = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.gitlab_data_efs_name })
}

resource "aws_efs_file_system" "gitlab_config" {
  count = local.create_gitlab_config_efs_effective && var.gitlab_config_filesystem_id == null ? 1 : 0

  performance_mode       = "generalPurpose"
  encrypted              = true
  availability_zone_name = local.gitlab_config_efs_az
  throughput_mode        = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(local.tags, { Name = local.gitlab_config_efs_name })
}

locals {
  zulip_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "zulip" {
  count = local.create_zulip_efs_effective ? 1 : 0

  file_system_id  = local.zulip_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.zulip_efs_subnet.name]
  security_groups = [aws_security_group.zulip_efs[0].id]
}

locals {
  zulip_filesystem_id_effective = (
    var.zulip_filesystem_id != null && var.zulip_filesystem_id != "" ? var.zulip_filesystem_id :
    local.zulip_existing_efs_id != null && local.zulip_existing_efs_id != "" ? local.zulip_existing_efs_id :
    local.create_zulip_efs_effective ? try(aws_efs_file_system.zulip[0].id, null) : null
  )
}

locals {
  exastro_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "exastro" {
  count = local.create_exastro_efs_effective ? 1 : 0

  file_system_id  = local.exastro_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.exastro_efs_subnet.name]
  security_groups = [aws_security_group.exastro_efs[0].id]
}

locals {
  exastro_filesystem_id_effective = (
    var.exastro_filesystem_id != null && var.exastro_filesystem_id != "" ? var.exastro_filesystem_id :
    local.exastro_existing_efs_id != null && local.exastro_existing_efs_id != "" ? local.exastro_existing_efs_id :
    local.create_exastro_efs_effective ? try(aws_efs_file_system.exastro[0].id, null) : null
  )
}

locals {
  cmdbuild_r2u_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "cmdbuild_r2u" {
  count = local.create_cmdbuild_r2u_efs_effective ? 1 : 0

  file_system_id  = local.cmdbuild_r2u_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.cmdbuild_r2u_efs_subnet.name]
  security_groups = [aws_security_group.cmdbuild_r2u_efs[0].id]
}

locals {
  cmdbuild_r2u_filesystem_id_effective = (
    var.cmdbuild_r2u_filesystem_id != null && var.cmdbuild_r2u_filesystem_id != "" ? var.cmdbuild_r2u_filesystem_id :
    local.cmdbuild_r2u_existing_efs_id != null && local.cmdbuild_r2u_existing_efs_id != "" ? local.cmdbuild_r2u_existing_efs_id :
    local.create_cmdbuild_r2u_efs_effective ? try(aws_efs_file_system.cmdbuild_r2u[0].id, null) : null
  )
}

locals {
  keycloak_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "keycloak" {
  count = local.create_keycloak_efs_effective ? 1 : 0

  file_system_id  = local.keycloak_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.keycloak_efs_subnet.name]
  security_groups = [aws_security_group.keycloak_efs[0].id]
}

locals {
  keycloak_filesystem_id_effective = (
    var.keycloak_filesystem_id != null && var.keycloak_filesystem_id != "" ? var.keycloak_filesystem_id :
    local.keycloak_existing_efs_id != null && local.keycloak_existing_efs_id != "" ? local.keycloak_existing_efs_id :
    local.create_keycloak_efs_effective ? try(aws_efs_file_system.keycloak[0].id, null) : null
  )
}

locals {
  odoo_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "odoo" {
  count = local.create_odoo_efs_effective ? 1 : 0

  file_system_id  = local.odoo_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.odoo_efs_subnet.name]
  security_groups = [aws_security_group.odoo_efs[0].id]
}

locals {
  odoo_filesystem_id_effective = (
    var.odoo_filesystem_id != null && var.odoo_filesystem_id != "" ? var.odoo_filesystem_id :
    local.odoo_existing_efs_id != null && local.odoo_existing_efs_id != "" ? local.odoo_existing_efs_id :
    local.create_odoo_efs_effective ? try(aws_efs_file_system.odoo[0].id, null) : null
  )
}

locals {
  pgadmin_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "pgadmin" {
  count = local.create_pgadmin_efs_effective ? 1 : 0

  file_system_id  = local.pgadmin_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.pgadmin_efs_subnet.name]
  security_groups = [aws_security_group.pgadmin_efs[0].id]
}

locals {
  pgadmin_filesystem_id_effective = (
    var.pgadmin_filesystem_id != null && var.pgadmin_filesystem_id != "" ? var.pgadmin_filesystem_id :
    local.pgadmin_existing_efs_id != null && local.pgadmin_existing_efs_id != "" ? local.pgadmin_existing_efs_id :
    local.create_pgadmin_efs_effective ? try(aws_efs_file_system.pgadmin[0].id, null) : null
  )
}

locals {
  gitlab_data_efs_subnet   = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
  gitlab_config_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "gitlab_data" {
  count = local.create_gitlab_data_efs_effective ? 1 : 0

  file_system_id  = local.gitlab_data_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.gitlab_data_efs_subnet.name]
  security_groups = [aws_security_group.gitlab_data_efs[0].id]
}

resource "aws_efs_mount_target" "gitlab_config" {
  count = local.create_gitlab_config_efs_effective ? 1 : 0

  file_system_id  = local.gitlab_config_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.gitlab_config_efs_subnet.name]
  security_groups = [aws_security_group.gitlab_config_efs[0].id]
}

locals {
  gitlab_data_filesystem_id_effective = (
    var.gitlab_data_filesystem_id != null && var.gitlab_data_filesystem_id != "" ? var.gitlab_data_filesystem_id :
    local.gitlab_data_existing_efs_id != null && local.gitlab_data_existing_efs_id != "" ? local.gitlab_data_existing_efs_id :
    local.create_gitlab_data_efs_effective ? try(aws_efs_file_system.gitlab_data[0].id, null) : null
  )
  gitlab_config_filesystem_id_effective = (
    var.gitlab_config_filesystem_id != null && var.gitlab_config_filesystem_id != "" ? var.gitlab_config_filesystem_id :
    local.gitlab_config_existing_efs_id != null && local.gitlab_config_existing_efs_id != "" ? local.gitlab_config_existing_efs_id :
    local.create_gitlab_config_efs_effective ? try(aws_efs_file_system.gitlab_config[0].id, null) : null
  )
}

locals {
  growi_efs_name     = "${local.name_prefix}-growi-efs"
  growi_efs_sg       = "${local.name_prefix}-growi-efs-sg"
  growi_efs_az       = coalesce(var.growi_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
  orangehrm_efs_name = "${local.name_prefix}-orangehrm-efs"
  orangehrm_efs_sg   = "${local.name_prefix}-orangehrm-efs-sg"
  orangehrm_efs_az   = coalesce(var.orangehrm_efs_availability_zone, try(local.private_subnets[0].az, null), "${var.region}a")
}

data "aws_resourcegroupstaggingapi_resources" "growi_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.growi_efs_name]
  }
}

data "aws_resourcegroupstaggingapi_resources" "orangehrm_efs" {
  resource_type_filters = ["elasticfilesystem"]

  tag_filter {
    key    = "Name"
    values = [local.orangehrm_efs_name]
  }
}

locals {
  growi_existing_efs_id          = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.growi_efs.resource_tag_mapping_list[0].resource_arn), null)
  orangehrm_existing_efs_id      = try(regex("fs-[0-9a-f]+", data.aws_resourcegroupstaggingapi_resources.orangehrm_efs.resource_tag_mapping_list[0].resource_arn), null)
  create_growi_efs_effective     = (var.create_growi_efs || (var.create_ecs && var.create_growi)) && var.growi_filesystem_id == null
  create_orangehrm_efs_effective = (var.create_orangehrm_efs || (var.create_ecs && var.create_orangehrm)) && var.orangehrm_filesystem_id == null
}

resource "aws_security_group" "growi_efs" {
  count = local.create_growi_efs_effective && var.growi_filesystem_id == null ? 1 : 0

  name        = local.growi_efs_sg
  description = "EFS access for GROWI"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.growi_efs_sg })
}

resource "aws_security_group" "orangehrm_efs" {
  count = local.create_orangehrm_efs_effective && var.orangehrm_filesystem_id == null ? 1 : 0

  name        = local.orangehrm_efs_sg
  description = "EFS access for OrangeHRM"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.orangehrm_efs_sg })
}

locals {
  growi_filesystem_id_effective = (
    var.growi_filesystem_id != null && var.growi_filesystem_id != "" ? var.growi_filesystem_id :
    local.growi_existing_efs_id != null && local.growi_existing_efs_id != "" ? local.growi_existing_efs_id :
    local.create_growi_efs_effective ? try(aws_efs_file_system.growi[0].id, null) : null
  )
  orangehrm_filesystem_id_effective = (
    var.orangehrm_filesystem_id != null && var.orangehrm_filesystem_id != "" ? var.orangehrm_filesystem_id :
    local.orangehrm_existing_efs_id != null && local.orangehrm_existing_efs_id != "" ? local.orangehrm_existing_efs_id :
    local.create_orangehrm_efs_effective ? try(aws_efs_file_system.orangehrm[0].id, null) : null
  )
}

resource "aws_efs_file_system" "growi" {
  count = local.create_growi_efs_effective && var.growi_filesystem_id == null ? 1 : 0

  availability_zone_name = local.growi_efs_az
  encrypted              = true
  throughput_mode        = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, { Name = local.growi_efs_name })
}

resource "aws_efs_file_system" "orangehrm" {
  count = local.create_orangehrm_efs_effective && var.orangehrm_filesystem_id == null ? 1 : 0

  availability_zone_name = local.orangehrm_efs_az
  encrypted              = true
  throughput_mode        = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, { Name = local.orangehrm_efs_name })
}

locals {
  growi_efs_subnet     = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
  orangehrm_efs_subnet = length(local.private_subnets) > 0 ? local.private_subnets[0] : null
}

resource "aws_efs_mount_target" "growi" {
  count = local.create_growi_efs_effective ? 1 : 0

  file_system_id  = local.growi_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.growi_efs_subnet.name]
  security_groups = [aws_security_group.growi_efs[0].id]
}

resource "aws_efs_mount_target" "orangehrm" {
  count = local.create_orangehrm_efs_effective ? 1 : 0

  file_system_id  = local.orangehrm_filesystem_id_effective
  subnet_id       = local.private_subnet_ids[local.orangehrm_efs_subnet.name]
  security_groups = [aws_security_group.orangehrm_efs[0].id]
}
