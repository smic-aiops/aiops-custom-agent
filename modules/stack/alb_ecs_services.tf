locals {
  alb_name             = "${local.name_prefix}-alb"
  alb_sg_name          = "${local.name_prefix}-alb-sg"
  ecs_service_sg       = "${local.name_prefix}-ecs-sg"
  tg_n8n_name          = "${local.name_prefix}-n8n-tg"
  tg_zulip_name        = "${local.name_prefix}-zulip-tg"
  tg_exastro_web_name  = "${local.name_prefix}-exastro-web-tg"
  tg_exastro_api_name  = "${local.name_prefix}-exastro-api-tg"
  tg_sulu_name         = "${local.name_prefix}-sulu-tg"
  tg_pgadmin_name      = "${local.name_prefix}-pgadmin-tg"
  tg_phpmyadmin_name   = "${local.name_prefix}-phpmyadmin-tg"
  tg_keycloak_name     = "${local.name_prefix}-keycloak-tg"
  tg_odoo_name         = "${local.name_prefix}-odoo-tg"
  tg_gitlab_name       = "${local.name_prefix}-gitlab-tg"
  tg_growi_name        = "${local.name_prefix}-growi-tg"
  tg_cmdbuild_r2u_name = "${local.name_prefix}-cmdbuild-r2u-tg"
  tg_orangehrm_name    = "${local.name_prefix}-orangehrm-tg"
  n8n_host             = "${local.service_subdomain_map["n8n"]}.${local.hosted_zone_name_input}"
  zulip_host           = "${local.service_subdomain_map["zulip"]}.${local.hosted_zone_name_input}"
  exastro_web_host     = "${local.service_subdomain_map["exastro_web"]}.${local.hosted_zone_name_input}"
  exastro_api_host     = "${local.service_subdomain_map["exastro_api"]}.${local.hosted_zone_name_input}"
  sulu_host            = "${local.service_subdomain_map["sulu"]}.${local.hosted_zone_name_input}"
  pgadmin_host         = "${local.service_subdomain_map["pgadmin"]}.${local.hosted_zone_name_input}"
  phpmyadmin_host      = "${local.service_subdomain_map["phpmyadmin"]}.${local.hosted_zone_name_input}"
  keycloak_host        = "${local.service_subdomain_map["keycloak"]}.${local.hosted_zone_name_input}"
  odoo_host            = "${local.service_subdomain_map["odoo"]}.${local.hosted_zone_name_input}"
  gitlab_host          = "${local.service_subdomain_map["gitlab"]}.${local.hosted_zone_name_input}"
  growi_host           = "${local.service_subdomain_map["growi"]}.${local.hosted_zone_name_input}"
  cmdbuild_r2u_host    = "${local.service_subdomain_map["cmdbuild_r2u"]}.${local.hosted_zone_name_input}"
  orangehrm_host       = "${local.service_subdomain_map["orangehrm"]}.${local.hosted_zone_name_input}"
  alb_cert_name        = "${local.name_prefix}-alb-cert"
  service_subnet_keys  = sort(keys(local.private_subnet_ids))
  service_subnet_id    = local.private_subnet_ids[local.service_subnet_keys[0]]
}

resource "aws_security_group" "alb" {
  count = var.create_ecs ? 1 : 0

  name        = local.alb_sg_name
  description = "ALB security group"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = local.alb_sg_name })
}

resource "aws_security_group" "ecs_service" {
  count = var.create_ecs ? 1 : 0

  name        = local.ecs_service_sg
  description = "ECS service security group"
  vpc_id      = local.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.create_gitlab && length(var.gitlab_ssh_cidr_blocks) > 0 ? [1] : []
    content {
      description = "GitLab SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.gitlab_ssh_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = var.create_keycloak ? [1] : []
    content {
      description = "Keycloak JGroups cluster"
      from_port   = 7800
      to_port     = 7800
      protocol    = "tcp"
      self        = true
    }
  }

  tags = merge(local.tags, { Name = local.ecs_service_sg })
}

resource "aws_lb" "app" {
  count = var.create_ecs ? 1 : 0

  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = values(local.public_subnet_ids)

  tags = merge(local.tags, { Name = local.alb_name })
}

