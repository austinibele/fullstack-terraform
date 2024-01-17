
resource "aws_ecr_repository" "backend" {
  name                 = "web/${var.project_id}/backend"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecs_cluster" "backend_cluster" {
  name = "backend-cluster-${var.project_id}-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "template_file" "backend_task_def_generated" {
  template = "${file("./task-definitions/backend-service.json.tpl")}"
  vars = {
    env                 = var.env
    port                = local.backend_port
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
resource "local_file" "backend_output_task_def" {
  content         = data.template_file.backend_task_def_generated.rendered
  file_permission = "644"
  filename        = "./task-definitions/backend-service.latest.json"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "task-definition-backend"
  execution_role_arn       = module.ecs_roles.ecs_execution_role_arn
  task_role_arn            = module.ecs_roles.ecs_task_role_arn

  requires_compatibilities = [local.ecs_launch_type]
  network_mode             = local.ecs_network_mode
  cpu                      = local.ecs_cpu
  memory                   = local.ecs_memory
  container_definitions    = jsonencode(
    jsondecode(data.template_file.backend_task_def_generated.rendered).containerDefinitions
  )
}

# Use the same module for target group as in main.tf
module "backend_ecs_tg" {
  source              = "github.com/austinibele/tf-modules//alb?ref=v1.0.27"
  create_target_group = true
  port                = local.backend_port
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = module.networking.vpc_id
  target_group_suffix = "backend"
  
}

# Use the same module for ALB as in main.tf
module "backend_alb" {
  source             = "github.com/austinibele/tf-modules//alb?ref=v1.0.27"
  create_alb         = true
  enable_https       = false
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_alb_ecs_sg.id]
  subnets            = module.networking.public_subnets[*].id
  target_group       = module.backend_ecs_tg.tg.arn
  target_group_suffix = "backend"
}


resource "aws_security_group" "backend_alb_ecs_sg" {
  vpc_id = module.networking.vpc_id

  ## Allow inbound on the backend port from the internet (all traffic)
  ingress {
    protocol         = "tcp"
    from_port        = local.backend_port
    to_port          = local.backend_port
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ## Allow outbound to ECS instances in private subnet
  egress {
    protocol    = "tcp"
    from_port   = local.backend_port
    to_port     = local.backend_port
    cidr_blocks = module.networking.private_subnets[*].cidr_block
  }
}

resource "aws_security_group" "backend_ecs_sg" {
  vpc_id = module.networking.vpc_id

  ## Allow inbound on the backend port from the ALB security group
  ingress {
    protocol         = "tcp"
    from_port        = local.backend_port
    to_port          = local.backend_port
    security_groups  = [aws_security_group.backend_alb_ecs_sg.id]
  }

  ## Allow ECS service to reach out to the internet (download packages, pull images, etc.)
  egress {
    protocol         = -1
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Backend ECS Service
resource "aws_ecs_service" "backend_ecs_service" {
  name            = "backend-service-${var.project_id}-${var.env}"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = local.ecs_desired_count
  launch_type     = local.ecs_launch_type

  load_balancer {
    target_group_arn = module.backend_ecs_tg.tg.arn
    container_name   = local.backend_ecs_container_name
    container_port   = local.backend_port
  }

  network_configuration {
    subnets         = module.networking.private_subnets[*].id
    security_groups = [aws_security_group.backend_ecs_sg.id]
  }

  tags = {
    Name = "backend-service-${var.project_id}-${var.env}"
  }

  depends_on = [
    module.backend_alb.lb,
    module.backend_ecs_tg.tg
  ]
}
