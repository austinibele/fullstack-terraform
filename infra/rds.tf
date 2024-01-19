module "db" {
  source  = "terraform-aws-modules/rds/aws"

  deletion_protection = false

  manage_master_user_password = false

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.networking.private_subnets[*].id

  # Security group
  vpc_security_group_ids = [module.postgres_security_group.security_group_id]

  db_name = var.db_name
  username       = var.db_username
  password       = var.db_password
  port           = var.db_port
  identifier     = "${var.project_id}-${var.env}-db"

  engine         = "postgres"
  engine_version = "16.1"

  create_db_option_group    = false
  create_db_parameter_group = false
  parameter_group_name = aws_db_parameter_group.postgres_parameter_group.name

  allocated_storage  = var.db_storage
  instance_class     = "db.t3.micro"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = {
    Name        = "db-pg-${var.project_id}-${var.env}"
    Environment = var.env
    Project     = var.project_id
  }
}

module "postgres_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/postgresql"

  name   = "${var.project_id}-rds-sg"
  vpc_id = module.networking.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.bastion_security_group.this_security_group_id
    },
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = aws_security_group.backend_ecs_sg.id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp"]

  tags = {
    Terraform   = "true"
    Name = "${var.env}-rds-sg"
    Environment = var.env
  }
}

resource "aws_db_parameter_group" "postgres_parameter_group" {
  name        = "${var.project_id}-${var.env}-pg-parameter-group"
  family      = "postgres16"
  description = "Parameter group for PostgreSQL 16"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name        = "${var.project_id}-${var.env}-pg-parameter-group"
    Environment = var.env
    Project     = var.project_id
  }
}
