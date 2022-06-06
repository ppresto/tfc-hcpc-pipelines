provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
}

terraform {
  required_version = ">= 1.0.5"
  required_providers {
    tfe = {
      version = "~>0.31.0"
    }
    multispace = {
      source  = "mitchellh/multispace"
      version = "~>0.1.0"
    }
  }
}

