# CPU > 80% for 5 min
resource "aws_cloudwatch_metric_alarm" "apprunner_cpu_high" {
  alarm_name          = "${var.name_prefix}-apprunner-cpu-high"
  namespace           = "AWS/AppRunner"
  metric_name         = "CPUUtilization"
  dimensions          = { ServiceName = var.apprunner_service_name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.waf_alerts.arn]
  ok_actions          = [aws_sns_topic.waf_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Mem > 85% for 5 min
resource "aws_cloudwatch_metric_alarm" "apprunner_mem_high" {
  alarm_name          = "${var.name_prefix}-apprunner-mem-high"
  namespace           = "AWS/AppRunner"
  metric_name         = "MemoryUtilization"
  dimensions          = { ServiceName = var.apprunner_service_name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 85
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.waf_alerts.arn]
  ok_actions          = [aws_sns_topic.waf_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Any 5xx > 0 in 5 min
resource "aws_cloudwatch_metric_alarm" "apprunner_5xx" {
  alarm_name          = "${var.name_prefix}-apprunner-5xx"
  namespace           = "AWS/AppRunner"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { ServiceName = var.apprunner_service_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.waf_alerts.arn]
  ok_actions          = [aws_sns_topic.waf_alerts.arn]
  treat_missing_data  = "notBreaching"
}