resource "aws_lb_target_group" "n8n" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  name_prefix = "n8n-"
  port        = 5678
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/healthz"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_n8n_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "zulip" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  name_prefix = "zul-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-499" # Zulip returns 400 for invalid Host headers used by ALB health checks
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_zulip_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "exastro_web" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  name_prefix = "itaw-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_exastro_web_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "exastro_api_admin" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  name_prefix = "itaa-"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_exastro_api_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "sulu" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  name_prefix = "mains-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_sulu_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "keycloak" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  name_prefix = "kc-"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    # Keycloak 26 exposes health endpoints on the management port 9000
    path                = "/health/ready"
    port                = "9000"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_keycloak_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "odoo" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  name_prefix = "odoo-"
  port        = 8069
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_odoo_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "pgadmin" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  name_prefix = "pgadm-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/misc/ping"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_pgadmin_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "phpmyadmin" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  name_prefix = "pma-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_phpmyadmin_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "gitlab" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  name_prefix = "gitlb-"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    # GitLab Omnibus exposes a lightweight liveness endpoint
    path                = "/-/liveness"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_gitlab_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "growi" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  name_prefix = "gro-"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_growi_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "cmdbuild_r2u" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  name_prefix = "cmdb-"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    # CMDBuild Ready2Use app redirects to /cmdbuild; probe that path directly
    path                = "/cmdbuild"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_cmdbuild_r2u_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "orangehrm" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  name_prefix = "ohrm-"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.tags, { Name = local.tg_orangehrm_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = var.create_ecs ? 1 : 0

  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_acm_certificate" "alb" {
  count             = var.create_ecs ? 1 : 0
  domain_name       = "*.${local.hosted_zone_name_input}"
  validation_method = "DNS"
  tags              = merge(local.tags, { Name = local.alb_cert_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_cert_validation" {
  for_each = var.create_ecs ? { for dvo in aws_acm_certificate.alb[0].domain_validation_options : dvo.domain_name => dvo } : {}

  zone_id         = local.hosted_zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  count                   = var.create_ecs ? 1 : 0
  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for r in aws_route53_record.alb_cert_validation : r.fqdn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "https" {
  count = var.create_ecs ? 1 : 0

  load_balancer_arn = aws_lb.app[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.alb[0].certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "n8n" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n[0].arn
  }

  condition {
    host_header {
      values = [local.n8n_host]
    }
  }
}

resource "aws_lb_listener_rule" "n8n_header" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["n8n"]
    }
  }
}

resource "aws_lb_listener_rule" "n8n_http" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n[0].arn
  }

  condition {
    host_header {
      values = [local.n8n_host]
    }
  }
}

resource "aws_lb_listener_rule" "n8n_http_header" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["n8n"]
    }
  }
}

resource "aws_lb_listener_rule" "zulip_header" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 17

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zulip[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["zulip"]
    }
  }
}

resource "aws_lb_listener_rule" "zulip" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 18

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zulip[0].arn
  }

  condition {
    host_header {
      values = [local.zulip_host]
    }
  }
}

resource "aws_lb_listener_rule" "zulip_http_header" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 17

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zulip[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["zulip"]
    }
  }
}

resource "aws_lb_listener_rule" "zulip_http" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 18

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zulip[0].arn
  }

  condition {
    host_header {
      values = [local.zulip_host]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_web_http_header" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 22

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_web[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["exastro-web"]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_web_http" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 24

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_web[0].arn
  }

  condition {
    host_header {
      values = [local.exastro_web_host]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_api_http_header" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 26

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_api_admin[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["exastro-api"]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_api_http" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 28

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_api_admin[0].arn
  }

  condition {
    host_header {
      values = [local.exastro_api_host]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_web_header" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 22

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_web[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["exastro-web"]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_web" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 24

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_web[0].arn
  }

  condition {
    host_header {
      values = [local.exastro_web_host]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_api_header" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 26

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_api_admin[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["exastro-api"]
    }
  }
}

resource "aws_lb_listener_rule" "exastro_api" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 28

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.exastro_api_admin[0].arn
  }

  condition {
    host_header {
      values = [local.exastro_api_host]
    }
  }
}

resource "aws_lb_listener_rule" "sulu" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sulu[0].arn
  }

  condition {
    host_header {
      values = [local.sulu_host]
    }
  }
}

resource "aws_lb_listener_rule" "sulu_http" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sulu[0].arn
  }

  condition {
    host_header {
      values = [local.sulu_host]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 41

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak[0].arn
  }

  condition {
    host_header {
      values = [local.keycloak_host]
    }
  }
}

resource "aws_lb_listener_rule" "odoo_header" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 42

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.odoo[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["odoo"]
    }
  }
}

