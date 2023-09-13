module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "${var.stack_name}.${var.domain_name}"
  zone_id     = data.aws_route53_zone.selected[0].zone_id

  subject_alternative_names = [
    "*.${var.stack_name}.${var.domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = "${var.stack_name}.${var.domain_name}"
  }
}
