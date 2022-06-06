resource "aws_security_group" "service" {
  name_prefix = "${var.region}-service-sg"
  description = "Security Group for services"
  vpc_id      = data.terraform_remote_state.hcp_consul.outputs.vpc_id
  tags = merge(
    { "Name" = "${var.region}-service-sg" },
    { "Project" = var.region }
  )
}
resource "aws_security_group_rule" "service_envoy" {
  security_group_id = aws_security_group.service.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 20000
  to_port           = 21255
  cidr_blocks       = [var.vpc_cidr_block]
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? var.allowed_bastion_cidr_blocks_ipv6 : null
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "service_9090-9099" {
  security_group_id = aws_security_group.service.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 9090
  to_port           = 9099
  cidr_blocks       = [var.vpc_cidr_block]
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? var.allowed_bastion_cidr_blocks_ipv6 : null
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "service_allow_outbound" {
  security_group_id = aws_security_group.service.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? ["::/0"] : null
  description       = "Allow any outbound traffic."
}
