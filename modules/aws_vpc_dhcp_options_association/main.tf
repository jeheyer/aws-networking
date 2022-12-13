resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = var.vpc_id
  dhcp_options_id = var.dhcp_options_id
}