resource "aws_lb_listener_rule" "odoo" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 44

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.odoo[0].arn
  }

  condition {
    host_header {
      values = [local.odoo_host]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak_root_redirect" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 37

  action {
    type = "redirect"
    redirect {
      host        = local.keycloak_host
      path        = "/realms/master/"
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_302"
    }
  }

  condition {
    host_header {
      values = [local.keycloak_host]
    }
  }

  condition {
    path_pattern {
      values = ["/", "/index.html"]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak_header" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 39

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["keycloak"]
    }
  }
}

resource "aws_lb_listener_rule" "pgadmin_header" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 43

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgadmin[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["pgadmin"]
    }
  }
}

resource "aws_lb_listener_rule" "phpmyadmin_header" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 46

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [1] : []
    content {
      type  = "authenticate-oidc"
      order = 1
      authenticate_oidc {
        authorization_endpoint     = local.keycloak_auth_url
        token_endpoint             = local.keycloak_token_url
        user_info_endpoint         = local.keycloak_userinfo_url
        issuer                     = local.keycloak_issuer_url
        client_id                  = local.phpmyadmin_oidc_client_id_value
        client_secret              = local.phpmyadmin_oidc_client_secret_value
        on_unauthenticated_request = "authenticate"
        scope                      = "openid email profile"
        session_cookie_name        = "${local.name_prefix}-phpmyadmin-auth"
        session_timeout            = 86400
      }
    }
  }

  action {
    type             = "forward"
    order            = var.enable_phpmyadmin_alb_oidc ? 2 : 1
    target_group_arn = aws_lb_target_group.phpmyadmin[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["phpmyadmin"]
    }
  }
}

resource "aws_lb_listener_rule" "pgadmin" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgadmin[0].arn
  }

  condition {
    host_header {
      values = [local.pgadmin_host]
    }
  }
}

resource "aws_lb_listener_rule" "phpmyadmin" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 52

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [1] : []
    content {
      type  = "authenticate-oidc"
      order = 1
      authenticate_oidc {
        authorization_endpoint     = local.keycloak_auth_url
        token_endpoint             = local.keycloak_token_url
        user_info_endpoint         = local.keycloak_userinfo_url
        issuer                     = local.keycloak_issuer_url
        client_id                  = local.phpmyadmin_oidc_client_id_value
        client_secret              = local.phpmyadmin_oidc_client_secret_value
        on_unauthenticated_request = "authenticate"
        scope                      = "openid email profile"
        session_cookie_name        = "${local.name_prefix}-phpmyadmin-auth"
        session_timeout            = 86400
      }
    }
  }

  action {
    type             = "forward"
    order            = var.enable_phpmyadmin_alb_oidc ? 2 : 1
    target_group_arn = aws_lb_target_group.phpmyadmin[0].arn
  }

  condition {
    host_header {
      values = [local.phpmyadmin_host]
    }
  }
}

resource "aws_lb_listener_rule" "gitlab_header" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 55

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["gitlab"]
    }
  }
}

resource "aws_lb_listener_rule" "gitlab" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab[0].arn
  }

  condition {
    host_header {
      values = [local.gitlab_host]
    }
  }
}

resource "aws_lb_listener_rule" "growi" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 65

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.growi[0].arn
  }

  condition {
    host_header {
      values = [local.growi_host]
    }
  }
}

resource "aws_lb_listener_rule" "cmdbuild_r2u" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 66

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cmdbuild_r2u[0].arn
  }

  condition {
    host_header {
      values = [local.cmdbuild_r2u_host]
    }
  }
}

