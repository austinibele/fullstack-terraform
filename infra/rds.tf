module "db" {
  source  = "terraform-aws-modules/rds/aws"

  # vpc_security_group_ids = [module.postgres_security_group.security_group_id]
  create_db_subnet_group = false
  # db_subnet_group_name   = local.create_test_resources ? var.subnet_group_name : ""

  deletion_protection = false

  username       = var.db_username
  password       = var.db_password
  port           = var.db_port
  identifier     = "${var.project_id}-${var.env}-db"
  # name           = var.db_name
  engine         = "postgres"
  engine_version = "16.1"

  create_db_option_group    = false
  create_db_parameter_group = false

  allocated_storage  = var.db_storage
  instance_class     = "db.t3.micro"
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  # maintenance_window = var.db_maintenance_window
  # backup_window      = var.db_backup_window

  tags = {
    Name        = "db-pg-${var.project_id}-${var.env}"
    Environment = var.env
    Project     = var.project_id
  }
}

# module "postgres_security_group" {
#   source  = "terraform-aws-modules/security-group/aws//modules/postgresql"

#   name   = "${var.project_id}-rds-sg"
#   vpc_id = module.networking.vpc_id
  
#   # using computed_* here to get around count issues.
#   # ingress_cidr_blocks = module.networking.subnet_private_cidrblock
#   # computed_ingress_cidr_blocks = module.networking.subnet_private_cidrblock
#   # number_of_computed_ingress_cidr_blocks = 1

#   ingress_rules       = ["postgresql-tcp"]

#   egress_cidr_blocks = ["0.0.0.0/0"]
#   egress_rules       = ["http-80-tcp", "https-443-tcp"]

#   tags = {
#     Terraform   = "true"
#     Name = "${var.env}-rds-sg"
#     Environment = var.env
#   }
# }