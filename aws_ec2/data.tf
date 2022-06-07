# data source for current (working) aws region
data "aws_region" "current" {}


data "terraform_remote_state" "aws_tgw" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_usw_dev_tgw"
    }
  }
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "hcp_consul"
    }
  }
}