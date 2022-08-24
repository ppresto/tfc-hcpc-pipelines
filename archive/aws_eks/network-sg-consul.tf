resource "aws_security_group" "consul_server" {
  name_prefix = "${var.region}-vpc3-consul"
  description = "Firewall for the consul server."
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "${var.region}-vpc3-consul" },
    { "Project" = var.region },
    { "Owner" = "presto" }
  )
}

#
###  Ingress Rules 
#
resource "aws_security_group_rule" "consul_server_allow_server_8301" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}
resource "aws_security_group_rule" "consul_server_allow_server_8301_udp" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}


resource "aws_security_group_rule" "consul_server_allow_client_8301" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_8301_udp" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}

#
### Egress Rules
#
resource "aws_security_group_rule" "hcp_tcp_RPC_from_clients" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8300
  to_port           = 8300
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "For RPC communication between clients and servers"
}
resource "aws_security_group_rule" "hcp_tcp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "hcp_udp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301_udp" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "egress"
  protocol                 = "udp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "hcp_tcp_https" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "The HTTPS API"
}

#
### EKS Security Group
#
resource "aws_security_group" "eks" {
  name_prefix = "${var.region}-eks-sg"
  description = "Security Group for eks"
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "presto-${var.region}-eks-sg" },
    { "Project" = var.region }
  )
}

resource "aws_security_group_rule" "eks-ingress" {
  security_group_id = aws_security_group.eks.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 9090
  to_port           = 9090
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow app traffic."
}
resource "aws_security_group_rule" "eks_envoy" {
  security_group_id = aws_security_group.eks.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 20000
  to_port           = 21255
  cidr_blocks       = ["10.0.0.0/10"]
  description       = "Allow envoy traffic."
}
resource "aws_security_group_rule" "eks_ssh" {
  security_group_id = aws_security_group.eks.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["10.0.0.0/10"]
  description       = "Allow SSH traffic."
}