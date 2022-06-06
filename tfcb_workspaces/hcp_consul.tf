module "ws_hcp_consul" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "hcp_consul"
  workingdir          = "hcp_consul"
  tfversion           = "1.1.4"
  queue_all_runs      = true
  auto_apply          = true
  identifier          = "${var.repo_org}/hcp_consul"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["auto","server"]
  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
  }
  tf_variables = {
    "ssh_key_name"   = var.ssh_key_name
    "hvn_id"         = "uswest-hvn-id"
    "cluster_id"     = "uswest"
    "region"         = var.aws_default_region
    "cloud_provider" = "aws"
    "vpc_id"         = null
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
  }
  tf_variables_sec = {}
}

output "hcp_consul_ws_name" {
  value = module.ws_hcp_consul
}