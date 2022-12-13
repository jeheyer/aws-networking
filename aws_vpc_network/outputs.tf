output "vpc_id" { value = data.aws_vpc.vpc_id.id }
output "public_subnet_ids" { value = data.aws_subnets.public.ids }
output "private_subnet_ids" { value = data.aws_subnets.private.ids }
output "route_tables_ids" { value = data.aws_route_tables.route_tables.ids }
output "vpgw_ids" { value = module.vpgw[*].id }
#output "cgw_ids" { value = module.cgws[*].id }
output "tgw_ids" { value = module.tgw[*].id }
