# Data Sources

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_vpc" "vpc_id" {
  id = var.vpc.create == true ? module.vpc[0].id : var.vpc.id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc.create == true ? module.vpc[0].id : var.vpc.id]
  }
  tags = {
    Tier = "Public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc.create == true ? module.vpc[0].id : var.vpc.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_route_tables" "route_tables" {
  vpc_id = var.vpc.create == true ? module.vpc[0].id : var.vpc.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

#data "aws_internet_gateway" "default" {
#  filter {
#    name   = "attachment.vpc-id"
#    values = [var.create_vpc == true && var.create_igw ? module.vpc[0].id : var.vpc.id]
#  }
#}


#data "aws_vpn_gateway" "selected" {
#  filter {
#    name   = "tag:Name"
#    values = ["vpn-gw"]
#  }
#}

#data "aws_ami_ids" "ubuntu" {
#  owners = ["amazon"]
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
#  }
#}
