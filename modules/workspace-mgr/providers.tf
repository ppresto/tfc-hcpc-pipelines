terraform {
  required_version = ">= 1.0.5"
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.35.0"
    }
  }
}