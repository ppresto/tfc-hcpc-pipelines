resource "multispace_run" "hcp_consul" {
  organization = var.organization
  workspace    = "aws_shared_hcp-consul"
}