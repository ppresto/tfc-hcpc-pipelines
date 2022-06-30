module "ws_aws_tgw" {
  source              = "../modules/workspace-mgr"
  agent_pool_id       = ""
  organization        = var.organization
  workspacename       = "aws_${var.aws_default_region}_${var.env}_tgw"
  workingdir          = "aws_tgw"
  tfversion           = "1.1.4"
  queue_all_runs      = false
  auto_apply          = true
  identifier          = "${var.repo_org}/hcpc-vpc-ec2-eks"
  oauth_token_id      = var.oauth_token_id
  repo_branch         = "main"
  global_remote_state = false
  tag_names           = ["auto", "sg", "transitGW", "bastion", "${var.aws_default_region}","${var.env}"]
  env_variables = {
    "CONFIRM_DESTROY" : 1
    "AWS_DEFAULT_REGION" : var.aws_default_region
    "HCP_CLIENT_ID" = var.HCP_CLIENT_ID
    "AWS_ACCESS_KEY_ID" = var.aws_access_key_id
  }
  tf_variables = {
    "region" = var.aws_default_region
    "organization" = var.organization
    "ec2_key_pair_name" = var.ssh_key_name
  }
  env_variables_sec = {
    "HCP_CLIENT_SECRET" = var.HCP_CLIENT_SECRET
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
  }
  tf_variables_sec = {}
}