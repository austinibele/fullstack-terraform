
resource "aws_ecr_repository" "backend" {
  name                 = "web/${var.project_id}/backend"
  image_tag_mutability = "IMMUTABLE"
}


# External ALB for backend services
resource "aws_lb" "external_alb" {
  name               = "alb-external-${var.project_id}-${var.env}"
  internal           = false  # Set to false to make the load balancer external
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_alb_sg.id]
  subnets            = module.networking.public_subnets[*].id  # Use public subnets for external ALB
}

resource "aws_lb_listener" "external_listener" {
  load_balancer_arn = aws_lb.external_alb.arn 
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg-${var.project_id}-${var.env}"
  port     = 5252
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id
  target_type = "ip" # Ensure this is set to 'ip'

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Update the security group to allow access from the internet
resource "aws_security_group" "external_alb_sg" {
  vpc_id = module.networking.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]  # Allows access from anywhere on the internet
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]  # Allows all outbound traffic
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
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 5252
  }

  network_configuration {
    subnets         = module.networking.private_subnets[*].id
    security_groups = [aws_security_group.ecs_sg.id]
  }

  tags = {
    Name = "backend-service-${var.project_id}-${var.env}"
  }
}