resource "aws_lb_listener_rule" "orangehrm" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 67

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orangehrm[0].arn
  }

  condition {
    host_header {
      values = [local.orangehrm_host]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak_http" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 41

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak[0].arn
  }

  condition {
    host_header {
      values = [local.keycloak_host]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak_http_root_redirect" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 37

  action {
    type = "redirect"
    redirect {
      host        = local.keycloak_host
      path        = "/realms/master/"
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_302"
    }
  }

  condition {
    host_header {
      values = [local.keycloak_host]
    }
  }

  condition {
    path_pattern {
      values = ["/", "/index.html"]
    }
  }
}

resource "aws_lb_listener_rule" "keycloak_http_header" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 39

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["keycloak"]
    }
  }
}

resource "aws_lb_listener_rule" "odoo_http_header" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 42

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.odoo[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["odoo"]
    }
  }
}

resource "aws_lb_listener_rule" "odoo_http" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 44

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.odoo[0].arn
  }

  condition {
    host_header {
      values = [local.odoo_host]
    }
  }
}

resource "aws_lb_listener_rule" "pgadmin_http_header" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 43

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgadmin[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["pgadmin"]
    }
  }
}

resource "aws_lb_listener_rule" "phpmyadmin_http_header" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 46

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_302"
      }
    }
  }

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.phpmyadmin[0].arn
    }
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["phpmyadmin"]
    }
  }
}

resource "aws_lb_listener_rule" "pgadmin_http" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 51

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgadmin[0].arn
  }

  condition {
    host_header {
      values = [local.pgadmin_host]
    }
  }
}

resource "aws_lb_listener_rule" "phpmyadmin_http" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 52

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_302"
      }
    }
  }

  dynamic "action" {
    for_each = var.enable_phpmyadmin_alb_oidc ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.phpmyadmin[0].arn
    }
  }

  condition {
    host_header {
      values = [local.phpmyadmin_host]
    }
  }
}

resource "aws_lb_listener_rule" "gitlab_http_header" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 55

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab[0].arn
  }

  condition {
    http_header {
      http_header_name = "X-Service-Key"
      values           = ["gitlab"]
    }
  }
}

resource "aws_lb_listener_rule" "gitlab_http" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab[0].arn
  }

  condition {
    host_header {
      values = [local.gitlab_host]
    }
  }
}

resource "aws_lb_listener_rule" "growi_http" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 65

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.growi[0].arn
  }

  condition {
    host_header {
      values = [local.growi_host]
    }
  }
}

resource "aws_lb_listener_rule" "cmdbuild_r2u_http" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 66

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cmdbuild_r2u[0].arn
  }

  condition {
    host_header {
      values = [local.cmdbuild_r2u_host]
    }
  }
}

resource "aws_lb_listener_rule" "orangehrm_http" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 67

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orangehrm[0].arn
  }

  condition {
    host_header {
      values = [local.orangehrm_host]
    }
  }
}

