# HVN belongs to an AWS organization managed by HashiCorp, first define an AWS resource share
# that allows the two organizations to share resources.
resource "aws_ram_resource_share" "hcpc" {
  name                      = "hcpc-${var.region}-share"
  allow_external_principals = true
}
resource "aws_ram_principal_association" "example" {
  resource_share_arn = aws_ram_resource_share.hcpc.arn
  principal          = data.terraform_remote_state.hcp_consul.outputs.provider_account_id
}

resource "aws_ram_resource_association" "example" {
  resource_share_arn = aws_ram_resource_share.hcpc.arn
  resource_arn       = module.tgw.ec2_transit_gateway_arn
}

# The aws tgw module is configured to auto accept attachments so just create the attachment.
resource "hcp_aws_transit_gateway_attachment" "example" {
  depends_on = [
    aws_ram_principal_association.example,
    aws_ram_resource_association.example,
  ]

  hvn_id                        = data.terraform_remote_state.hcp_consul.outputs.hvn_id
  transit_gateway_attachment_id = "hcpc-tgw-${var.region}-attachment"
  transit_gateway_id            = module.tgw.ec2_transit_gateway_id
  resource_share_arn            = aws_ram_resource_share.hcpc.arn
}

#Finally define the HCP Route to the VPC CIDR
resource "hcp_hvn_route" "route" {
  hvn_link         = data.terraform_remote_state.hcp_consul.outputs.hvn_self_link
  hvn_route_id     = "hvn-to-tgw-${var.region}-attachment"
  destination_cidr = data.terraform_remote_state.hcp_consul.outputs.vpc_cidr_block
  #destination_cidr = "10.0.0.0/10"  # 10.0-10.63
  target_link      = hcp_aws_transit_gateway_attachment.example.self_link
}