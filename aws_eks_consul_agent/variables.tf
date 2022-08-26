variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "presto"
}

variable "env" { default = "dev" }
variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}
variable "organization" { default = "my_org_name" }
variable "namespace" {
  description = "K8s Namespace"
  type        = string
  default     = "default"
}
variable "consul_dns_cluster_ip" {
  description = "Preset Consul DNS ClusterIP to configure CoreDNS"
  type        = string
  default     = "172.20.128.87"
}

locals {
  region_shortname   = join("", regex("([a-z]{2}).*-([a-z]).*-(\\d+)", var.region))
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