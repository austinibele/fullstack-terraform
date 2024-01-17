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
    from_port   = local.target_port
    to_port     = local.target_port
    cidr_blocks = module.networking.private_subnets[*].cidr_block
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = module.networking.vpc_id
  ingress {
    protocol         = "tcp"
    from_port        = local.target_port
    to_port          = local.target_port
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
  source              = "github.com/austinibele/tf-modules//alb?ref=v1.0.27"
  create_target_group = true
  port                = local.target_port
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = module.networking.vpc_id
  target_group_suffix = "frontend"
}

module "alb" {
  source             = "github.com/austinibele/tf-modules//alb?ref=v1.0.27"
  create_alb         = true
  enable_https       = false
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_ecs_sg.id]
  subnets            = module.networking.public_subnets[*].id
  target_group       = module.ecs_tg.tg.arn
  target_group_suffix = "frontend"
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "main" {
  name                 = "web/${var.project_id}/frontend"
  image_tag_mutability = "IMMUTABLE"
}



resource "aws_ecs_cluster" "web_cluster" {
  name = "web-cluster-${var.project_id}-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "template_file" "task_def_generated" {
  template = "${file("./task-definitions/service.json.tpl")}"
  vars = {
    env                 = var.env
    port                = local.target_port
    name                = local.ecs_container_name
    cpu                 = local.ecs_cpu
    memory              = local.ecs_memory
    aws_region          = var.aws_region
    ecs_execution_role  = module.ecs_roles.ecs_execution_role_arn
    launch_type         = local.ecs_launch_type
    network_mode        = local.ecs_network_mode
    log_group           = local.ecs_log_group
  }
}

# Create a static version of task definition for CI/CD
resource "local_file" "output_task_def" {
  content         = data.template_file.task_def_generated.rendered
  file_permission = "644"
  filename        = "./task-definitions/service.latest.json"
}

resource "aws_ecs_task_definition" "frontend" {
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
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = local.ecs_desired_count
  launch_type     = local.ecs_launch_type

  load_balancer {
    target_group_arn = module.ecs_tg.tg.arn
    container_name   = local.ecs_container_name
    container_port   = local.target_port
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