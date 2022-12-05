variable "vpc" {
  type = object({
    create           = optional(bool)
    create_subnets   = optional(bool)
    create_igw       = optional(bool)
    create_nat_gws   = optional(bool)
    use_multiple_azs = optional(bool)
    id               = optional(string)
    name             = optional(string)
    region           = string
    cidr_blocks      = optional(list(string))
  })
  default = {
    create           = true
    create_nat_gws   = false
    use_multiple_azs = true
    id               = null
    name             = "default-vpc"
    region           = "us-east-1"
    cidr_blocks      = ["172.31.0.0/16"]
  }
}
variable "subnets" {
  type = object({
    create        = optional(bool)
    public_cidrs  = optional(list(string))
    private_cidrs = optional(list(string))
  })
  default = {}
}
variable "create_nat_gateways" {
  type    = bool
  default = false
}
variable "security_groups" {
  type = map(object({
    description = optional(string)
    inbound_rules = list(object({
      protocol    = optional(string)
      from_port   = optional(number)
      to_port     = number
      cidr_blocks = list(string)
    }))
  }))
  default = {}
}
variable "ec2_instances" {
  type = map(object({
    num_instances = optional(number)
    ami           = optional(string)
    #subnet_ids         = list(string)
    instance_type = optional(string)
    port          = optional(number)
    protocol      = optional(number)
    #security_group_names = list(string)
    security_group_name = optional(string)
    #security_group_ids = optional(list(string))
    key_name = string
  }))
  default = {}
}
variable "lambda_functions" {
  type = map(object({
    description  = optional(string)
    handler_file = optional(string)
    handler_name = optional(string)
    zipfile_name = optional(string)
    runtime      = string
  }))
  default = {}
}
variable "albs" {
  type = map(object({
    type = optional(string)
    #subnet_ids           = optional(list(string))
    #security_group_names = list(string)
    security_group_name = optional(string)
    #security_group_ids   = optional(list(string))
    default_cert_arn     = string
    additional_cert_arns = optional(list(string))
    ssl_policy_name      = optional(string)
    default_target_group = string
    dns_zone_id          = optional(string)
    #dns_record = optional(string)
  }))
  default = {}
}
variable "igw" {
  type = object({
    create = optional(bool)
  })
  default = {
    create = true
  }
}
variable "vpgw" {
  type = object({
    create = optional(bool)
    id     = optional(string)
    name   = optional(string)
    asn    = optional(number)
  })
  default = {
    create = false
    id     = null
    name   = null
    asn    = 64512
  }
}
variable "tgw" {
  type = object({
    create = optional(bool)
    id     = optional(string)
    name   = optional(string)
    asn    = optional(number)
  })
  default = {
    create = false
    id     = null
    name   = null
    asn    = 64512
  }
}

variable "cgws" {
  type = map(object({
    id         = optional(string)
    ip_address = string
    bgp_asn    = optional(number)
    device     = optional(string)
  }))
  default = {}
}

variable "nat_gws" {
  type = list(object({
    create = optional(bool)
    type   = optional(string)
    eip_id = optional(string)
  }))
  default = []
}
variable "vpn_connections" {
  type = map(object({
    #vpn_gateway      = string
    cgw_name    = optional(string)
    cgw_id      = optional(string)
    ike_version = optional(number)
    phase1_settings = optional(object({
      lifetime   = optional(number)
      encryption = optional(list(string))
      integrity  = optional(list(string))
      dh_groups  = optional(list(string))
    }))
    phase2_settings = optional(object({
      lifetime   = optional(number)
      encryption = optional(list(string))
      integrity  = optional(list(string))
      dh_groups  = optional(list(string))
    }))
    tunnel_settings = optional(list(object({
      preshared_key    = optional(string)
      inside_ipv4_cidr = optional(string)
    })))
  }))
  default = {}
}
variable "peerings" {
  type = map(object({
    vpc_id       = string
    region       = optional(string)
    account_id   = optional(string)
    destinations = optional(list(string))
    auto_accept  = optional(bool)
  }))
  default = {}
}
#variable "auto_accept_peering" {
#  description = "Auto-accept peering connections when same account on both ends"
#  type        = bool
#  default     = false
#}
variable "network_firewalls" {
  type = map(object({
    policy_arn = string
    subnet_id  = string
  }))
  default = {}
}
