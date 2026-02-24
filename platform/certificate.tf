locals {
  all_domains = distinct(flatten([
    for site in var.websites : [
      site.domain_name,
      "*.${site.domain_name}"
    ]
  ]))
}

resource "aws_acm_certificate" "certificate" {
  domain_name               = local.all_domains[0]
  subject_alternative_names = slice(local.all_domains, 1, length(local.all_domains))
  validation_method         = "DNS"

  dynamic "domain_validation_options" {
    for_each = local.all_domains
    content {
      domain_name    = domain_validation_options.value
      hosted_zone_id = var.hosted_zone_id
    }
  }

  tags = {
    Name = "multi-domain-certificate"
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "certificate" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}
