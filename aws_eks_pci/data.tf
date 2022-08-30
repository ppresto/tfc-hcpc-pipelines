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

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}