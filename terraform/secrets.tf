data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  parameter_base_path = "${var.project_name}/${var.environment}"
}

# Shared non-secret DB connection metadata
resource "aws_ssm_parameter" "db_host" {
  name  = "${local.parameter_base_path}/shared/db/host"
  type  = "String"
  value = aws_db_instance.postgres.address

  tags = {
    Name = "${local.name_prefix}-db-host"
    Tier = "security"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "${local.parameter_base_path}/shared/db/port"
  type  = "String"
  value = tostring(aws_db_instance.postgres.port)

  tags = {
    Name = "${local.name_prefix}-db-port"
    Tier = "security"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${local.parameter_base_path}/shared/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-db-name"
    Tier = "security"
  }
}

# Tenant-scoped runtime parameters.
# The current assignment uses one shared PostgreSQL instance, so the DB username/password
# values are duplicated per tenant path to preserve IAM boundary separation at the secret path level.
resource "aws_ssm_parameter" "company_db_username" {
  name  = "${local.parameter_base_path}/companies/db/username"
  type  = "String"
  value = var.db_username

  tags = {
    Name   = "${local.name_prefix}-companies-db-username"
    Tier   = "security"
    Tenant = "companies"
  }
}

resource "aws_ssm_parameter" "company_db_password" {
  name  = "${local.parameter_base_path}/companies/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name   = "${local.name_prefix}-companies-db-password"
    Tier   = "security"
    Tenant = "companies"
  }
}

resource "aws_ssm_parameter" "bureau_db_username" {
  name  = "${local.parameter_base_path}/bureaus/db/username"
  type  = "String"
  value = var.db_username

  tags = {
    Name   = "${local.name_prefix}-bureaus-db-username"
    Tier   = "security"
    Tenant = "bureaus"
  }
}

resource "aws_ssm_parameter" "bureau_db_password" {
  name  = "${local.parameter_base_path}/bureaus/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name   = "${local.name_prefix}-bureaus-db-password"
    Tier   = "security"
    Tenant = "bureaus"
  }
}

resource "aws_ssm_parameter" "employee_db_username" {
  name  = "${local.parameter_base_path}/employees/db/username"
  type  = "String"
  value = var.db_username

  tags = {
    Name   = "${local.name_prefix}-employees-db-username"
    Tier   = "security"
    Tenant = "employees"
  }
}

resource "aws_ssm_parameter" "employee_db_password" {
  name  = "${local.parameter_base_path}/employees/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name   = "${local.name_prefix}-employees-db-password"
    Tier   = "security"
    Tenant = "employees"
  }
}