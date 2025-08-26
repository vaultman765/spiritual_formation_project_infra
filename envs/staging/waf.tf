# Web ACL for staging
resource "aws_wafv2_web_acl" "staging" {
  provider    = aws.us_east_1
  name        = "${var.name_prefix}-waf"
  description = "Staging WAF for CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  # Log4j vulnerability protection - anonymousIpList
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 25
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AnonymousIPList"
      sampled_requests_enabled   = true
    }
  }

  # Log4j specific protection
  rule {
    name     = "Log4jProtection"
    priority = 15
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "Log4JRCE"
          action_to_use {
            block {}
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Log4jProtection"
      sampled_requests_enabled   = true
    }
  }

  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}