provider "aws" {
  region = var.region
}

# See Notes in README.md for explanation regarding using data-sources and computed values
data "aws_vpc" "default" {
  default = false
  id      = data.terraform_remote_state.hcp_consul.outputs.vpc_id
}

data "aws_subnet_ids" "this" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Tier = "Public"
  }
}

data "aws_caller_identity" "this" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_shared_hcp-consul"
    }
  }
}