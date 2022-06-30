# data source for current (working) aws region
data "aws_region" "current" {}


data "terraform_remote_state" "aws_usw_dev_tgw" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${region}_dev_tgw"
    }
  }
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${region}_hcp_consul"
    }
  }
}