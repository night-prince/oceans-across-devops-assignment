resource "aws_db_instance" "postgres" {
  identifier            = "${replace(local.name_prefix, "_", "-")}-postgres"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  engine                = "postgres"
  engine_version        = "16.3"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  # Password is supplied externally at plan/apply time and mirrored into SSM Parameter Store
  # for workload runtime retrieval. No database credential is hardcoded in Terraform.
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  # RDS stays private: private DB subnet group + dedicated DB security group + no public access.
  publicly_accessible          = false
  multi_az                     = false
  storage_encrypted            = true
  backup_retention_period      = 7
  deletion_protection          = false
  skip_final_snapshot          = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false

  tags = {
    Name = "${local.name_prefix}-postgres"
    Tier = "database"
  }
}