# ─── Custom Domain (Route 53 + ACM for CloudFront) ───────────────────────────
# Bonus Path C: HTTPS on a custom domain via ACM cert in us-east-1.
# Requires an existing public hosted zone for var.custom_domain in Route 53.

data "aws_route53_zone" "main" {
  count        = local.use_custom_domain ? 1 : 0
  name         = var.custom_domain
  private_zone = false
}

resource "aws_acm_certificate" "dochub" {
  provider          = aws.us_east_1
  count             = local.use_custom_domain ? 1 : 0
  domain_name       = var.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-cert" }
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.use_custom_domain ? {
    for dvo in aws_acm_certificate.dochub[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 300
}

resource "aws_acm_certificate_validation" "dochub" {
  provider                = aws.us_east_1
  count                   = local.use_custom_domain ? 1 : 0
  certificate_arn         = aws_acm_certificate.dochub[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cloudfront_a" {
  count   = local.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dochub.domain_name
    zone_id                = aws_cloudfront_distribution.dochub.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_aaaa" {
  count   = local.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.custom_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.dochub.domain_name
    zone_id                = aws_cloudfront_distribution.dochub.hosted_zone_id
    evaluate_target_health = false
  }
}
