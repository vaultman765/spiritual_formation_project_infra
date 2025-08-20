resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.name_prefix}-security-headers"
  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
    # Optional CSP: tune for your app (start loose, tighten later)
    content_security_policy {
      content_security_policy = "default-src 'self' https: data: blob: 'unsafe-inline'; img-src * data: blob:"
      override                = true
    }
  }

}
