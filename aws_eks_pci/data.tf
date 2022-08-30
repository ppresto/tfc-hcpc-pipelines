# data source for current (working) aws region
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${local.region_shortname}_shared_hcp-consul"
    }
  }
}

data "terraform_remote_state" "aws-eks-pci" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${local.region_shortname}_${var.env}_eks-pci"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.aws-eks-pci.outputs.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.aws-eks-pci.outputs.cluster_id
}