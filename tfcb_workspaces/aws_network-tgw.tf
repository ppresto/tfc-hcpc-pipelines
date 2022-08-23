module "ws_aws_tgw" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "aws_${local.region_shortname}_${var.env}_network-tgw"
  workingdir          = "aws_tgw"
  tfversion           = "1.1.4"
  queue_all_runs      = false
  auto_apply          = true
  identifier          = "${var.repo_org}/tfc-hcpc-pipelines"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["team-net", "sg", "tgw", "bastion", "${var.aws_default_region}", "${var.env}"]
  variable_set        = var.variable_set != null ? tfe_variable_set.cloud_creds.id : null
  
  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
  }
  tf_variables = {
    "region"            = var.aws_default_region
    "organization"      = var.organization
    "ec2_key_pair_name" = var.ssh_key_name
    "env"               = var.env
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
  }
  tf_variables_sec = {}
  depends_on = [tfe_variable_set.cloud_creds]
}