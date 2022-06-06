resource "aws_security_group" "consul_server" {
  name_prefix = "${var.region}-consul-server-sg"
  description = "Firewall for the consul server."
  vpc_id      = data.terraform_remote_state.hcp_consul.outputs.vpc_id
  tags = merge(
    { "Name" = "${var.region}-consul-server-sg" },
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

# Bastion SSH access
resource "aws_security_group_rule" "consul_server_allow_22_bastion" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow SSH traffic from consul bastion."
}
/*
# EKS - Consul ingress gateway
kubectl logs consul-ingress-gateway-55d874f58-rc98s service-init
Error registering service "ingress-gateway": Put "https://10.20.3.197:8501/v1/agent/service/register": dial tcp 10.20.3.197:8501: connect: connection refused
*/
resource "aws_security_group_rule" "consul_server_allow_client_8501" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8501
  to_port                  = 8501
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
# Enable Consul Connect: GRPC for Envoy Proxy
resource "aws_security_group_rule" "consul_server_allow_client_8502" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8502
  to_port                  = 8502
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Consul Connect requires grpc 8502 for envoy"
}
# Enable Consul Connect: Envoy sidecar registration ports
# ref: https://learn.hashicorp.com/tutorials/consul/service-mesh-production-checklist?in=consul/developer-mesh
resource "aws_security_group_rule" "consul_allow_client_com_20000-21255" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 20000
  to_port                  = 21255
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Consul Connect requires envoy"
}
# Fake service ports
resource "aws_security_group_rule" "consul_client_allow_fakeservice" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9090
  to_port                  = 9091
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle EKS request to fake-service"
}

# EKS - Consul client
# [ERROR] agent.auto_config: AutoEncrypt.Sign RPC failed: addr=172.25.26.99:8300 error="rpcinsecure error establishing connection: dial tcp <nil>->172.25.26.99:8300: i/o timeout"
resource "aws_security_group_rule" "consul_server_allow_client_8300" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_8300_udp" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
/*
# EKS - API needs access to Pods.  hashicups pods can't be started
Error from server (InternalError): error when creating "hashicups/frontend.yaml": Internal error occurred: failed calling webhook "mutate-servicedefaults.consul.hashicorp.com": 
Post "https://consul-controller-webhook.default.svc:443/mutate-v1alpha1-servicedefaults?timeout=10s": context deadline exceeded
*/
resource "aws_security_group_rule" "consul_client_allow_eksapi_9443" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9443
  to_port                  = 9443
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle EKS API request to Pods"
}

/*
# Hashicups fails to deploy replicaset

$ kubectl describe rs frontend-d6c448596
Warning  FailedCreate  2m8s (x16 over 6m42s)  replicaset-controller  Error creating: Internal error occurred: failed calling webhook "consul-connect-injector.consul.hashicorp.com": Post "https://consul-connect-injector-svc.default.svc:443/mutate?timeout=10s": context deadline exceeded
Warning  FailedCreate  12m                  replicaset-controller  Error creating: Internal error occurred: failed calling webhook "consul-connect-injector.consul.hashicorp.com": Post "https://consul-connect-injector-svc.default.svc:443/mutate?timeout=10s": dial tcp 10.20.2.118:8080: i/o timeout
*/
resource "aws_security_group_rule" "consul_client_allow_eksapi_443" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle EKS API request to consul-connect"
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
resource "aws_security_group_rule" "hcp_tcp_http" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "The HTTP API"
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
resource "aws_security_group_rule" "consul_server_allow_outbound" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}