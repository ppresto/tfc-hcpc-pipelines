data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_shared_hcp-consul"
    }
  }
}

data "terraform_remote_state" "aws-eks" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = "aws_${var.env}_eks"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.aws-eks.outputs.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.aws-eks.outputs.cluster_id
}