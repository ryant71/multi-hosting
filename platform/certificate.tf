locals {
  all_domains = distinct(flatten([
    for site in var.websites : [
      site.domain_name,
      "*.${site.domain_name}"
    ]
  ]))
  
  domain_zone_mapping = {
    for site in var.websites : site.domain_name => site.zone_id
  }
}

resource "aws_acm_certificate" "certificate" {
  provider                 = aws.us_east_1
  domain_name               = local.all_domains[0]
  subject_alternative_names = slice(local.all_domains, 1, length(local.all_domains))
  validation_method         = "DNS"

  tags = {
    Name = "multi-domain-certificate"
  }
}

# Certificate validation - COMMENTED OUT because certificate is already validated
# Uncomment this section when rebuilding from scratch
# resource "aws_route53_record" "certificate_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#       zone_id = local.domain_zone_mapping[replace(dvo.domain_name, "*.", "")]
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone_id
# }
#
# resource "aws_acm_certificate_validation" "certificate" {
#   certificate_arn         = aws_acm_certificate.certificate.arn
#   validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
# }
