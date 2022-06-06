# data source for current (working) aws region
data "aws_region" "current" {}


data "terraform_remote_state" "aws_tgw" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws_tgw"
    }
  }
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "hcp_consul"
    }
  }
}