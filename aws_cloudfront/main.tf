# Create CloudFront Distribution
module "cloudfront" {
  source              = "../modules/aws_cloudfront_distribution/"
  domain_names        = var.domain_names
  origins             = var.origins
  behaviors           = var.behaviors
  default_origin      = var.default_origin
  ssl_cert            = var.ssl_cert
  block_list          = ["IR", "KP"]
  price_class         = "PriceClass_100"
  tls_security_policy = "TLSv1.2_2019"
  enable_ipv6         = false
  enable_http2        = true
}

# Create CNAME in Route 53
module "route53_cname" {
  source      = "../modules/aws_route53_record/"
  dns_zone_id = var.dns_zone_id
  name        = var.name
  type        = "CNAME"
  records     = [module.cloudfront.domain_name]
  ttl         = var.dns_ttl
}
