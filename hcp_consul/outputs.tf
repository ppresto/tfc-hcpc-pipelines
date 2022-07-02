output "provider_account_id" {
  value = hcp_hvn.example_hvn.provider_account_id
}
output "hvn_cidr_block" {
  value = var.hvn_cidr_block
}
output "hvn_id" {
  value = var.hvn_id
}
output "hvn_self_link" {
  value = hcp_hvn.example_hvn.self_link
}
output "hcpc_versions" {
  value = data.hcp_consul_versions.default
}
output "consul_public_endpoint_url" {
  value = hcp_consul_cluster.example_hcp.consul_public_endpoint_url
}
output "consul_private_endpoint_url" {
  value = hcp_consul_cluster.example_hcp.consul_private_endpoint_url
}

output "datacenter" {
  value = hcp_consul_cluster.example_hcp.datacenter
}

output "organization_id" {
  value = hcp_consul_cluster.example_hcp.organization_id
}

output "project_id" {
  value = hcp_consul_cluster.example_hcp.project_id
}

output "scale" {
  value = hcp_consul_cluster.example_hcp.scale
}

output "consul_version" {
  value = hcp_consul_cluster.example_hcp.consul_version
}

output "consul_self_link" {
  value = hcp_consul_cluster.example_hcp.self_link
}

output "consul_root_token_secret_id" {
  value = nonsensitive(hcp_consul_cluster_root_token.init.secret_id)
}
output "consul_ca_file" {
  value = hcp_consul_cluster.example_hcp.consul_ca_file
}
output "consul_config_file" {
  value = hcp_consul_cluster.example_hcp.consul_config_file
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}
output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}
output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}
output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}
output "vpc_default_security_group_id" {
  value = module.vpc.default_security_group_id
}