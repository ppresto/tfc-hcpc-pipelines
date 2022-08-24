## Bastion ec2

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
resource "aws_instance" "bastion" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.bastion.id, aws_security_group.service.id, aws_security_group.consul_server.id]
  subnet_id                   = data.terraform_remote_state.hcp_consul.outputs.vpc_public_subnets[0]
  associate_public_ip_address = true
  user_data                   = data.template_file.userdata.rendered
  tags = merge(
    { "Name" = "presto-${var.region}-bastion" },
    { "Project" = var.region }
  )
}

## Bastion SG
resource "aws_security_group" "bastion" {
  name_prefix = "${var.region}-bastion-sg"
  description = "Firewall for the bastion instance"
  vpc_id      = data.terraform_remote_state.hcp_consul.outputs.vpc_id
  tags = merge(
    { "Name" = "${var.region}-bastion-sg" },
    { "Project" = var.region }
  )
}

resource "aws_security_group_rule" "bastion_allow_22" {
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.allowed_bastion_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? var.allowed_bastion_cidr_blocks_ipv6 : null
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "bastion_allow_outbound" {
  security_group_id = aws_security_group.bastion.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? ["::/0"] : null
  description       = "Allow any outbound traffic."
}

output "bastion_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP address of bastion"
}
