# ---- SNS topic for alerts (email) ----
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

# Subscribe your email (you must confirm the subscription email once)
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email
}

# Common dimensions
locals {
  rds_dims = {
    DBInstanceIdentifier = var.identifier
  }
}

# ---- CPU high (sustained >80% for 5 minutes) ----
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU > 80% for 5 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = local.rds_dims
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---- Memory low (FreeableMemory < 200MB for 5 minutes) ----
resource "aws_cloudwatch_metric_alarm" "rds_mem_low" {
  alarm_name          = "${var.name_prefix}-rds-mem-low"
  alarm_description   = "RDS FreeableMemory < 200MB for 5 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 200 * 1024 * 1024 # bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = local.rds_dims
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---- Disk low (FreeStorageSpace < 5GB for 5 minutes) ----
resource "aws_cloudwatch_metric_alarm" "rds_disk_low" {
  alarm_name          = "${var.name_prefix}-rds-disk-low"
  alarm_description   = "RDS FreeStorageSpace < 5GB for 5 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 5 * 1024 * 1024 * 1024 # bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = local.rds_dims
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---- T-class credits low (CPUCreditBalance < 20 for 10 minutes) ----
resource "aws_cloudwatch_metric_alarm" "rds_cpu_credits_low" {
  alarm_name          = "${var.name_prefix}-rds-cpu-credits-low"
  alarm_description   = "RDS CPUCreditBalance < 20 for 10 minutes (t4g.* bursts)"
  namespace           = "AWS/RDS"
  metric_name         = "CPUCreditBalance"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 10
  threshold           = 20
  comparison_operator = "LessThanThreshold"
  dimensions          = local.rds_dims
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---- (Optional) Connections high (>= 90% of max for 5 minutes) ----
# Rough rule-of-thumb threshold; tune to your app.
resource "aws_cloudwatch_metric_alarm" "rds_conns_high" {
  alarm_name          = "${var.name_prefix}-rds-connections-high"
  alarm_description   = "RDS DatabaseConnections unusually high"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80 # set an absolute number you consider high (e.g., 80)
  comparison_operator = "GreaterThanThreshold"
  dimensions          = local.rds_dims
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
