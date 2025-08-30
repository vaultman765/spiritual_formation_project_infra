resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.name_prefix}-security-headers"
  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "SAMEORIGIN"
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

# CORS-friendly policy for static assets consumed cross-origin
resource "aws_cloudfront_response_headers_policy" "static_cors" {
  name    = "${var.name_prefix}-static-cors"
  comment = "Allow cross-origin use of static assets (CSS/JS/fonts)"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    # If you want to pin to only your API origin, replace "*" with "https://api.${var.root_domain_name}"
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_expose_headers {
      items = []
    }
    origin_override = true
  }

  security_headers_config {
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
  # IMPORTANT: allow cross-origin consumption of the asset itself
  # (the policy header travels with the resource)
  custom_headers_config {
    items {
      header   = "Cross-Origin-Resource-Policy"
      value    = "cross-origin"
      override = true
    }
  }
}
