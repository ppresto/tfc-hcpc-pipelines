module "aws_eks_consul_agent" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "aws_usw_dev_eks_consul_agent"
  workingdir          = "aws_eks_consul_agent"
  tfversion           = "1.1.4"
  queue_all_runs      = false
  auto_apply          = true
  identifier          = "${var.repo_org}/hcpc-vpc-ec2-eks"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["auto", "agent"]
  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
    "AWS_ACCESS_KEY_ID" = var.aws_access_key_id
  }
  tf_variables = {
    "region"          = var.aws_default_region
    "organization" = var.organization
    "consul_template" = "fake-service"
    "namespace"       = "consul"
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
  }
  tf_variables_sec = {}
}