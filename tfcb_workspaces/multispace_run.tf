resource "multispace_run" "hcp_consul" {
  # Use string workspace names here and not data sources so that
  # you can define the multispace runs before the workspace even exists.
  organization = var.organization
  workspace    = "aws_shared_hcp-consul"
}