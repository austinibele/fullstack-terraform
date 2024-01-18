module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"

  ami                         = "ami-0005e0cfe09cc9050"
  name                        = "${var.project_id}-bastion"
  associate_public_ip_address = true
  instance_type               = "t2.small"
  vpc_security_group_ids      = [module.bastion_security_group.this_security_group_id]
  subnet_ids                  = module.networking.public_subnets[*].id
#   key_name                    = var.bastion_key_name
}

module "bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.1.0"

  name   = "${var.project_id}-bastion-sg"
  vpc_id = module.networking.vpc_id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["postgresql-tcp", "http-80-tcp", "https-443-tcp"]
}

module ec2_connect_role_policy {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.7.0"

  role_name               = "${var.project_id}-rds-ec2-connect-role"
  role_requires_mfa       = false
  create_role             = true
  create_instance_profile = true

  trusted_role_services   = ["ec2.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/EC2InstanceConnect", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}
