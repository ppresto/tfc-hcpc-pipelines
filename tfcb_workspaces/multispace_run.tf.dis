resource "multispace_run" "hcp_consul" {
  # Use string workspace names here and not data sources so that
  # you can define the multispace runs before the workspace even exists.
  organization = var.organization
  workspace    = module.ws_hcp_consul.workspace
}

resource "multispace_run" "aws_network" {
  workspace    = module.ws_aws_tgw.workspace
  organization = var.organization
  depends_on   = [multispace_run.hcp_consul]
}

resource "multispace_run" "eks" {
  workspace    = module.aws-eks.workspace
  organization = var.organization
  depends_on   = [multispace_run.aws_network]
}