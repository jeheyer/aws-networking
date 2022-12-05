locals {
  create_vpc       = var.vpc.id == null ? true : false
  vpc_name         = coalesce(var.vpc.name, var.vpc.id)
  zone_names       = data.aws_availability_zones.available.names
  zone_short_names = [for zone_name in local.zone_names : substr(zone_name, -1, 0)]
  zone_ids         = data.aws_availability_zones.available.zone_ids
  zone_short_ids   = [for zone_id in local.zone_ids : element(split("-", zone_id), 1)]
  igw_name         = "igw-${local.vpc_name}"
  vpgw_name        = "vpgw-${local.vpc_name}"
  tgw_name         = "tgw-${local.vpc_name}"
}

# The VPC itself
module "vpc" {
  source     = "../modules/aws_vpc"
  count      = local.create_vpc == true ? 1 : 0
  name       = var.vpc.name
  cidr_block = var.vpc.cidr_blocks[0]
}

# IGW
module "igw" {
  source = "../modules/aws_internet_gateway"
  count  = var.igw.create == true ? 1 : 0
  name   = local.igw_name
  vpc_id = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
}

# Public subnets & Route Table
module "public_subnets" {
  source     = "../modules/aws_subnet"
  count      = var.subnets.create == true ? length(var.subnets.public_cidrs) : 0
  name       = "${local.vpc_name}-public-${element(local.zone_short_ids, count.index)}"
  cidr_block = var.subnets.public_cidrs[count.index]
  az         = var.vpc.use_multiple_azs == true ? element(local.zone_names, count.index) : null
  vpc_id     = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  tier       = "Public"
}
module "public_route_table" {
  source = "../modules/aws_route_table"
  count  = var.subnets.create == true ? 1 : 0
  name   = "${local.vpc_name}-public"
  vpc_id = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
}
module "public_routes" {
  source         = "../modules/aws_route"
  count          = var.subnets.create == true ? length(module.public_route_table) : 0
  route_table_id = module.public_route_table[0].id
  routes         = ["0.0.0.0/0"]
  #  target         = var.igw.create == true ? module.igw.id : data.aws_internet_gateway.default.id
  target = var.igw.create == true ? module.igw[0].id : null
}
module "public_route_table_association" {
  source         = "../modules/aws_route_table_association"
  count          = var.subnets.create == true ? length(var.subnets.public_cidrs) : 0
  subnet_id      = module.public_subnets[count.index].id
  route_table_id = var.subnets.create == true ? module.public_route_table[0].id : null
}

# Private subnets & Route Table
module "private_subnets" {
  source     = "../modules/aws_subnet"
  count      = var.subnets.create == true ? length(var.subnets.private_cidrs) : 0
  name       = "${local.vpc_name}-private-${element(local.zone_short_ids, count.index)}"
  cidr_block = var.subnets.private_cidrs[count.index]
  az         = var.vpc.use_multiple_azs == true ? element(local.zone_names, count.index) : null
  vpc_id     = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  tier       = "Private"
}
module "private_route_tables" {
  source = "../modules/aws_route_table"
  #  count  = var.subnets.create == true ? length(var.subnets.private_cidrs) : 0
  count  = var.subnets.create == true ? length(local.zone_ids) : 0
  name   = "${local.vpc_name}-private-${element(local.zone_short_names, count.index)}"
  vpc_id = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  #  routes = local.default_route
}
module "private_routes" {
  source = "../modules/aws_route"
  #  count          = var.subnets.create == true && var.create_nat_gateways == true ? length(var.subnets.private_cidrs) : 0
  count          = var.subnets.create == true && var.create_nat_gateways == true ? length(data.aws_availability_zones.available) : 0
  route_table_id = module.private_route_tables[count.index].id
  routes         = ["0.0.0.0/0"]
  target         = var.create_nat_gateways == true ? module.nat_gateways[count.index].id : null
}
module "private_route_table_association" {
  source    = "../modules/aws_route_table_association"
  count     = length(var.subnets.private_cidrs)
  subnet_id = module.private_subnets[count.index].id
  #  route_table_id = module.private_route_tables[count.index].id
  route_table_id = element(module.private_route_tables, count.index).id
}

# NAT gateway Elastic IP allocations
module "nat_gateway_eip" {
  source = "../modules/aws_eip"
  count  = var.create_nat_gateways == true ? length(var.subnets.private_cidrs) : 0
  name   = "${local.vpc_name}-nat-gateway-${local.zone_ids[count.index]}"
}

