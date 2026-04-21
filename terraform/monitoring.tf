resource "aws_sns_topic" "critical_alerts" {
  name = "${local.name_prefix}-critical-alerts"

  tags = {
    Name = "${local.name_prefix}-critical-alerts"
    Tier = "monitoring"
  }
}

resource "aws_sns_topic_subscription" "critical_email" {
  count     = var.alert_email_endpoint == "" ? 0 : 1
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_endpoint
}

# Application log groups stay separated by portal type so operational visibility
# follows the same boundary model as compute and IAM.
resource "aws_cloudwatch_log_group" "application" {
  for_each = aws_instance.tenant_portal

  name              = "/${local.name_prefix}/application/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Name   = "${local.name_prefix}-${each.key}-app-logs"
    Tier   = "monitoring"
    Scope  = "application"
    Tenant = each.key
  }
}

# Infrastructure log groups capture shared operational signals such as deployment
# and instance/agent level logs without mixing them into application streams.
resource "aws_cloudwatch_log_group" "infrastructure" {
  for_each = toset([
    "deployments",
    "ssm",
    "system"
  ])

  name              = "/${local.name_prefix}/infrastructure/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Name  = "${local.name_prefix}-${each.key}-infra-logs"
    Tier  = "monitoring"
    Scope = "infrastructure"
  }
}

# Protects against runaway load, crash loops, bad releases, or sustained CPU saturation
# on any tenant-facing portal instance.
resource "aws_cloudwatch_metric_alarm" "portal_cpu_high" {
  for_each = aws_instance.tenant_portal

  alarm_name          = "${local.name_prefix}-${each.key}-cpu-high"
  alarm_description   = "Critical: ${each.key} portal EC2 average CPU >= 80% for 15 minutes. Protects against sustained saturation, runaway processes, or unhealthy deployments."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value.id
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Name   = "${local.name_prefix}-${each.key}-cpu-high"
    Tier   = "monitoring"
    Scope  = "compute"
    Tenant = each.key
  }
}

# Protects against connection pool leaks, stuck application sessions, or approaching
# connection exhaustion on the shared PostgreSQL instance.
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  alarm_description   = "Critical: PostgreSQL database connections >= 40 for 10 minutes. Protects against connection exhaustion, pool leaks, or application retry storms."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 40
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Name  = "${local.name_prefix}-rds-connections-high"
    Tier  = "monitoring"
    Scope = "database"
  }
}