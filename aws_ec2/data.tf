# data source for current (working) aws region
data "aws_region" "current" {}

# data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}


data "terraform_remote_state" "aws_usw_dev_tgw" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${var.env}_tgw"
    }
  }
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_shared_hcp-consul"
    }
  }
}