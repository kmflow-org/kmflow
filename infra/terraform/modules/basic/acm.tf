resource "aws_acm_certificate" "kmflow" {
  domain_name       = "*.kmflow.org"
  subject_alternative_names = ["kmflow.org"]
  validation_method = "DNS"
}

data "aws_route53_zone" "kmflow" {
  name         = "kmflow.org"
}

resource "aws_route53_record" "kmflow" {
  for_each = {
    for dvo in aws_acm_certificate.kmflow.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.kmflow.zone_id
}

resource "aws_acm_certificate_validation" "kmflow" {
  certificate_arn         = aws_acm_certificate.kmflow.arn
  validation_record_fqdns = [for record in aws_route53_record.kmflow : record.fqdn]
}

