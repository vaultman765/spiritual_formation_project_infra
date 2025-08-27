# --- SNS topic for alerts ---
resource "aws_sns_topic" "waf_alerts" {
  name              = "${var.name_prefix}-waf-alerts"
  kms_master_key_id = module.kms_logs.kms_key_arn
  tags              = { Project = var.project, Env = var.env, Managed = "Terraform" }
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

  # 2) Known Bad Inputs with Log4J protection specifically enabled
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

        # Add this rule action override specifically for Log4j
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
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # 3) Rate limit 
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

  # 4) Anonymous IP list (additional protection for Log4j)
  rule {
    name     = "AnonymousIPList"
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

resource "aws_s3_bucket" "waf_logs" {
  bucket = "${var.name_prefix}-waf-logs"
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "waf_logs" {
  bucket        = aws_s3_bucket.waf_logs.id
  target_bucket = module.logging.log_bucket_name
  target_prefix = "s3/${aws_s3_bucket.waf_logs.id}/"
}

resource "aws_s3_bucket_notification" "waf_logs" {
  bucket      = aws_s3_bucket.waf_logs.id
  eventbridge = true
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms_logs.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "noncurrent-versions"
    status = "Enabled"
    noncurrent_version_expiration { noncurrent_days = 7 }
  }

  rule {
    id     = "expire-logs-7d"
    status = "Enabled"
    filter {} # Required by AWS provider

    expiration {
      days = 7
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {} # Applies to all objects
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = "aws-waf-logs-${var.name_prefix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_waf.arn
    bucket_arn         = aws_s3_bucket.waf_logs.arn
    buffering_interval = 300
  }
}

resource "aws_iam_role" "firehose_waf" {
  name = "${var.name_prefix}-firehose-waf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "firehose_waf" {
  role = aws_iam_role.firehose_waf.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucket",
          "s3:PutBucketNotification"
        ],
        Resource = [aws_s3_bucket.waf_logs.arn, "${aws_s3_bucket.waf_logs.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = [module.kms_logs.kms_key_arn]
      }
    ]
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.prod.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf.arn]

  # Ensure the delivery stream is created first
  depends_on = [aws_kinesis_firehose_delivery_stream.waf]
}