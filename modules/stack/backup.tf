locals {
  backup_vault_name = "${local.name_prefix}-backup-vault"
  backup_plan_name  = "${local.name_prefix}-efs-backup-plan"
  backup_role_name  = "${local.name_prefix}-backup-role"
  backup_resource_arns = compact([
    local.n8n_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.n8n_filesystem_id_effective}" : null,
    local.pgadmin_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.pgadmin_filesystem_id_effective}" : null,
    local.keycloak_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.keycloak_filesystem_id_effective}" : null,
    local.odoo_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.odoo_filesystem_id_effective}" : null,
    local.cmdbuild_r2u_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.cmdbuild_r2u_filesystem_id_effective}" : null,
    local.gitlab_data_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.gitlab_data_filesystem_id_effective}" : null,
    local.gitlab_config_filesystem_id_effective != null ? "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${local.gitlab_config_filesystem_id_effective}" : null
  ])
}

resource "aws_backup_vault" "efs" {
  name = local.backup_vault_name

  tags = merge(local.tags, { Name = local.backup_vault_name })
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = local.backup_role_name
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json

  tags = merge(local.tags, { Name = local.backup_role_name })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "efs" {
  name = local.backup_plan_name

  rule {
    rule_name         = "${local.name_prefix}-daily"
    target_vault_name = aws_backup_vault.efs.name
    schedule          = "cron(0 18 * * ? *)" # 03:00 JST

    lifecycle {
      delete_after = 2
    }
  }

  tags = merge(local.tags, { Name = local.backup_plan_name })
}

resource "aws_backup_selection" "efs" {
  count        = 1
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.name_prefix}-efs-selection"
  plan_id      = aws_backup_plan.efs.id
  resources    = local.backup_resource_arns
}
