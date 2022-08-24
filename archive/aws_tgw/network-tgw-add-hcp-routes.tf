# Define required Routes for Layer 3 connectivity from within the VPC to HCP.
#
# Note:  The "for_each" value depends on resource attributes that cannot be determined until apply,
#        so Terraform cannot predict how many instances will be created.
#        To work around this we put these routes into a new TFCB workspace.

# VPC private subnet route to HCP CIDR Block
resource "aws_route" "private" {
  for_each               = toset(data.terraform_remote_state.hcp_consul.outputs.private_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}
# VPC public subnet route to HCP CIDR Block
resource "aws_route" "public" {
  for_each               = toset(data.terraform_remote_state.hcp_consul.outputs.public_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}

# Shared VPC private network routes to other VPC's
resource "aws_route" "allVpcPrivate" {
  for_each               = toset(data.terraform_remote_state.hcp_consul.outputs.public_route_table_ids)
  route_table_id         = each.key
  destination_cidr_block = "10.0.0.0/10"
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}