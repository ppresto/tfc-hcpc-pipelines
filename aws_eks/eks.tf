provider "aws" {
  region = var.region
}

locals {
  name            = "${var.name}-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.21"

  tags = {
    Example    = local.name
    GithubRepo = "hcp_consul"
    GithubOrg  = "ppresto"
  }
}

#
### EKS Module
#
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

module "eks" {
  source                                = "terraform-aws-modules/eks/aws"
  version                               = "18.4.1"
  cluster_name                          = local.name
  cluster_version                       = local.cluster_version
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = true
  cluster_additional_security_group_ids = [data.terraform_remote_state.aws_usw_dev_tgw.outputs.consul_server_sg_id]
  vpc_id                                = data.terraform_remote_state.hcp_consul.outputs.vpc_id
  subnet_ids                            = data.terraform_remote_state.hcp_consul.outputs.vpc_private_subnets

  cluster_addons = {
    #coredns = {
    #  resolve_conflicts = "OVERWRITE"
    #}
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      create_launch_template = false
      launch_template_name   = ""

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = var.ec2_key_pair_name
        source_security_group_ids = [data.terraform_remote_state.aws_usw_dev_tgw.outputs.bastion_ssh_sg_id]
      }
    }
  }
}

################################################################################
# Supporting Resources
################################################################################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}