resource "aws_route53_record" "n8n" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.n8n_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "zulip" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.zulip_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "exastro_web" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.exastro_web_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "exastro_api" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.exastro_api_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "pgadmin" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.pgadmin_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "phpmyadmin" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.phpmyadmin_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sulu" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.sulu_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "keycloak" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.keycloak_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "odoo" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.odoo_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "gitlab" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.gitlab_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "growi" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.growi_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cmdbuild_r2u" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.cmdbuild_r2u_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "orangehrm" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  zone_id         = local.hosted_zone_id
  name            = local.orangehrm_host
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.app[0].dns_name
    zone_id                = aws_lb.app[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_ecs_service" "n8n" {
  count = var.create_ecs && var.create_n8n ? 1 : 0

  name                   = "${local.name_prefix}-n8n"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.n8n[0].arn
  desired_count          = var.n8n_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.n8n[0].arn
    container_name   = "n8n"
    container_port   = 5678
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-n8n-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "exastro_web" {
  count = var.create_ecs && var.create_exastro_web_server ? 1 : 0

  name                   = "${local.name_prefix}-exastro-web"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.exastro_web[0].arn
  desired_count          = var.exastro_web_server_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.exastro_web[0].arn
    container_name   = "exastro-web"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-web-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "exastro_api_admin" {
  count = var.create_ecs && var.create_exastro_api_admin ? 1 : 0

  name                   = "${local.name_prefix}-exastro-api"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.exastro_api_admin[0].arn
  desired_count          = var.exastro_api_admin_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.exastro_api_admin[0].arn
    container_name   = "exastro-api"
    container_port   = 8000
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-exastro-api-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "sulu" {
  count = var.create_ecs && var.create_sulu ? 1 : 0

  name                   = "${local.name_prefix}-sulu"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.sulu[0].arn
  desired_count          = var.sulu_desired_count
  launch_type            = "FARGATE"
  health_check_grace_period_seconds = var.sulu_health_check_grace_period_seconds
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sulu[0].arn
    container_name   = "sulu"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-sulu-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "keycloak" {
  count = var.create_ecs && var.create_keycloak ? 1 : 0

  name                   = "${local.name_prefix}-keycloak"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.keycloak[0].arn
  desired_count          = var.keycloak_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.keycloak[0].arn
    container_name   = "keycloak"
    container_port   = 8080
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-keycloak-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "odoo" {
  count = var.create_ecs && var.create_odoo ? 1 : 0

  name                   = "${local.name_prefix}-odoo"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.odoo[0].arn
  desired_count          = var.odoo_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.odoo[0].arn
    container_name   = "odoo"
    container_port   = 8069
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-odoo-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "pgadmin" {
  count = var.create_ecs && var.create_pgadmin ? 1 : 0

  name                   = "${local.name_prefix}-pgadmin"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.pgadmin[0].arn
  desired_count          = var.pgadmin_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pgadmin[0].arn
    container_name   = "pgadmin"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-pgadmin-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "phpmyadmin" {
  count = var.create_ecs && var.create_phpmyadmin ? 1 : 0

  name                   = "${local.name_prefix}-phpmyadmin"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.phpmyadmin[0].arn
  desired_count          = var.phpmyadmin_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.phpmyadmin[0].arn
    container_name   = "phpmyadmin"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-phpmyadmin-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "gitlab" {
  count = var.create_ecs && var.create_gitlab ? 1 : 0

  name                              = "${local.name_prefix}-gitlab"
  cluster                           = aws_ecs_cluster.this[0].id
  task_definition                   = aws_ecs_task_definition.gitlab[0].arn
  desired_count                     = var.gitlab_desired_count
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = var.gitlab_health_check_grace_period_seconds

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gitlab[0].arn
    container_name   = "gitlab"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-gitlab-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "growi" {
  count = var.create_ecs && var.create_growi ? 1 : 0

  name                   = "${local.name_prefix}-growi"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.growi[0].arn
  desired_count          = var.growi_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.growi[0].arn
    container_name   = "growi"
    container_port   = 3000
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-growi-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "cmdbuild_r2u" {
  count = var.create_ecs && var.create_cmdbuild_r2u ? 1 : 0

  name                   = "${local.name_prefix}-cmdbuild-r2u"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.cmdbuild_r2u[0].arn
  desired_count          = var.cmdbuild_r2u_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cmdbuild_r2u[0].arn
    container_name   = "cmdbuild-r2u"
    container_port   = 8080
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cmdbuild-r2u-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "orangehrm" {
  count = var.create_ecs && var.create_orangehrm ? 1 : 0

  name                   = "${local.name_prefix}-orangehrm"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.orangehrm[0].arn
  desired_count          = var.orangehrm_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orangehrm[0].arn
    container_name   = "orangehrm"
    container_port   = 8080
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-orangehrm-svc" })

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "zulip" {
  count = var.create_ecs && var.create_zulip ? 1 : 0

  name                   = "${local.name_prefix}-zulip"
  cluster                = aws_ecs_cluster.this[0].id
  task_definition        = aws_ecs_task_definition.zulip[0].arn
  desired_count          = var.zulip_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [local.service_subnet_id]
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.zulip[0].arn
    container_name   = "zulip"
    container_port   = 80
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-zulip-svc" })

  depends_on = [aws_lb_listener.https]
}
