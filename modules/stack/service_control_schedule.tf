locals {
  service_control_services = [
    "keycloak",
    "zulip",
    "growi",
    "odoo",
    "orangehrm",
    "cmdbuild-r2u",
    "n8n",
    "sulu",
    "exastro-web",
    "exastro-api",
    "gitlab",
    "pgadmin",
    "phpmyadmin"
  ]
  service_control_ssm_path = "/${local.name_prefix}/service-control"
  default_service_control_schedule = {
    for svc in local.service_control_services : svc => {
      enabled      = contains(["keycloak", "n8n", "zulip"], svc)
      start_time   = "14:00"
      stop_time    = "22:00"
      idle_minutes = 60
    }
  }
  service_control_schedule_map = merge(local.default_service_control_schedule, var.service_control_schedule_overrides)
}

resource "aws_ssm_parameter" "service_control_schedule" {
  for_each = var.create_ecs && var.create_ssm_parameters ? local.service_control_schedule_map : {}

  name      = "${local.service_control_ssm_path}/${each.key}/schedule"
  type      = "String"
  value     = jsonencode(each.value)
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-svc-control-${each.key}-schedule" })
}
