resource "aws_vpc_dhcp_options" "default" {
  domain_name          = var.domain_name
  domain_name_servers  = var.dns_servers
  ntp_servers          = var.ntp_servers
  netbios_name_servers = var.nbns_servers
  netbios_node_type    = 2
  tags = {
    Name = var.name
  }
}
