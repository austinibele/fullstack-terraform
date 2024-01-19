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
  default = "postgres" 
}

variable "db_name" {
  default = "postgres"
}

variable "db_username" {
  default = "postgres"
}

variable "db_port" {
  default = 5432
}

variable "db_storage" {
  default = 20
}
