data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "eureka" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_ecs_cluster" "main" {
  name = var.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_iam_role" "task_execution" {
  name = "${var.name_prefix}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Eureka port from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Peer replication between Eureka tasks on container port
  ingress {
    description = "Eureka peer replication"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    self        = true
  }

  # Peer communication between ECS services via port 80
  ingress {
    description = "Inter-node cluster communication"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-ecs-sg" })
}

# Separate rule resource to avoid a Terraform cycle (ALB SG ↔ ECS tasks SG).
# Allows tasks to reach the ALB via the private DNS CNAMEs for peer replication.
resource "aws_security_group_rule" "alb_from_ecs_tasks" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  security_group_id        = aws_security_group.alb.id
  description              = "Eureka peer replication from ECS tasks"
}

resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = var.tags
}

resource "aws_lb_target_group" "eureka" {
  count       = 2
  name        = "${var.name_prefix}-tg-${count.index}"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }

  tags = var.tags
}

# Default action distributes evenly across both services (handles service-registry.eurika.internal)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.eureka[0].arn
        weight = 1
      }
      target_group {
        arn    = aws_lb_target_group.eureka[1].arn
        weight = 1
      }
    }
  }
}

# Host-header rules route service-registry-{0,1}.eurika.internal to their dedicated target group
resource "aws_lb_listener_rule" "eureka" {
  count        = 2
  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + count.index

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eureka[count.index].arn
  }

  condition {
    host_header {
      values = ["service-registry-${count.index}.${var.private_zone_name}"]
    }
  }
}

resource "aws_ecs_task_definition" "eureka" {
  count                    = 2
  family                   = "${var.name_prefix}-task-${count.index}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([{
    name      = "eureka-server"
    image     = var.image_uri
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "EUREKA_HOSTNAME"
        value = var.eureka_config[count.index].eureka_instance_hostname
      },
      {
        name  = "EUREKA_SERVICE_URL"
        value = var.eureka_config[count.index].eureka_service_url
      },
      {
        name  = "EUREKA_SELF_PRESERVATION"
        value = tostring(var.enable_self_preservation)
      },
      {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.environment
      }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "wget -q -O- http://localhost:${var.container_port}/actuator/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.eureka.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "eureka"
      }
    }
  }])

  tags = var.tags
}

# Two services, each pinned to one AZ via a single subnet, each backed by its own target group
resource "aws_ecs_service" "eureka" {
  count           = 2
  name            = "${var.name_prefix}-service-${count.index}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.eureka[count.index].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.task_subnets[count.index]]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.eureka[count.index].arn
    container_name   = "eureka-server"
    container_port   = var.container_port
  }

  health_check_grace_period_seconds  = 90
  deployment_minimum_healthy_percent = var.environment == "prod" ? 100 : 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}

# service-registry-{0,1}.eurika.internal → dedicated target group via ALB host-header rule
resource "aws_route53_record" "eureka_service" {
  count   = 2
  zone_id = var.private_zone_id
  name    = "service-registry-${count.index}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.main.dns_name]
}

# service-registry.eurika.internal → weighted default action across both target groups
resource "aws_route53_record" "eureka_shared" {
  zone_id = var.private_zone_id
  name    = "service-registry"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.main.dns_name]
}
