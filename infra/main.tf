provider "aws" {
  region  = var.aws_region
}

locals {
  # Frontend configuration
  frontend_port = 3000
  frontend_container_name = "frontend"
  frontend_memory = 512

  # Backend configuration
  backend_port = 5252
  backend_container_name = "backend"
  backend_memory = 512

  ## ECS Service config
  ecs_launch_type = "FARGATE"
  ecs_desired_count = 2
  ecs_network_mode = "awsvpc"
  ecs_cpu = 512  # This is shared between containers if using Fargate

  ecs_memory = 1024
  ecs_log_group = "/aws/ecs/${var.project_id}-${var.env}"
  ecs_log_retention = 1
}

module "networking" {
  source = "github.com/austinibele/tf-modules//networking?ref=v1.0.25"
  env = var.env
  project_id = var.project_id
  subnet_public_cidrblock = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  subnet_private_cidrblock = [
    "10.0.11.0/24",
    "10.0.22.0/24"
  ]
  azs = ["us-east-1a", "us-east-1b"]
}

#### Security groups
resource "aws_security_group" "alb_ecs_sg" {
  vpc_id = module.networking.vpc_id

  ## Allow inbound on port 80 from internet (all traffic)
  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ## Allow outbound to ecs instances in private subnet
  egress {
    protocol    = "tcp"
    from_port   = local.frontend_port
    to_port     = local.frontend_port
    cidr_blocks = module.networking.private_subnets[*].cidr_block
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = module.networking.vpc_id

  # Frontend
  ingress {
    protocol         = "tcp"
    from_port        = local.frontend_port
    to_port          = local.frontend_port
    security_groups  = [aws_security_group.alb_ecs_sg.id]
  }

  # Backend
  ingress {
    protocol         = "tcp"
    from_port        = local.backend_port
    to_port          = local.backend_port
    security_groups  = [aws_security_group.alb_ecs_sg.id]
  }

  ## Allow ECS service to reach out to internet (download packages, pull images etc)
  egress {
    protocol         = -1
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

module "ecs_tg" {
  source              = "github.com/austinibele/tf-modules//alb?ref=v1.0.26"
  create_target_group = true
  port                = local.frontend_port
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = module.networking.vpc_id
  target_group_suffix = "frontend"
}

module "ecs_backend_tg" {
  source              = "github.com/austinibele/tf-modules//alb?ref=v1.0.26"
  create_target_group = true
  port                = local.backend_port
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = module.networking.vpc_id
  target_group_suffix = "backend"
}

## Forward /API to backend
resource "aws_lb_listener_rule" "backend" {
  listener_arn = module.alb.http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.ecs_backend_tg.tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

module "alb" {
  source             = "github.com/austinibele/tf-modules//alb?ref=v1.0.26"
  create_alb         = true
  enable_https       = false
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_ecs_sg.id]
  subnets            = module.networking.public_subnets[*].id
  target_group       = module.ecs_tg.tg.arn
  target_group_suffix = ""
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "frontend" {
  name                 = "web/${var.project_id}-frontend"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository" "backend" {
  name                 = "web/${var.project_id}-backend"
  image_tag_mutability = "IMMUTABLE"
}

## CI/CD user role for managing pipeline for AWS ECR resources
module "ecr_ecs_ci_user" {
  source            = "github.com/austinibele/tf-modules//iam/ecr?ref=v1.0.25"
  env               = var.env
  project_id        = var.project_id
  create_ci_user    = true
  # This is the ECR ARN - Feel free to add other repository as required (if you want to re-use role for CI/CD in other projects)
  ecr_resource_arns = [
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/web/${var.project_id}",
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/web/${var.project_id}/*"
  ]
}

resource "aws_ecs_cluster" "web_cluster" {
  name = "web-cluster-${var.project_id}-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = local.ecs_log_group
  retention_in_days = local.ecs_log_retention
}

data "template_file" "task_def_generated" {
  template = "${file("./task-definitions/service.json.tpl")}"
  vars = {
    env                 = var.env
    aws_region          = var.aws_region
    ecs_execution_role  = module.ecs_roles.ecs_execution_role_arn
    launch_type         = local.ecs_launch_type
    network_mode        = local.ecs_network_mode
    log_group           = local.ecs_log_group
    cpu                 = local.ecs_cpu
    memory              = local.ecs_memory

    frontend_name       = local.frontend_container_name
    frontend_memory     = local.frontend_memory
    frontend_port       = local.frontend_port

    backend_name        = local.backend_container_name
    backend_memory      = local.backend_memory
    backend_port        = local.backend_port
  }
}

# Create a static version of task definition for CI/CD
resource "local_file" "output_task_def" {
  content         = data.template_file.task_def_generated.rendered
  file_permission = "644"
  filename        = "./task-definitions/service.latest.json"
}

resource "aws_ecs_task_definition" "nextjs" {
  family                   = "task-definition-node"
  execution_role_arn       = module.ecs_roles.ecs_execution_role_arn
  task_role_arn            = module.ecs_roles.ecs_task_role_arn

  requires_compatibilities = [local.ecs_launch_type]
  network_mode             = local.ecs_network_mode
  cpu                      = local.ecs_cpu
  memory                   = local.ecs_memory
  container_definitions    = jsonencode(
    jsondecode(data.template_file.task_def_generated.rendered).containerDefinitions
  )
}

resource "aws_ecs_service" "web_ecs_service" {
  name            = "web-service-${var.project_id}-${var.env}"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.nextjs.arn
  desired_count   = local.ecs_desired_count
  launch_type     = local.ecs_launch_type

  load_balancer {
    target_group_arn = module.ecs_tg.tg.arn
    container_name   = local.frontend_container_name
    container_port   = local.frontend_port
  }

  network_configuration {
    subnets         = module.networking.private_subnets[*].id
    security_groups = [aws_security_group.ecs_sg.id]
  }

  tags = {
    Name = "web-service-${var.project_id}-${var.env}"
  }

  depends_on = [
    module.alb.lb,
    module.ecs_tg.tg
  ]
}

## Execution role and task roles
module "ecs_roles" {
  source                    = "github.com/austinibele/tf-modules//iam/ecs?ref=v1.0.1"
  create_ecs_execution_role = true
  create_ecs_task_role      = true

  # Extend baseline policy statements (ignore for now)
  ecs_execution_policies_extension = {}
}