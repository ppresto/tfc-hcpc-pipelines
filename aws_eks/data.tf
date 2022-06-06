# data source for current (working) aws region
data "aws_region" "current" {}


data "terraform_remote_state" "aws-tgw" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws-tgw"
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