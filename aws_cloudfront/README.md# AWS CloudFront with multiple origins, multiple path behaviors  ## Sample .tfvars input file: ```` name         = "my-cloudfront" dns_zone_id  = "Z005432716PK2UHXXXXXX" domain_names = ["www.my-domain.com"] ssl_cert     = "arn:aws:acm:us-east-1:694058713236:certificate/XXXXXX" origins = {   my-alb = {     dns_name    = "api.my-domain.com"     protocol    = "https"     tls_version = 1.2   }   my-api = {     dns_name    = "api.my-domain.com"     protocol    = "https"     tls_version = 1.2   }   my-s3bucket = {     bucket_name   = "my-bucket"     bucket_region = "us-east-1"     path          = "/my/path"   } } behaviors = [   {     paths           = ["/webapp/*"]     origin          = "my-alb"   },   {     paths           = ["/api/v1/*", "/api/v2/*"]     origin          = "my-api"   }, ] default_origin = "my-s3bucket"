# AWS CloudFront with multiple origins, multiple path behaviors

## Sample .tfvars input file:
````
name         = "my-cloudfront"
dns_zone_id  = "Z005432716PK2UHXXXXXX"
domain_names = ["www.my-domain.com"]
ssl_cert     = "arn:aws:acm:us-east-1:694058713236:certificate/XXXXXX"
origins = {
  my-alb = {
    dns_name    = "api.my-domain.com"
    protocol    = "https"
    tls_version = 1.2
  }
  my-api = {
    dns_name    = "api.my-domain.com"
    protocol    = "https"
    tls_version = 1.2
  }
  my-s3bucket = {
    bucket_name   = "my-bucket"
    bucket_region = "us-east-1"
    path          = "/my/path"
  }
}
behaviors = [
  {
    paths           = ["/webapp/*"]
    origin          = "my-alb"
  },
  {
    paths           = ["/api/v1/*", "/api/v2/*"]
    origin          = "my-api"
  },
]
default_origin = "my-s3bucket"
