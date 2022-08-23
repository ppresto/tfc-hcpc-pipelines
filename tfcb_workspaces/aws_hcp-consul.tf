module "ws_hcp_consul" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "aws_${local.region_shortname}_shared_hcp-consul"
  workingdir          = "hcp_consul"
  tfversion           = "1.1.4"
  queue_all_runs      = false
  auto_apply          = true
  identifier          = "${var.repo_org}/tfc-hcpc-pipelines"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["team-ss", "hcp", "shared-vpc", "consul", "${var.aws_default_region}"]
  variable_set        = var.variable_set != null ? tfe_variable_set.cloud_creds.id : null
  
  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
  }
  # local.region_shortname ex: "usw2"
  tf_variables = {
    "hvn_id"         = "${local.region_shortname}-hvn-id"
    "cluster_id"     = local.region_shortname
    "region"         = var.aws_default_region
    "cloud_provider" = "aws"
    "vpc_id"         = null
    "env"            = "shared"
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
  }
  tf_variables_sec = {}
  depends_on = [tfe_variable_set.cloud_creds]
}

output "hcp_consul_ws_name" {
  value = module.ws_hcp_consul
}