# NAT gateways
module "nat_gateways" {
  source            = "../modules/aws_nat_gateway"
  count             = var.create_nat_gateways == true ? length(var.subnets.private_cidrs) : 0
  subnet_id         = module.public_subnets[count.index].id
  eip_allocation_id = module.nat_gateway_eip[count.index].allocation_id
  name              = "${local.vpc_name}-${local.zone_ids[count.index]}"
}

# Security Groups
module "security_groups" {
  source        = "../modules/aws_security_group"
  for_each      = var.security_groups
  name          = each.key
  description   = each.value["description"]
  vpc_id        = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  inbound_rules = each.value["inbound_rules"]
}

# EC2 ENIs
module "ec2_enis" {
  source             = "../modules/aws_network_interface"
  for_each           = var.ec2_instances
  num_interfaces     = coalesce(each.value["num_instances"], 2)
  subnet_ids         = var.subnets.create == true ? module.private_subnets.ids : data.aws_subnets.private.ids
  security_group_ids = [module.security_groups[each.value["security_group_name"]].id]
}

# EC2 Instances
module "ec2_instances" {
  source        = "../modules/aws_instance"
  for_each      = var.ec2_instances
  naming_prefix = each.key
  num_instances = coalesce(each.value["num_instances"], 2)
  instance_type = coalesce(each.value["instance_type"], "t2.nano")
  key_name      = each.value["key_name"]
  ami           = each.value["ami"]
  eni_ids       = module.ec2_enis[each.key].ids
}

# EC2 Target Group
module "ec2_target_group" {
  source      = "../modules/aws_lb_target_group"
  for_each    = var.ec2_instances
  vpc_id      = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  name        = "${each.key}-ec2-tg"
  target_port = coalesce(each.value["port"], 80)
  protocol    = coalesce(each.value["protocol"], "HTTP")
}

# EC2 Target Group Attachment
module "ec2_target_group_attachment" {
  source           = "../modules/aws_lb_target_group_attachment"
  for_each         = var.ec2_instances
  target_group_arn = module.ec2_target_group[each.key].arn
  target_ids       = module.ec2_instances[each.key].ids
}

# Lambda IAM Role
module "lambda_iam_role" {
  source   = "../modules/aws_iam_role"
  for_each = var.lambda_functions
  name     = "LambdaIamRole-${each.key}"
}

# Lambda Function
module "lambda_function" {
  source       = "../modules/aws_lambda_function"
  for_each     = var.lambda_functions
  name         = each.key
  zipfile_name = each.value["zipfile_name"]
  runtime      = each.value["runtime"]
  iam_role_arn = module.lambda_iam_role[each.key].arn
}

# Create Aliases to latest version
module "lambda_function_alias" {
  source           = "../modules/aws_lambda_alias"
  for_each         = var.lambda_functions
  name             = "live"
  function_arn     = module.lambda_function[each.key].arn
  function_version = module.lambda_function[each.key].version
}

# Target Group for Lambda functions
module "lambda_target_group" {
  source              = "../modules/aws_lb_target_group"
  for_each            = var.lambda_functions
  name                = "${each.key}-lambda-tg"
  target_type         = "lambda"
  multi_value_headers = true
}

# Lambda Permissions required for Target Group
module "lambda_permissions" {
  source           = "../modules/aws_lambda_permission"
  for_each         = var.lambda_functions
  function_name    = module.lambda_function[each.key].name
  alias_name       = module.lambda_function_alias[each.key].name
  target_group_arn = module.lambda_target_group[each.key].arn
}

# Target Group Attachment
module "lambda_target_group_attachment" {
  source           = "../modules/aws_lb_target_group_attachment"
  for_each         = var.lambda_functions
  target_group_arn = module.lambda_target_group[each.key].arn
  target_ids       = [module.lambda_function_alias[each.key].arn]
}

# Create ALBs
module "alb" {
  source             = "../modules/aws_lb"
  for_each           = var.albs
  name               = each.key
  subnet_ids         = var.subnets.create == true ? module.public_subnets.ids : data.aws_subnets.public.ids
  security_group_ids = [module.security_groups[each.value["security_group_name"]].id]
}

# Create HTTP Listener
module "alb_http_listener" {
  source           = "../modules/aws_lb_listener"
  for_each         = var.albs
  target_group_arn = module.lambda_target_group[each.value["default_target_group"]].arn
  aws_lb_arn       = module.alb[each.key].arn
}

# Create HTTPS Listener
module "alb_https_listener" {
  source           = "../modules/aws_lb_listener"
  for_each         = var.albs
  port             = 443
  protocol         = "https"
  default_cert_arn = each.value["default_cert_arn"]
  ssl_policy_name  = coalesce(each.value["ssl_policy_name"], "ELBSecurityPolicy-FS-1-2-2019-08")
  target_group_arn = module.lambda_target_group[each.value["default_target_group"]].arn
  aws_lb_arn       = module.alb[each.key].arn
}

