resource "aws_security_group" "service" {
  name_prefix = "${var.region}-service-sg"
  description = "Security Group for services"
  vpc_id      = module.vpc.vpc_id
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
  to_port           = 20000
  cidr_blocks       = local.private_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? var.allowed_bastion_cidr_blocks_ipv6 : null
  description       = "Allow SSH traffic."
}