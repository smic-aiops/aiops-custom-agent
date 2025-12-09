locals {
  rds_identifier          = coalesce(var.rds_identifier, "${local.name_prefix}-pg")
  rds_subnet_group_name   = "${local.name_prefix}-db-subnets"
  rds_security_group_name = "${local.name_prefix}-rds-sg"
  master_username         = coalesce(var.pg_db_username, "${var.platform}user")
  # RDS master password: 8-128 chars, must include upper/lower/digit/special, avoid "/" and "\"".
  db_password_effective = coalesce(var.pg_db_password, try(random_password.master[0].result, null))
}

resource "aws_security_group" "rds" {
  count       = var.create_rds ? 1 : 0
  name        = local.rds_security_group_name
  description = "PostgreSQL access"
  vpc_id      = local.vpc_id

  ingress {
    description = "Postgres from ECS services"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ecs_service[0].id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.rds_security_group_name })
}

locals {
  rds_sg_id = var.create_rds ? try(aws_security_group.rds[0].id, null) : null
}

resource "random_password" "master" {
  count            = var.create_rds && var.pg_db_password == null ? 1 : 0
  length           = 16
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%^&*()-_+=" # exclude '/', '"', '@'
}

resource "aws_db_subnet_group" "this" {
  count = var.create_rds ? 1 : 0

  name       = local.rds_subnet_group_name
  subnet_ids = values(local.private_subnet_ids)

  tags = merge(local.tags, { Name = local.rds_subnet_group_name })
}

resource "aws_db_instance" "this" {
  count = var.create_rds ? 1 : 0

  identifier = local.rds_identifier

  engine         = "postgres"
  engine_version = var.rds_engine_version

  instance_class          = var.rds_instance_class
  multi_az                = false
  publicly_accessible     = false
  storage_encrypted       = true
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot
  backup_retention_period = var.rds_backup_retention

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [local.rds_sg_id]

  db_name  = var.pg_db_name
  username = local.master_username
  password = local.db_password_effective

  tags = merge(local.tags, { Name = local.rds_identifier })
}
