output "vpc_id" {
  description = "Shared VPC ID."
  value       = aws_vpc.core.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by internet-facing portal instances."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs reserved for internal services."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs used by RDS."
  value       = aws_subnet.private_db[*].id
}

output "db_subnet_group_name" {
  description = "Database subnet group name."
  value       = aws_db_subnet_group.postgres.name
}

output "tenant_instance_ids" {
  description = "EC2 instance IDs by tenant role."
  value       = { for k, v in aws_instance.tenant_portal : k => v.id }
}

output "tenant_instance_public_ips" {
  description = "Public IPs for tenant portal EC2 instances."
  value       = { for k, v in aws_instance.tenant_portal : k => v.public_ip }
}

output "rds_endpoint" {
  description = "PostgreSQL endpoint."
  value       = aws_db_instance.postgres.address
}

output "s3_bucket_name" {
  description = "S3 bucket for payroll documents and reports."
  value       = aws_s3_bucket.payroll_docs.bucket
}

output "tenant_security_group_ids" {
  description = "Security groups per tenant boundary."
  value       = { for k, v in aws_security_group.portal_ec2 : k => v.id }
}

output "rds_security_group_id" {
  description = "Security group protecting the database layer."
  value       = aws_security_group.rds.id
}

output "runtime_parameter_paths" {
  description = "SSM parameter paths used for runtime configuration and secrets."
  value = {
    shared = {
      db_host = aws_ssm_parameter.db_host.name
      db_port = aws_ssm_parameter.db_port.name
      db_name = aws_ssm_parameter.db_name.name
    }
    companies = {
      db_username = aws_ssm_parameter.company_db_username.name
      db_password = aws_ssm_parameter.company_db_password.name
    }
    bureaus = {
      db_username = aws_ssm_parameter.bureau_db_username.name
      db_password = aws_ssm_parameter.bureau_db_password.name
    }
    employees = {
      db_username = aws_ssm_parameter.employee_db_username.name
      db_password = aws_ssm_parameter.employee_db_password.name
    }
  }
}

output "critical_alerts_topic_arn" {
  description = "SNS topic ARN for critical infrastructure alerts."
  value       = aws_sns_topic.critical_alerts.arn
}

output "application_log_group_names" {
  description = "CloudWatch application log group names by tenant portal."
  value       = { for k, v in aws_cloudwatch_log_group.application : k => v.name }
}

output "infrastructure_log_group_names" {
  description = "CloudWatch infrastructure log group names."
  value       = { for k, v in aws_cloudwatch_log_group.infrastructure : k => v.name }
}