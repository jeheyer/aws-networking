resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = var.inbound_rules
    content {
      protocol    = coalesce(ingress.value["protocol"], "tcp")
      from_port   = coalesce(ingress.value["from_port"], ingress.value["to_port"])
      to_port     = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      description = ingress.value["description"]
    }
  }
  description = var.description
}

