
# This prefix will be used in your EKS cluster name.
# Update the ./aws_eks/awscli_eks_connect.sh with your EKS cluster name to connect.
variable "prefix" {
  description = "Unique name to identify all resources. Try using your name."
  type        = string
  default     = "presto"
}

# The EKS cluster will be created in this region.
# Update ./aws_eks/awscli_eks_connect.sh with your region value to connect.
variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}
variable "organization" { default = "my_org_name" }

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
  default     = "my-aws-ssh-key-pair"
}
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.20.0.0/16"
  #default     = "0.0.0.0/0"
}
locals {
  region_shortname = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.region))
  vpc_id             = data.terraform_remote_state.hcp_consul.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.hcp_consul.outputs.vpc_private_subnets
  public_subnet_ids  = data.terraform_remote_state.hcp_consul.outputs.vpc_public_subnets

  consul_config_file      = jsondecode(base64decode(data.terraform_remote_state.hcp_consul.outputs.consul_config_file))
  consul_gossip_key       = local.consul_config_file.encrypt
  consul_retry_join       = local.consul_config_file.retry_join
  consul_server_http_addr = data.terraform_remote_state.hcp_consul.outputs.consul_private_endpoint_url
  consul_datacenter       = data.terraform_remote_state.hcp_consul.outputs.datacenter
  consul_acl_token        = data.terraform_remote_state.hcp_consul.outputs.consul_root_token_secret_id
  consul_client_ca_path   = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
}