# Attach additional certs, if given
module "alb_additional_certs" {
  source               = "../modules/aws_lb_listener_certificate"
  for_each             = var.albs
  listener_arn         = module.alb_https_listener[each.key].arn
  additional_cert_arns = coalesce(each.value["additional_cert_arns"], [])
}

# Create DNS CNAME to each ALB's DNS name
module "dns_cname" {
  source      = "../modules/aws_route53_record"
  for_each    = var.albs
  dns_zone_id = each.value["dns_zone_id"]
  name        = each.key
  type        = "CNAME"
  records     = [module.alb[each.key].dns_name]
}

# Peering connections
module "peering_connections" {
  source          = "../modules/aws_vpc_peering_connection"
  for_each        = var.peerings
  name            = each.key
  vpc_id          = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  peer_vpc_id     = each.value.vpc_id
  region          = data.aws_region.current.name
  peer_region     = coalesce(each.value.region, data.aws_region.current.name)
  peer_account_id = coalesce(each.value.account_id, data.aws_caller_identity.current.account_id)
  #peer_owner_account_id    = each.value.owner_account_id 
  auto_accept = each.value.auto_accept
}

# Routes related to Peering connections
module "peering_routes" {
  source         = "../modules/aws_route"
  for_each       = var.peerings
  route_table_id = module.public_route_table[0].id
  routes         = each.value["destinations"]
  target         = module.peering_connections[each.key].id
}

# Customer Gateways
module "cgws" {
  source     = "../modules/aws_customer_gateway"
  for_each   = var.cgws
  name       = each.key
  ip_address = each.value["ip_address"]
  bgp_asn    = each.value["bgp_asn"]
}

# Virtual Private Gateway (VPGW)
module "vpgw" {
  source = "../modules/aws_vpn_gateway"
  count  = var.vpgw["create"] == true ? 1 : 0
  name   = coalesce(var.vpgw["name"], local.vpgw_name)
  asn    = coalesce(var.vpgw["asn"], 64512)
  vpc_id = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
}

# Enable VPGW route propogation
module "vpgw_propogation" {
  source = "../modules/aws_vpn_gateway_route_propagation"
  count  = var.subnets.create == true && var.vpgw["create"] == true ? length(var.subnets.private_cidrs) : 0
  #  route_table_id = var.subnets.create == true ? module.private_route_tables[count.index].id : null
  route_table_id = var.subnets.create == true ? element(module.private_route_tables, count.index).id : null
  vpgw_id        = var.vpgw["create"] == true ? module.vpgw[0].id : var.vpgw["id"]
}

# Transit Gateway
module "tgw" {
  source = "../modules/aws_ec2_transit_gateway"
  count  = var.tgw["create"] == true ? 1 : 0
  name   = coalesce(var.tgw["name"], local.tgw_name)
  asn    = coalesce(var.tgw["asn"], 64512)
}

# Transit Gateway Attachment
module "tgw_attachment" {
  source     = "../modules/aws_ec2_transit_gateway_vpc_attachment"
  count      = var.tgw.create == true || var.tgw.id != null ? 1 : 0
  tgw_id     = var.tgw.create == true ? module.tgw[0].id : var.tgw.id
  vpc_id     = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
  subnet_ids = var.subnets.create == true ? module.private_subnets[*].id : data.aws_subnets.private.ids
}

# VPN tunnels
module "vpn_connections" {
  source   = "../modules/aws_vpn_connection"
  for_each = var.vpn_connections
  name     = each.key
  vpgw_id  = var.vpgw["create"] == true ? module.vpgw[0].id : var.vpgw.id
  #tgw_id          = var.tgw["create"] == true ? module.tgw[0].id : var.tgw.id
  cgw_id = each.value["cgw_id"]
  #module.cgws[each.value["cgw_name"]].id : each.value["cgw_id"]
  ike_version     = each.value["ike_version"]
  phase1_settings = each.value["phase1_settings"]
  phase2_settings = each.value["phase2_settings"]
  tunnel_settings = each.value["tunnel_settings"]
  depends_on      = [module.vpgw]
}

#module "network_firewalls" {
#  source   = "../modules/aws_networkfirewall_firewall"
#  for_each = var.network_firewalls
#  name     = each.key
#  vpc_id     = local.create_vpc == true ? module.vpc[0].id : var.vpc.id
#  subnet_id  = "subnet-0c0673d2034d0a96f"
#  policy_arn = each.value["policy_arn"]
#}

