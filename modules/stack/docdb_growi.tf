locals {
  growi_docdb_cluster_identifier = "${local.name_prefix}-growi-docdb"
  growi_docdb_sg_name            = "${local.name_prefix}-growi-docdb-sg"
  growi_docdb_subnet_group_name  = "${local.name_prefix}-growi-docdb-subnets"
}

resource "aws_security_group" "growi_docdb" {
  count = var.create_ecs && var.create_growi && var.create_growi_docdb ? 1 : 0

  name        = local.growi_docdb_sg_name
  description = "DocumentDB access for GROWI"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.growi_docdb_sg_name })
}

resource "aws_docdb_subnet_group" "growi" {
  count = var.create_ecs && var.create_growi && var.create_growi_docdb ? 1 : 0

  name       = local.growi_docdb_subnet_group_name
  subnet_ids = values(local.private_subnet_ids)

  tags = merge(local.tags, { Name = local.growi_docdb_subnet_group_name })
}

resource "random_id" "growi_docdb_final_snapshot_suffix" {
  count       = var.create_ecs && var.create_growi && var.create_growi_docdb && !var.docdb_skip_final_snapshot ? 1 : 0
  byte_length = 4
}

locals {
  growi_docdb_final_snapshot_suffix               = try(random_id.growi_docdb_final_snapshot_suffix[0].hex, null)
  growi_docdb_auto_final_snapshot_identifier      = local.growi_docdb_final_snapshot_suffix != null ? format("%s-final-%s", local.growi_docdb_cluster_identifier, local.growi_docdb_final_snapshot_suffix) : null
  growi_docdb_final_snapshot_identifier_effective = var.docdb_skip_final_snapshot ? null : coalesce(var.growi_docdb_final_snapshot_identifier, local.growi_docdb_auto_final_snapshot_identifier)
}

resource "aws_docdb_cluster" "growi" {
  count = var.create_ecs && var.create_growi && var.create_growi_docdb ? 1 : 0

  cluster_identifier        = local.growi_docdb_cluster_identifier
  engine                    = "docdb"
  engine_version            = var.growi_docdb_engine_version
  master_username           = local.growi_db_username_value
  master_password           = local.growi_db_password_value
  storage_encrypted         = true
  deletion_protection       = var.docdb_deletion_protection
  apply_immediately         = true
  port                      = 27017
  skip_final_snapshot       = var.docdb_skip_final_snapshot
  final_snapshot_identifier = local.growi_docdb_final_snapshot_identifier_effective

  db_subnet_group_name   = aws_docdb_subnet_group.growi[0].name
  vpc_security_group_ids = [aws_security_group.growi_docdb[0].id]

  tags = merge(local.tags, { Name = local.growi_docdb_cluster_identifier })

  lifecycle {
    # Avoid perpetual diffs when the engine version cannot be modified due to pending changes.
    ignore_changes = [engine_version]
  }
}

resource "aws_docdb_cluster_instance" "growi" {
  count = var.create_ecs && var.create_growi && var.create_growi_docdb ? var.growi_docdb_instance_count : 0

  identifier         = "${local.growi_docdb_cluster_identifier}-${count.index}"
  cluster_identifier = aws_docdb_cluster.growi[0].id
  instance_class     = var.growi_docdb_instance_class
  engine             = aws_docdb_cluster.growi[0].engine
  apply_immediately  = true

  tags = merge(local.tags, { Name = "${local.growi_docdb_cluster_identifier}-${count.index}" })
}
