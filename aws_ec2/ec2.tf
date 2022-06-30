provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "ubuntu_1804_ami_id" {
  name = "/aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "template_file" "userdata" {
  template = file("${path.module}/templates/client-systemd.sh")
  vars = {
    CONSUL_CA_FILE     = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
    CONSUL_CONFIG_FILE = data.terraform_remote_state.hcp_consul.outputs.consul_config_file
    CONSUL_ACL_TOKEN   = data.terraform_remote_state.hcp_consul.outputs.consul_root_token_secret_id
    SERVICE_ACL_TOKEN  = data.terraform_remote_state.hcp_consul.outputs.consul_service_api_token
  }
}
resource "aws_instance" "node" {
  ami                         = data.aws_ssm_parameter.ubuntu_1804_ami_id.value
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.ec2-svc-node.id, aws_security_group.consul_server.id]
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  user_data                   = data.template_file.userdata.rendered
  tags = merge(
    { "Name" = "presto-${var.region}-svc-node" },
    { "Project" = var.region }
  )
}

## node SG
resource "aws_security_group" "ec2-svc-node" {
  name_prefix = "${var.region}-ec2-svc-node-sg"
  description = "Security Group for ec2-svc-nodes"
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "presto-${var.region}-ec2-svc-node-sg" },
    { "Project" = var.region }
  )
}
resource "aws_security_group_rule" "ec2-svc-node_envoy" {
  security_group_id = aws_security_group.ec2-svc-node.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 20000
  to_port           = 21255
  cidr_blocks       = [var.vpc_cidr_block]
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "ec2-svc-node_9090-9099" {
  security_group_id = aws_security_group.ec2-svc-node.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 9090
  to_port           = 9099
  cidr_blocks       = [var.vpc_cidr_block]
  description       = "Allow SSH traffic."
}
resource "aws_security_group_rule" "node_allow_22" {
  security_group_id = aws_security_group.ec2-svc-node.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [var.vpc_cidr_block]
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "node_allow_outbound" {
  security_group_id = aws_security_group.ec2-svc-node.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}
