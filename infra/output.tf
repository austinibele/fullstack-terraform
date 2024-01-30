output "ecr_repo_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repo_path" {
  value = aws_ecr_repository.main.name
}

output "aws_region" {
  value = var.aws_region
}

output "aws_iam_access_id" {
  value = module.ecr_ecs_ci_user.aws_iam_access_id
}

output "aws_iam_access_key" {
  value = module.ecr_ecs_ci_user.aws_iam_access_key
  sensitive = true
}

output "alb_url" {
  value = module.alb.lb.dns_name
}

output "backend_alb_url" {
  value = module.backend_alb.lb.dns_name
}

output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "db_host" {
  description = "The hostname of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_name" {
  sensitive = true
  value = var.db_name
}

output "db_port" {
  value = var.db_port
}
