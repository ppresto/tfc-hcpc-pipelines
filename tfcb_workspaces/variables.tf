variable "tfe_token" {}
variable "tfe_hostname" { default = "app.terraform.io" }
variable "oauth_token_id" {}
variable "organization" { default = "" }
variable "ssh_key_name" { default = "" }

# Workspace names will be used for the repo name when setting up VCS.
variable "repo_org" {}

variable "gcp_region" { default = "" }

variable "gcp_zone" { default = "" }

variable "gcp_project" { default = "" }

variable "gcp_credentials" { default = "" }

variable "aws_default_region" { default = "us-west-2" }

variable "aws_secret_access_key" { default = "" }

variable "aws_access_key_id" { default = "" }

variable "arm_subscription_id" { default = "" }

variable "arm_client_secret" { default = "" }

variable "arm_tenant_id" { default = "" }

variable "arm_client_id" { default = "" }

# Custom variables
variable "HCP_CLIENT_ID" { default = "" }
variable "HCP_CLIENT_SECRET" { default = "" }

variable "tag_names" {
  type    = list(any)
  default = ["auto"]
}