# --- SNS topic for alerts ---
resource "aws_sns_topic" "waf_alerts" {
  name = "${var.name_prefix}-waf-alerts"
  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_sns_topic_subscription" "waf_email" {
  topic_arn = aws_sns_topic.waf_alerts.arn
  protocol  = "email"
  endpoint  = var.email
}

# Web ACL
resource "aws_wafv2_web_acl" "prod" {
  provider    = aws.us_east_1
  name        = "${var.name_prefix}-waf"
  description = "Prod WAF for CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  # 1) Core managed protections (on, with sensible thresholds)
  rule {
    name     = "AWSCommon"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        # Example: lower sensitivity for body size
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            block {}
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommon"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "KnownBadInputs"
    priority = 20
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # 2) Basic rate limit (tune if needed)
  rule {
    name     = "RateLimit"
    priority = 30
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000 # requests / 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# --- CloudWatch Alarm: any blocked requests by WAF (CloudFront scope=Global) ---
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.name_prefix}-waf-blocked-requests"
  alarm_description   = "Alerts when AWS WAF (CloudFront) blocks any requests."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/WAFV2"
  metric_name = "BlockedRequests"

  # For CloudFront-scope WAF, Region dimension must be 'Global'
  dimensions = {
    WebACL = aws_wafv2_web_acl.prod.name
    Region = "Global"
    Rule   = "ALL"
  }

  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  ok_actions    = [aws_sns_topic.waf_alerts.arn]

  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}
