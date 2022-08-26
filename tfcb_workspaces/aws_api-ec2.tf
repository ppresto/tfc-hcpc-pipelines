module "aws-ec2" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "aws_${local.region_shortname}_${var.env}_api-ec2"
  workingdir          = "aws_ec2"
  tfversion           = "1.1.4"
  queue_all_runs      = false
  auto_apply          = true
  identifier          = "${var.repo_org}/tfc-hcpc-pipelines"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["team-api", "ec2", "${var.aws_default_region}", "${var.env}"]
  variable_set        = tfe_variable_set.cloud_creds.id

  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
  }
  tf_variables = {
    "ec2_key_pair_name" = var.ssh_key_name
    "region"            = var.aws_default_region
    "organization"      = var.organization
    "env"               = var.env
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
  }
  tf_variables_sec = {}
}