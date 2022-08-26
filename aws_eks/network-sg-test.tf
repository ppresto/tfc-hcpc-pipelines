resource "aws_security_group_rule" "consul_server_allow_client_egress_8301" {
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301_udp" {
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "egress"
  protocol                 = "udp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}