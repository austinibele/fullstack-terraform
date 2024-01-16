output "ecr_repo_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "frontend_ecr_repo_path" {
  value = aws_ecr_repository.frontend.name
}

output "backend_ecr_repo_path" {
  value = aws_ecr_repository.backend.name
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