variable "aws_region" {
  default = "us-east-1"
}

variable "project_id" {
  default = "node-app"
}

variable "env" {
  default = "prod"
}

variable "db_password" {
}

variable "db_name" {
}

variable "db_username" {
}

variable "db_port" {
  default = 5432
}

variable "db_storage" {
  default = 20
}
