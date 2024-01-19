terraform {
  cloud {
    organization = "austinibele"

    workspaces {
      name = "fullstack-terraform-template"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

locals {
  # Target port to expose
  target_port = 3000

  # Backend service port
  backend_port = 5252
  backend_ecs_container_name = "backend"

  ## ECS Service config
  ecs_launch_type = "FARGATE"
  ecs_desired_count = 2
  ecs_network_mode = "awsvpc"
  ecs_cpu = 512
  ecs_memory = 1024
  ecs_container_name = "frontend"
  ecs_log_group = "/aws/ecs/${var.project_id}-${var.env}"
  # Retention in days
  ecs_log_retention = 1
}

module "networking" {
  source = "github.com/austinibele/tf-modules//networking?ref=v1.0.29"
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

resource "aws_cloudwatch_log_group" "ecs" {
  name = local.ecs_log_group
  retention_in_days = local.ecs_log_retention
}

## Execution role and task roles
module "ecs_roles" {
  source                    = "github.com/austinibele/tf-modules//iam/ecs?ref=v1.0.1"
  create_ecs_execution_role = true
  create_ecs_task_role      = true

  # Extend baseline policy statements (ignore for now)
  ecs_execution_policies_extension = {}
}