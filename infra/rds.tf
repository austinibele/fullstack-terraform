module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.project_id}-${var.env}-db"

  publicly_accessible = true

  engine            = "postgres"
  engine_version    = "16.1"  # Specify the version you want to use
  instance_class    = "db.t3.micro"  # Choose the instance size
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "mydb"
  username = "dbuser"
  password = var.db_password
  port     = "5432"

  # vpc_security_group_ids = [aws_security_group.backend_ecs_sg.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Subnets
  create_db_subnet_group = true
  subnet_ids = concat(
    module.networking.private_subnets[*].id,
    module.networking.public_subnets[*].id
    )

  # Backup
  backup_retention_period = 7
  skip_final_snapshot     = false

  # Monitoring
  monitoring_interval = 0

  # Tags
  tags = {
    Name        = "mydb-${var.project_id}-${var.env}"
    Environment = var.env
    Project     = var.project_id
  }

  # Enable deletion protection only in production
  deletion_protection = var.env == "prod" ? true : false

  # DB parameter group
  family = "postgres16"  # Match the family to the `engine_version`

  parameters = [
    {
      name  = "log_statement"
      value = "all"
    }
  ]
}

resource "aws_db_parameter_group" "default" {
  name        = "db-pg-${var.project_id}-${var.env}"
  family      = "postgres16" 

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = {
    Name        = "db-pg-${var.project_id}-${var.env}"
    Environment = var.env
    Project     = var.project_id
  }
}